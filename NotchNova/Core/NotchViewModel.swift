import SwiftUI
import Combine

enum NotchState: Equatable {
    case closed
    case expanded
}

enum NotchTab: String, CaseIterable, Identifiable {
    case home, shelf, tools, pet
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "waveform"
        case .shelf: return "tray.full.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        case .pet: return "pawprint.fill"
        }
    }

    var title: String {
        switch self {
        case .home: return "Home"
        case .shelf: return "Shelf"
        case .tools: return "Tools"
        case .pet: return "Pet"
        }
    }
}

struct HUDEvent: Equatable {
    enum Kind: Equatable { case volume, brightness }
    var kind: Kind
    var level: Double   // 0...1
    var muted: Bool = false

    var icon: String {
        switch kind {
        case .brightness: return "sun.max.fill"
        case .volume:
            if muted || level <= 0.001 { return "speaker.slash.fill" }
            if level < 0.34 { return "speaker.wave.1.fill" }
            if level < 0.67 { return "speaker.wave.2.fill" }
            return "speaker.wave.3.fill"
        }
    }
}

@MainActor
final class NotchViewModel: ObservableObject {
    @Published var state: NotchState = .closed
    @Published var isHovering = false
    @Published var selectedTab: NotchTab = .home
    @Published var geometry: NotchGeometry = .fallback
    @Published var hudEvent: HUDEvent?
    @Published var dragTargeted = false

    /// Size of the expanded island content. Kept snug so it doesn't feel
    /// empty when little is playing.
    let expandedSize = CGSize(width: 600, height: 282)
    /// Total panel canvas (leaves room for glow, alert wings and the pet).
    var panelSize: CGSize {
        CGSize(width: max(expandedSize.width + 80, geometry.notchWidth + 460),
               height: expandedSize.height + 120)
    }

    var spring: Animation { .spring(response: 0.42, dampingFraction: 0.78) }

    private var closeWorkItem: DispatchWorkItem?
    private var hudWorkItem: DispatchWorkItem?

    func open(tab: NotchTab? = nil) {
        cancelScheduledClose()
        if let tab { selectedTab = tab }
        withAnimation(spring) { state = .expanded }
    }

    func close() {
        cancelScheduledClose()
        withAnimation(spring) { state = .closed }
    }

    /// Close a moment after the pointer leaves, so brushing past doesn't slam it shut.
    func scheduleClose(after delay: TimeInterval = 0.35) {
        cancelScheduledClose()
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self, !self.isHovering, !self.dragTargeted else { return }
                self.close()
            }
        }
        closeWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func cancelScheduledClose() {
        closeWorkItem?.cancel()
        closeWorkItem = nil
    }

    func hoverChanged(_ hovering: Bool) {
        isHovering = hovering
        if hovering {
            if state == .closed, Prefs.bool(.openOnHover, default: true) {
                open()
            } else {
                cancelScheduledClose()
            }
        } else if state == .expanded {
            scheduleClose()
        }
    }

    func showHUD(_ event: HUDEvent) {
        guard Prefs.bool(.hudEnabled, default: true) else { return }
        hudWorkItem?.cancel()
        withAnimation(spring) { hudEvent = event }
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                withAnimation(self.spring) { self.hudEvent = nil }
            }
        }
        hudWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: item)
    }
}
