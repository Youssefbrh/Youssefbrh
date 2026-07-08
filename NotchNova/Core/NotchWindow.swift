import AppKit
import SwiftUI

/// Borderless, non-activating panel pinned over the notch. It is
/// click-through by default; a mouse tracker only enables interaction while
/// the pointer is actually over the notch (or the opened island), so the app
/// never blocks the windows behind it.
final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class NotchWindowController {
    private let state: AppState
    private var panel: NotchPanel?
    private var screen: NSScreen?
    private var trackingTimer: Timer?
    private var lastInteractive = false

    init(state: AppState) {
        self.state = state
    }

    func show() {
        guard let screen = NotchGeometry.preferredScreen() else { return }
        self.screen = screen
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
        // Sit just above the menu bar, not above every window on the system.
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        // Start transparent to clicks; the tracker flips this on over the notch.
        panel.ignoresMouseEvents = true
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
        startTracking()
    }

    func repositionForCurrentScreen() {
        guard let screen = NotchGeometry.preferredScreen() else { return }
        self.screen = screen
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

    // MARK: - Mouse tracking (permission-free, polls NSEvent.mouseLocation)

    private func startTracking() {
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func closedHotRect(_ screen: NSScreen) -> CGRect {
        let g = state.vm.geometry
        let w = g.notchWidth + 24
        let h = g.notchHeight + 10
        return CGRect(x: screen.frame.midX - w / 2, y: screen.frame.maxY - h, width: w, height: h)
    }

    private func expandedHotRect(_ screen: NSScreen) -> CGRect {
        let size = state.vm.expandedSize
        let w = size.width + 40
        let h = size.height + 24
        return CGRect(x: screen.frame.midX - w / 2, y: screen.frame.maxY - h, width: w, height: h)
    }

    private func tick() {
        guard let panel, let screen else { return }
        let mouse = NSEvent.mouseLocation
        let interactive = state.vm.state == .expanded
            ? expandedHotRect(screen).contains(mouse)
            : closedHotRect(screen).contains(mouse)

        if panel.ignoresMouseEvents == interactive {
            panel.ignoresMouseEvents = !interactive
        }
        // Only react to enter/leave transitions — calling hoverChanged every
        // tick would perpetually reschedule the close timer.
        if interactive != lastInteractive {
            lastInteractive = interactive
            state.vm.hoverChanged(interactive)
        }
    }
}
