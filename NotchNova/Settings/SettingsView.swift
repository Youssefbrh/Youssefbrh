import SwiftUI
import AppKit
import ServiceManagement

struct SettingsView: View {
    @AppStorage(Prefs.Key.openOnHover.rawValue) private var openOnHover = true
    @AppStorage(Prefs.Key.hudEnabled.rawValue) private var hudEnabled = true
    @AppStorage(Prefs.Key.auroraStyle.rawValue) private var auroraStyle = AuroraStyle.ambient.rawValue
    @AppStorage(Prefs.Key.petEnabled.rawValue) private var petEnabled = true
    @AppStorage(Prefs.Key.petPeeks.rawValue) private var petPeeks = true
    @AppStorage(Prefs.Key.petName.rawValue) private var petName = "Nova"
    @AppStorage(Prefs.Key.clipboardEnabled.rawValue) private var clipboardEnabled = true
    @AppStorage(Prefs.Key.alertsEnabled.rawValue) private var alertsEnabled = true
    @AppStorage(Prefs.Key.launchAtLogin.rawValue) private var launchAtLogin = false

    @State private var diagnosis: String?
    @State private var testing = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Open the notch on hover", isOn: $openOnHover)
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !enabled
                        }
                    }
            }

            Section("Notch") {
                Toggle("Volume & brightness HUD in the notch", isOn: $hudEnabled)
                Toggle("Sneak alerts (battery, timer, drops…)", isOn: $alertsEnabled)
                Picker("Aurora glow", selection: $auroraStyle) {
                    ForEach(AuroraStyle.allCases) { style in
                        Text(style.label).tag(style.rawValue)
                    }
                }
            }

            Section("Pet") {
                Toggle("Enable pet", isOn: $petEnabled)
                Toggle("Pet peeks from the closed notch", isOn: $petPeeks)
                    .disabled(!petEnabled)
                TextField("Pet name", text: $petName)
                    .disabled(!petEnabled)
            }

            Section("Tools") {
                Toggle("Clipboard history", isOn: $clipboardEnabled)
            }

            Section("Now Playing connection") {
                HStack {
                    Button {
                        runDiagnostic()
                    } label: {
                        if testing {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Test connection")
                        }
                    }
                    .disabled(testing)

                    if let diagnosis, diagnosis.hasPrefix("🔒") {
                        Button("Open Automation Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }

                if let diagnosis {
                    Text(diagnosis)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section {
                Text("NotchNova is a local app — nothing leaves your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 560)
    }

    private func runDiagnostic() {
        testing = true
        diagnosis = nil
        AppState.shared.media.diagnose { result in
            diagnosis = result
            testing = false
        }
    }
}
