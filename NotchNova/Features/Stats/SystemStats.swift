import Foundation
import IOKit.ps
import Darwin

enum SystemAlertEvent {
    case batteryLow(Int)
    case cpuHot
    case charging
}

/// Samples CPU / memory / network / battery / temperature every 2 seconds.
@MainActor
final class SystemStats: ObservableObject {
    @Published private(set) var cpuUsage: Double = 0          // 0...1
    @Published private(set) var cpuHistory: [Double] = []
    @Published private(set) var memUsedBytes: UInt64 = 0
    @Published private(set) var memTotalBytes: UInt64 = ProcessInfo.processInfo.physicalMemory
    @Published private(set) var netDownBps: Double = 0
    @Published private(set) var netUpBps: Double = 0
    @Published private(set) var batteryPercent: Int?
    @Published private(set) var isCharging = false
    @Published private(set) var cpuTemperature: Double?

    var onAlert: (@MainActor (SystemAlertEvent) -> Void)?

    var memUsedFraction: Double {
        memTotalBytes > 0 ? Double(memUsedBytes) / Double(memTotalBytes) : 0
    }

    private var timer: Timer?
    private let interval: TimeInterval = 2
    private let smc = SMCTemperature()

    private var prevCPUTicks: [Int32] = []
    private var prevNetBytes: (down: UInt64, up: UInt64)?
    private var hotStreak = 0
    private var batteryAlertArmed = true
    private var lastHotAlert: Date = .distantPast
    private var wasCharging: Bool?

    func start() {
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func sample() {
        if let cpu = sampleCPU() {
            cpuUsage = cpu
            cpuHistory.append(cpu)
            if cpuHistory.count > 40 { cpuHistory.removeFirst(cpuHistory.count - 40) }
        }
        sampleMemory()
        sampleNetwork()
        sampleBattery()
        cpuTemperature = smc?.readCPUTemperature()
        checkAlerts()
    }

    // MARK: - CPU

    private func sampleCPU() -> Double? {
        var cpuCount: natural_t = 0
        var infoArray: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &infoArray, &infoCount
        )
        guard result == KERN_SUCCESS, let infoArray else { return nil }
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(UInt(bitPattern: infoArray)),
                vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride)
            )
        }

        let ticks = Array(UnsafeBufferPointer(start: infoArray, count: Int(infoCount)))
        guard prevCPUTicks.count == ticks.count else {
            prevCPUTicks = ticks
            return nil
        }

        let states = Int(CPU_STATE_MAX)
        var used: Double = 0
        var total: Double = 0
        for cpu in 0..<Int(cpuCount) {
            let base = cpu * states
            let user = Double(ticks[base + Int(CPU_STATE_USER)] &- prevCPUTicks[base + Int(CPU_STATE_USER)])
            let sys = Double(ticks[base + Int(CPU_STATE_SYSTEM)] &- prevCPUTicks[base + Int(CPU_STATE_SYSTEM)])
            let nice = Double(ticks[base + Int(CPU_STATE_NICE)] &- prevCPUTicks[base + Int(CPU_STATE_NICE)])
            let idle = Double(ticks[base + Int(CPU_STATE_IDLE)] &- prevCPUTicks[base + Int(CPU_STATE_IDLE)])
            used += user + sys + nice
            total += user + sys + nice + idle
        }
        prevCPUTicks = ticks
        guard total > 0 else { return nil }
        return min(1, max(0, used / total))
    }

    // MARK: - Memory

    private func sampleMemory() {
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return }
        let used = UInt64(stats.active_count) + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        memUsedBytes = used * UInt64(pageSize)
    }

    // MARK: - Network

    private func sampleNetwork() {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrs) == 0, let first = addrs else { return }
        defer { freeifaddrs(addrs) }

        var down: UInt64 = 0
        var up: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let ifa = cursor {
            defer { cursor = ifa.pointee.ifa_next }
            guard let addr = ifa.pointee.ifa_addr,
                  addr.pointee.sa_family == UInt8(AF_LINK),
                  let dataPtr = ifa.pointee.ifa_data else { continue }
            let name = String(cString: ifa.pointee.ifa_name)
            guard name.hasPrefix("en") || name.hasPrefix("utun") || name.hasPrefix("pdp") else { continue }
            let data = dataPtr.assumingMemoryBound(to: if_data.self).pointee
            down &+= UInt64(data.ifi_ibytes)
            up &+= UInt64(data.ifi_obytes)
        }

        if let prev = prevNetBytes {
            netDownBps = max(0, Double(down &- prev.down)) / interval
            netUpBps = max(0, Double(up &- prev.up)) / interval
        }
        prevNetBytes = (down, up)
    }

    // MARK: - Battery

    private func sampleBattery() {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            batteryPercent = nil
            return
        }
        for source in list {
            guard let desc = IOPSGetPowerSourceDescription(blob, source)?
                .takeUnretainedValue() as? [String: Any] else { continue }
            if let capacity = desc[kIOPSCurrentCapacityKey] as? Int {
                batteryPercent = capacity
                isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
                return
            }
        }
        batteryPercent = nil
    }

    // MARK: - Alerts

    private func checkAlerts() {
        guard Prefs.bool(.alertsEnabled, default: true) else { return }

        if let pct = batteryPercent {
            if !isCharging, pct <= 15, batteryAlertArmed {
                batteryAlertArmed = false
                onAlert?(.batteryLow(pct))
            } else if isCharging || pct > 20 {
                batteryAlertArmed = true
            }
        }

        if let was = wasCharging, !was, isCharging {
            onAlert?(.charging)
        }
        wasCharging = isCharging

        let hot = (cpuTemperature ?? 0) > 90 || cpuUsage > 0.95
        hotStreak = hot ? hotStreak + 1 : 0
        if hotStreak >= 3, Date().timeIntervalSince(lastHotAlert) > 300 {
            lastHotAlert = Date()
            hotStreak = 0
            onAlert?(.cpuHot)
        }
    }
}
