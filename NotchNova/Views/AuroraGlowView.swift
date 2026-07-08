import SwiftUI

/// Ambient gradient glow bleeding out from under the island — the "vibes".
/// Slowly drifts through the theme colors; in music mode it pulses with
/// playback energy.
struct AuroraGlowView: View {
    var isExpanded: Bool

    @EnvironmentObject var media: MediaController
    @AppStorage(Prefs.Key.auroraStyle.rawValue) private var styleRaw = AuroraStyle.ambient.rawValue

    private var style: AuroraStyle { AuroraStyle(rawValue: styleRaw) ?? .ambient }

    var body: some View {
        if style == .off {
            EmptyView()
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                let energy = style == .music
                    ? VisualizerView.energy(at: t, playing: media.isPlaying)
                    : 0.5 + 0.5 * sin(t * 0.35)

                let base = isExpanded ? 0.5 : 0.22
                let opacity = base * (0.55 + 0.45 * energy)

                ZStack {
                    ForEach(0..<Theme.auroraColors.count, id: \.self) { i in
                        Ellipse()
                            .fill(Theme.auroraColors[i])
                            .frame(width: 220, height: 90)
                            .offset(
                                x: CGFloat(sin(t * 0.21 + Double(i) * 1.9)) * 120,
                                y: CGFloat(cos(t * 0.17 + Double(i) * 1.2)) * 16 - 10
                            )
                            .opacity(0.5)
                    }
                }
                .blur(radius: 46)
                .opacity(opacity)
            }
        }
    }
}
