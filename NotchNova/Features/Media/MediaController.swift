import AppKit
import Combine

/// Now-playing state + transport controls. Primary source: MediaRemote
/// (system-wide). Fallback: AppleScript polling of Spotify / Apple Music,
/// which keeps working on macOS 15.4+ where MediaRemote is locked down.
@MainActor
final class MediaController: ObservableObject {
    @Published private(set) var title: String?
    @Published private(set) var artist: String?
    @Published private(set) var artwork: NSImage?
    @Published private(set) var isPlaying = false

    var hasTrack: Bool { title != nil }

    private var bridge: MediaRemoteBridge?
    private var bridgeDelivers = false
    private var pollTimer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var lastArtworkKey: String?

    private enum PlayerApp: String {
        case spotify = "com.spotify.client"
        case music = "com.apple.Music"
        var scriptName: String { self == .spotify ? "Spotify" : "Music" }
    }

    /// Apple restricted third-party access to MediaRemote's now-playing data
    /// starting in macOS 15.4 — calling it there just logs "Operation not
    /// permitted" on every poll. Skip it and use the AppleScript fallback.
    private static var mediaRemoteAvailable: Bool {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        if v.majorVersion > 15 { return false }
        if v.majorVersion == 15, v.minorVersion >= 4 { return false }
        return true
    }

    func start() {
        if Self.mediaRemoteAvailable {
            bridge = MediaRemoteBridge()
        }

        if bridge != nil {
            let center = NotificationCenter.default
            observers.append(center.addObserver(
                forName: MediaRemoteBridge.infoDidChange, object: nil, queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.refreshFromBridge() }
            })
            observers.append(center.addObserver(
                forName: MediaRemoteBridge.isPlayingDidChange, object: nil, queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.refreshFromBridge() }
            })
            refreshFromBridge()
        } else {
            // Populate immediately from Spotify / Music instead of waiting
            // for the first poll tick.
            refreshFromAppleScript()
        }

        // Safety net: covers locked-down MediaRemote and missed notifications.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.bridge != nil, self.bridgeDelivers {
                    self.refreshFromBridge()
                } else {
                    self.refreshFromAppleScript()
                }
            }
        }
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        for o in observers { NotificationCenter.default.removeObserver(o) }
        observers.removeAll()
    }

    // MARK: - Transport

    func togglePlayPause() { sendCommand(.togglePlayPause, script: "playpause") }
    func nextTrack() { sendCommand(.nextTrack, script: "next track") }
    func previousTrack() { sendCommand(.previousTrack, script: "previous track") }

    private func sendCommand(_ command: MediaRemoteBridge.Command, script: String) {
        if let bridge, bridgeDelivers {
            bridge.send(command)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                Task { @MainActor in self?.refreshFromBridge() }
            }
        } else if let app = runningPlayer() {
            runAppleScript("tell application \"\(app.scriptName)\" to \(script)") { [weak self] _ in
                Task { @MainActor in self?.refreshFromAppleScript() }
            }
        }
    }

    // MARK: - MediaRemote path

    private func refreshFromBridge() {
        guard let bridge else { return }
        bridge.fetchNowPlaying { [weak self] info in
            Task { @MainActor in
                guard let self else { return }
                guard let info, !info.isEmpty else {
                    if !self.bridgeDelivers { self.refreshFromAppleScript() }
                    return
                }
                self.bridgeDelivers = true
                self.title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String
                self.artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String
                if let data = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                    self.artwork = NSImage(data: data)
                }
                if let rate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double {
                    self.isPlaying = rate > 0
                } else {
                    bridge.fetchIsPlaying { playing in
                        Task { @MainActor in self.isPlaying = playing }
                    }
                }
            }
        }
    }

    // MARK: - AppleScript fallback

    private func runningPlayer() -> PlayerApp? {
        let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        if running.contains(PlayerApp.spotify.rawValue) { return .spotify }
        if running.contains(PlayerApp.music.rawValue) { return .music }
        return nil
    }

    private func refreshFromAppleScript() {
        guard let app = runningPlayer() else {
            if !bridgeDelivers, title != nil {
                title = nil; artist = nil; artwork = nil; isPlaying = false
            }
            return
        }

        let sep = "|~|"
        let script: String
        if app == .spotify {
            script = """
            tell application "Spotify"
                set st to player state as text
                set t to name of current track
                set a to artist of current track
                set art to artwork url of current track
                return st & "\(sep)" & t & "\(sep)" & a & "\(sep)" & art
            end tell
            """
        } else {
            script = """
            tell application "Music"
                set st to player state as text
                set t to name of current track
                set a to artist of current track
                return st & "\(sep)" & t & "\(sep)" & a & "\(sep)"
            end tell
            """
        }

        runAppleScript(script) { [weak self] output in
            guard let output else { return }
            let parts = output.components(separatedBy: sep)
            guard parts.count >= 3 else { return }
            Task { @MainActor in
                guard let self else { return }
                self.isPlaying = parts[0].trimmingCharacters(in: .whitespacesAndNewlines) == "playing"
                self.title = parts[1]
                self.artist = parts[2]
                if parts.count >= 4, let url = URL(string: parts[3].trimmingCharacters(in: .whitespacesAndNewlines)),
                   url.scheme?.hasPrefix("http") == true {
                    self.loadArtwork(from: url, key: parts[3])
                } else if app == .music {
                    self.artwork = NSWorkspace.shared.runningApplications
                        .first { $0.bundleIdentifier == PlayerApp.music.rawValue }?.icon
                }
            }
        }
    }

    private func loadArtwork(from url: URL, key: String) {
        guard key != lastArtworkKey else { return }
        lastArtworkKey = key
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            Task { @MainActor in self?.artwork = image }
        }.resume()
    }

    private func runAppleScript(_ source: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", source]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            do {
                try process.run()
                process.waitUntilExit()
                guard process.terminationStatus == 0 else {
                    completion(nil)
                    return
                }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                completion(output)
            } catch {
                completion(nil)
            }
        }
    }
}
