import SwiftUI

struct PomodoroView: View {
    @EnvironmentObject var pomodoro: PomodoroTimer

    var body: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: max(0.003, pomodoro.progress))
                    .stroke(
                        pomodoro.phase == .focus ? Color.orange : Color.green,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: pomodoro.progress)
                VStack(spacing: 2) {
                    Text(pomodoro.timeString)
                        .font(.system(size: 20, weight: .bold).monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                    Text(pomodoro.phase.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(pomodoro.phase == .focus ? .orange : .green)
                }
            }
            .frame(width: 108, height: 108)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Button {
                        pomodoro.startPause()
                    } label: {
                        Label(pomodoro.isRunning ? "Pause" : "Start",
                              systemImage: pomodoro.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Theme.accent.opacity(0.25)))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .buttonStyle(.plain)

                    Button {
                        pomodoro.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(7)
                            .background(Circle().fill(Theme.surface))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                durationRow(label: "Focus", value: $pomodoro.focusMinutes, range: 5...90)
                durationRow(label: "Break", value: $pomodoro.restMinutes, range: 1...30)

                Text("Progress shows on the notch while closed")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
            }
        }
    }

    private func durationRow(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 38, alignment: .leading)
            Slider(value: value, in: range, step: 1) { editing in
                if !editing { pomodoro.applyDurations() }
            }
            .controlSize(.mini)
            .frame(width: 130)
            .disabled(pomodoro.isRunning)
            Text("\(Int(value.wrappedValue))m")
                .font(.system(size: 10, weight: .medium).monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
