import Foundation
import IOKit

/// Reads CPU temperature straight from the SMC (AppleSMC IOKit service).
/// Sensor keys differ across chips, so a candidate list is probed once and
/// the readable ones get averaged. Returns nil (gauge hidden) when nothing
/// is readable — some Apple Silicon models expose no keys to userspace.
final class SMCTemperature {
    // 32-byte payload used by the SMC param struct.
    typealias SMCBytes = (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )

    private struct SMCVersion {
        var major: UInt8 = 0, minor: UInt8 = 0, build: UInt8 = 0
        var reserved: UInt8 = 0
        var release: UInt16 = 0
    }

    private struct SMCPLimitData {
        var version: UInt16 = 0, length: UInt16 = 0
        var cpuPLimit: UInt32 = 0, gpuPLimit: UInt32 = 0, memPLimit: UInt32 = 0
    }

    private struct SMCKeyInfoData {
        var dataSize: UInt32 = 0
        var dataType: UInt32 = 0
        var dataAttributes: UInt8 = 0
    }

    private struct SMCParamStruct {
        var key: UInt32 = 0
        var vers = SMCVersion()
        var pLimitData = SMCPLimitData()
        var keyInfo = SMCKeyInfoData()
        var padding: UInt16 = 0
        var result: UInt8 = 0
        var status: UInt8 = 0
        var data8: UInt8 = 0
        var data32: UInt32 = 0
        var bytes: SMCBytes = (
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        )
    }

    private enum Selector: UInt8 {
        case readKeyInfo = 9
        case readBytes = 5
    }

    private static let candidateKeys: [String] = [
        // Intel
        "TC0P", "TC0E", "TC0F", "TC0D",
        // Apple Silicon M1
        "Tp09", "Tp0T", "Tp01", "Tp05", "Tp0D", "Tp0H", "Tp0L", "Tp0P", "Tp0X", "Tp0b",
        // M2
        "Tp1h", "Tp1t", "Tp1p", "Tp1l", "Tp0f", "Tp0j", "Tp0n", "Tp0r",
        // M3 / M4
        "Te05", "Te0L", "Te0P", "Te0S",
        "Tf04", "Tf09", "Tf0A", "Tf0B", "Tf0D", "Tf0E",
        "Tf44", "Tf49", "Tf4A", "Tf4B", "Tf4D", "Tf4E",
    ]

    private var connection: io_connect_t = 0
    private var usableKeys: [UInt32] = []

    init?() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return nil }
        let openResult = IOServiceOpen(service, mach_task_self_, 0, &connection)
        IOObjectRelease(service)
        guard openResult == kIOReturnSuccess else { return nil }

        for key in Self.candidateKeys {
            let code = Self.fourCC(key)
            if let value = readTemperature(code), value > 5, value < 125 {
                usableKeys.append(code)
            }
        }
        guard !usableKeys.isEmpty else {
            IOServiceClose(connection)
            return nil
        }
    }

    deinit {
        if connection != 0 { IOServiceClose(connection) }
    }

    func readCPUTemperature() -> Double? {
        var values: [Double] = []
        for key in usableKeys {
            if let v = readTemperature(key), v > 5, v < 125 {
                values.append(v)
            }
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    // MARK: - SMC plumbing

    private func readTemperature(_ key: UInt32) -> Double? {
        var input = SMCParamStruct()
        input.key = key
        input.data8 = Selector.readKeyInfo.rawValue
        guard let info = callSMC(&input) else { return nil }
        let dataType = info.keyInfo.dataType
        let dataSize = info.keyInfo.dataSize
        guard dataSize > 0, dataSize <= 32 else { return nil }

        var readInput = SMCParamStruct()
        readInput.key = key
        readInput.keyInfo = info.keyInfo
        readInput.data8 = Selector.readBytes.rawValue
        guard let output = callSMC(&readInput) else { return nil }

        var bytes = output.bytes
        return withUnsafeBytes(of: &bytes) { raw -> Double? in
            switch dataType {
            case Self.fourCC("flt "):
                guard dataSize >= 4 else { return nil }
                let bits = UInt32(raw[0]) | (UInt32(raw[1]) << 8) | (UInt32(raw[2]) << 16) | (UInt32(raw[3]) << 24)
                return Double(Float(bitPattern: bits))
            case Self.fourCC("sp78"):
                guard dataSize >= 2 else { return nil }
                let value = Int16(bitPattern: (UInt16(raw[0]) << 8) | UInt16(raw[1]))
                return Double(value) / 256.0
            case Self.fourCC("ui8 "):
                return Double(raw[0])
            default:
                return nil
            }
        }
    }

    private func callSMC(_ input: inout SMCParamStruct) -> SMCParamStruct? {
        var output = SMCParamStruct()
        var outputSize = MemoryLayout<SMCParamStruct>.stride
        let result = IOConnectCallStructMethod(
            connection,
            2,  // kSMCHandleYPCEvent
            &input,
            MemoryLayout<SMCParamStruct>.stride,
            &output,
            &outputSize
        )
        guard result == kIOReturnSuccess, output.result == 0 else { return nil }
        return output
    }

    private static func fourCC(_ string: String) -> UInt32 {
        var result: UInt32 = 0
        for scalar in string.unicodeScalars.prefix(4) {
            result = (result << 8) | (scalar.value & 0xFF)
        }
        return result
    }
}
