import AppKit

/// Measures the physical notch of the target screen, or synthesizes one on
/// flat displays so the app still works everywhere.
struct NotchGeometry: Equatable {
    var notchWidth: CGFloat
    var notchHeight: CGFloat
    var isReal: Bool

    static let fallback = NotchGeometry(notchWidth: 196, notchHeight: 32, isReal: false)

    static func measure(on screen: NSScreen) -> NotchGeometry {
        let topInset = screen.safeAreaInsets.top
        guard topInset > 0,
              let left = screen.auxiliaryTopLeftArea,
              let right = screen.auxiliaryTopRightArea else {
            return .fallback
        }
        let width = screen.frame.width - left.width - right.width
        guard width > 0 else { return .fallback }
        return NotchGeometry(notchWidth: width, notchHeight: topInset, isReal: true)
    }

    /// The screen the notch UI should live on: prefer a built-in notched
    /// display, fall back to the main screen.
    static func preferredScreen() -> NSScreen? {
        NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main
    }
}
