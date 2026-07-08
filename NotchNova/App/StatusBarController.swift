import AppKit

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let state: AppState
    private var settingsWindow: SettingsWindowController?

    init(state: AppState) {
        self.state = state
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "sparkles.rectangle.stack",
                accessibilityDescription: "NotchNova"
            )
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Open Notch", action: #selector(openNotch), keyEquivalent: "o").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit NotchNova", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
    }

    @objc private func openNotch() {
        state.vm.open(tab: .home)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController(state: state)
        }
        settingsWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
