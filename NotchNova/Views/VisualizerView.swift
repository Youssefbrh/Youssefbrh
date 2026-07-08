import SwiftUI

/// Beat-style bars. There's no public API to tap another app's audio, so the
/// motion is procedural — smooth layered sine noise that only dances while
/// music is actually playing.
struct VisualizerView: View {
    var isPlaying: Bool
    var barCount: Int = 5
    var tint: Color = Theme.accent

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 2.5) {
                ForEach(0..<barCount, id: \.self) { i in
                    Capsule()
                        .fill(tint)
                        .frame(width: 3, height: barHeight(index: i, time: t))
                }
            }
        }
        .frame(height: 18)
        .opacity(isPlaying ? 1 : 0.35)
    }

    private func barHeight(index: Int, time: TimeInterval) -> CGFloat {
        guard isPlaying else { return 4 }
        let phase = Double(index) * 1.7
        let fast = sin(time * 9.3 + phase)
        let slow = sin(time * 3.1 + phase * 2.3)
        let wob = sin(time * 13.7 + phase * 0.6)
        let v = (fast * 0.5 + slow * 0.35 + wob * 0.15 + 1) / 2   // 0...1
        return 4 + CGFloat(v) * 13
    }

    /// A rough 0...1 "energy" other views (aurora, pet) can reuse for sync.
    static func energy(at time: TimeInterval, playing: Bool) -> Double {
        guard playing else { return 0 }
        return (sin(time * 4.2) * 0.5 + sin(time * 9.1) * 0.3 + sin(time * 1.3) * 0.2 + 1) / 2
    }
}
