import SwiftUI

/// The little creature that lives on the notch. A tiny state machine: it
/// idles, wanders, naps, dances to music, gets startled by file drops and
/// loves being petted.
@MainActor
final class PetEngine: ObservableObject {
    enum Mood: String {
        case idle, walking, sleeping, dancing, startled, happy

        var caption: String {
            switch self {
            case .idle: return "chilling"
            case .walking: return "on a stroll"
            case .sleeping: return "zzz…"
            case .dancing: return "vibing to the music"
            case .startled: return "!!!"
            case .happy: return "loves you"
            }
        }
    }

    @Published private(set) var mood: Mood = .idle
    @Published private(set) var peekOffsetX: CGFloat = 0
    @Published private(set) var heartsBurst = 0   // increments → view spawns hearts

    private var behaviorTimer: Timer?
    private var musicPlaying = false
    private var revertWorkItem: DispatchWorkItem?

    var name: String {
        Prefs.string(.petName, default: "Nova")
    }

    func start() {
        scheduleNextBehavior(in: 4)
    }

    func stop() {
        behaviorTimer?.invalidate()
        behaviorTimer = nil
    }

    func setDancing(_ dancing: Bool) {
        musicPlaying = dancing
        guard mood != .startled, mood != .happy else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            mood = dancing ? .dancing : .idle
        }
    }

    func startle() {
        interrupt(with: .startled, for: 1.6)
    }

    func pet() {
        heartsBurst += 1
        interrupt(with: .happy, for: 2.2)
    }

    private func interrupt(with newMood: Mood, for duration: TimeInterval) {
        revertWorkItem?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            mood = newMood
        }
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    self.mood = self.musicPlaying ? .dancing : .idle
                }
            }
        }
        revertWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: item)
    }

    private func scheduleNextBehavior(in delay: TimeInterval) {
        behaviorTimer?.invalidate()
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.nextBehavior() }
        }
    }

    private func nextBehavior() {
        defer { scheduleNextBehavior(in: .random(in: 6...14)) }
        guard mood != .startled, mood != .happy else { return }
        if musicPlaying {
            withAnimation { mood = .dancing }
            return
        }

        let roll = Int.random(in: 0..<10)
        switch roll {
        case 0...4:
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { mood = .idle }
        case 5...7:
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { mood = .walking }
            withAnimation(.easeInOut(duration: 4)) {
                peekOffsetX = .random(in: -70...70)
            }
        default:
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { mood = .sleeping }
        }
    }
}
