import SwiftUI
import AppKit

/// Album art, track info, transport controls and the visualizer.
struct MediaView: View {
    @EnvironmentObject var media: MediaController

    var body: some View {
        if media.hasTrack {
            HStack(spacing: 14) {
                artworkView

                VStack(alignment: .leading, spacing: 4) {
                    Text(media.title ?? "—")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(media.artist ?? "")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        transportButton("backward.fill", size: 13) { media.previousTrack() }
                        transportButton(media.isPlaying ? "pause.fill" : "play.fill", size: 18) {
                            media.togglePlayPause()
                        }
                        transportButton("forward.fill", size: 13) { media.nextTrack() }

                        Spacer(minLength: 4)

                        VisualizerView(isPlaying: media.isPlaying)
                    }
                    .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 6)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "music.note")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.textSecondary)
                Text("Nothing playing")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Text("Start Spotify or Apple Music")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var artworkView: some View {
        Group {
            if let artwork = media.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.surface)
                    Image(systemName: "music.note")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
    }

    private func transportButton(_ symbol: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: size + 14, height: size + 14)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
