import AppKit
import SwiftUI

/// Borderless, non-activating panel pinned over the notch. Fully transparent
/// regions pass clicks through to whatever is underneath, so the oversized
/// canvas doesn't block the menu bar.
final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class NotchWindowController {
    private let state: AppState
    private var panel: NotchPanel?

    init(state: AppState) {
        self.state = state
    }

    func show() {
        guard let screen = NotchGeometry.preferredScreen() else { return }
        state.vm.geometry = NotchGeometry.measure(on: screen)

        let panel = NotchPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.registerForDraggedTypes([.fileURL])

        let root = NotchContainerView()
            .environmentObject(state.vm)
            .environmentObject(state.shelf)
            .environmentObject(state.media)
            .environmentObject(state.stats)
            .environmentObject(state.alerts)
            .environmentObject(state.clipboard)
            .environmentObject(state.pomodoro)
            .environmentObject(state.pet)

        let hosting = NSHostingView(rootView: root)
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting

        self.panel = panel
        position(on: screen)
        panel.orderFrontRegardless()
    }

    func repositionForCurrentScreen() {
        guard let screen = NotchGeometry.preferredScreen() else { return }
        state.vm.geometry = NotchGeometry.measure(on: screen)
        position(on: screen)
    }

    private func position(on screen: NSScreen) {
        guard let panel else { return }
        let size = state.vm.panelSize
        let origin = CGPoint(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.maxY - size.height
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }
}
