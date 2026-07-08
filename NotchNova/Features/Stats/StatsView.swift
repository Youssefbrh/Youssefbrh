import SwiftUI

/// Live gauges: CPU (with sparkline), memory, network throughput, battery
/// and temperature.
struct StatsView: View {
    @EnvironmentObject var stats: SystemStats

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                gaugeRing(
                    value: stats.cpuUsage,
                    label: "CPU",
                    detail: "\(Int(stats.cpuUsage * 100))%",
                    tint: tint(for: stats.cpuUsage)
                )
                gaugeRing(
                    value: stats.memUsedFraction,
                    label: "RAM",
                    detail: byteString(stats.memUsedBytes),
                    tint: tint(for: stats.memUsedFraction)
                )
                if let temp = stats.cpuTemperature {
                    gaugeRing(
                        value: min(1, max(0, (temp - 25) / 75)),
                        label: "TEMP",
                        detail: String(format: "%.0f°", temp),
                        tint: temp > 85 ? .red : (temp > 70 ? .orange : Theme.accent)
                    )
                }
            }
            .frame(maxWidth: .infinity)

            Sparkline(values: stats.cpuHistory)
                .frame(height: 26)

            HStack(spacing: 12) {
                Label(throughput(stats.netDownBps), systemImage: "arrow.down")
                Label(throughput(stats.netUpBps), systemImage: "arrow.up")
                Spacer()
                if let pct = stats.batteryPercent {
                    Label("\(pct)%", systemImage: stats.isCharging ? "battery.100percent.bolt" : batterySymbol(pct))
                        .foregroundStyle(pct <= 15 && !stats.isCharging ? .red : Theme.textSecondary)
                }
            }
            .font(.system(size: 10, weight: .medium).monospacedDigit())
            .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 4)
    }

    private func gaugeRing(value: Double, label: String, detail: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: max(0.02, value))
                    .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: value)
                Text(detail)
                    .font(.system(size: 9, weight: .bold).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .padding(4)
            }
            .frame(width: 48, height: 48)
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func tint(for value: Double) -> Color {
        value > 0.9 ? .red : (value > 0.7 ? .orange : Theme.accent)
    }

    private func byteString(_ bytes: UInt64) -> String {
        String(format: "%.1fG", Double(bytes) / 1_073_741_824)
    }

    private func throughput(_ bps: Double) -> String {
        if bps >= 1_048_576 { return String(format: "%.1f MB/s", bps / 1_048_576) }
        if bps >= 1024 { return String(format: "%.0f KB/s", bps / 1024) }
        return String(format: "%.0f B/s", bps)
    }

    private func batterySymbol(_ pct: Int) -> String {
        switch pct {
        case ..<13: return "battery.0percent"
        case ..<38: return "battery.25percent"
        case ..<63: return "battery.50percent"
        case ..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
}

struct Sparkline: View {
    var values: [Double]

    var body: some View {
        GeometryReader { geo in
            let points = normalizedPoints(in: geo.size)
            ZStack {
                if points.count > 1 {
                    Path { p in
                        p.move(to: CGPoint(x: points[0].x, y: geo.size.height))
                        for pt in points { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: points[points.count - 1].x, y: geo.size.height))
                        p.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.35), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    Path { p in
                        p.move(to: points[0])
                        for pt in points.dropFirst() { p.addLine(to: pt) }
                    }
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let stepX = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { i, v in
            CGPoint(x: CGFloat(i) * stepX, y: size.height * (1 - CGFloat(min(1, max(0, v)))))
        }
    }
}
