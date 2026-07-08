import SwiftUI

struct SneakAlert: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let title: String
    let tint: Color
}

/// Queues Dynamic-Island-style alerts that slide out of the closed notch.
@MainActor
final class AlertCenter: ObservableObject {
    @Published private(set) var current: SneakAlert?

    private var queue: [SneakAlert] = []
    private var dismissWorkItem: DispatchWorkItem?

    func post(icon: String, title: String, tint: Color) {
        guard Prefs.bool(.alertsEnabled, default: true) else { return }
        let alert = SneakAlert(icon: icon, title: title, tint: tint)
        if current == nil {
            show(alert)
        } else {
            queue.append(alert)
            if queue.count > 3 { queue.removeFirst() }
        }
    }

    private func show(_ alert: SneakAlert) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            current = alert
        }
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in self?.dismiss() }
        }
        dismissWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2, execute: item)
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            current = nil
        }
        if !queue.isEmpty {
            let next = queue.removeFirst()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
                Task { @MainActor in self?.show(next) }
            }
        }
    }
}
