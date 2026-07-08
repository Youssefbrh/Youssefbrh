import SwiftUI

/// What lives in (and briefly around) the notch while it's closed:
/// volume/brightness HUD wings, sneak alerts, and the pomodoro progress line.
struct ClosedNotchView: View {
    @EnvironmentObject var vm: NotchViewModel
    @EnvironmentObject var alerts: AlertCenter
    @EnvironmentObject var pomodoro: PomodoroTimer

    var body: some View {
        ZStack {
            if let hud = vm.hudEvent {
                wings(
                    leading: {
                        Image(systemName: hud.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 24)
                    },
                    trailing: {
                        HUDLevelBar(level: hud.muted ? 0 : hud.level)
                    }
                )
                .transition(.opacity)
            } else if let alert = alerts.current {
                wings(
                    leading: {
                        Image(systemName: alert.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(alert.tint)
                            .symbolRenderingMode(.hierarchical)
                    },
                    trailing: {
                        Text(alert.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                )
                .transition(.opacity)
            }

            if pomodoro.isRunning {
                VStack {
                    Spacer()
                    GeometryReader { geo in
                        Capsule()
                            .fill(pomodoro.phase == .focus ? Color.orange : Color.green)
                            .frame(width: max(4, geo.size.width * pomodoro.progress), height: 3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 3)
                }
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Content in the flared-out areas either side of the physical cutout.
    private func wings<L: View, T: View>(
        @ViewBuilder leading: () -> L,
        @ViewBuilder trailing: () -> T
    ) -> some View {
        HStack(spacing: 0) {
            leading()
                .frame(width: 90)
            Spacer()
                .frame(width: vm.geometry.notchWidth - 40)
            trailing()
                .frame(width: 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HUDLevelBar: View {
    var level: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.22))
                Capsule()
                    .fill(Color.white)
                    .frame(width: max(0, geo.size.width * level))
            }
        }
        .frame(width: 96, height: 5)
        .animation(.easeOut(duration: 0.12), value: level)
    }
}
