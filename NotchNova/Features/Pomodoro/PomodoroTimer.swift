import Foundation

/// Focus / break timer. Progress is mirrored on the closed notch as a thin
/// line, completion fires a sneak alert.
@MainActor
final class PomodoroTimer: ObservableObject {
    enum Phase: String {
        case focus = "Focus"
        case rest = "Break"
    }

    @Published private(set) var phase: Phase = .focus
    @Published private(set) var isRunning = false
    @Published private(set) var remaining: TimeInterval = 25 * 60
    @Published var focusMinutes: Double = 25
    @Published var restMinutes: Double = 5

    var onPhaseCompleted: (@MainActor (Phase) -> Void)?

    private var timer: Timer?

    var total: TimeInterval {
        (phase == .focus ? focusMinutes : restMinutes) * 60
    }

    var progress: Double {
        total > 0 ? 1 - remaining / total : 0
    }

    var timeString: String {
        let s = max(0, Int(remaining.rounded()))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    func startPause() {
        if isRunning {
            timer?.invalidate()
            timer = nil
            isRunning = false
        } else {
            isRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.tick() }
            }
        }
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        phase = .focus
        remaining = focusMinutes * 60
    }

    func applyDurations() {
        guard !isRunning else { return }
        remaining = total
    }

    private func tick() {
        remaining -= 1
        if remaining <= 0 {
            let finished = phase
            onPhaseCompleted?(finished)
            phase = finished == .focus ? .rest : .focus
            remaining = total
        }
    }
}
