import SwiftUI

enum AuroraStyle: String, CaseIterable, Identifiable {
    case off, ambient, music
    var id: String { rawValue }
    var label: String {
        switch self {
        case .off: return "Off"
        case .ambient: return "Ambient drift"
        case .music: return "Music reactive"
        }
    }
}

enum Theme {
    static let islandBackground = Color.black
    static let surface = Color.white.opacity(0.07)
    static let surfaceHover = Color.white.opacity(0.13)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let accent = Color(red: 0.45, green: 0.75, blue: 1.0)

    static let auroraColors: [Color] = [
        Color(red: 0.35, green: 0.55, blue: 1.0),
        Color(red: 0.75, green: 0.35, blue: 1.0),
        Color(red: 0.25, green: 0.95, blue: 0.75),
        Color(red: 1.0, green: 0.45, blue: 0.65),
    ]

    static let cornerRadius: CGFloat = 22
}

/// UserDefaults-backed preferences, shared between SwiftUI (@AppStorage uses
/// the same keys) and imperative code.
enum Prefs {
    enum Key: String {
        case openOnHover = "pref.openOnHover"
        case hudEnabled = "pref.hudEnabled"
        case auroraStyle = "pref.auroraStyle"
        case petEnabled = "pref.petEnabled"
        case petPeeks = "pref.petPeeks"
        case petName = "pref.petName"
        case clipboardEnabled = "pref.clipboardEnabled"
        case statsEnabled = "pref.statsEnabled"
        case alertsEnabled = "pref.alertsEnabled"
        case launchAtLogin = "pref.launchAtLogin"
    }

    static func bool(_ key: Key, default def: Bool) -> Bool {
        if UserDefaults.standard.object(forKey: key.rawValue) == nil { return def }
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }

    static func string(_ key: Key, default def: String) -> String {
        UserDefaults.standard.string(forKey: key.rawValue) ?? def
    }
}
