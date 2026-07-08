import Foundation

/// Thin dlopen bridge to the private MediaRemote framework — the only way to
/// read system-wide now-playing info. Works up to macOS 15.3; on newer
/// releases Apple gated it behind an entitlement, so `MediaController` falls
/// back to AppleScript when this yields nothing.
final class MediaRemoteBridge {
    enum Command: Int32 {
        case play = 0
        case pause = 1
        case togglePlayPause = 2
        case nextTrack = 4
        case previousTrack = 5
    }

    static let infoDidChange = Notification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
    static let isPlayingDidChange = Notification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification")

    private typealias GetInfoFn = @convention(c) (DispatchQueue, @escaping @convention(block) (CFDictionary?) -> Void) -> Void
    private typealias RegisterFn = @convention(c) (DispatchQueue) -> Void
    private typealias SendCommandFn = @convention(c) (Int32, CFDictionary?) -> Bool
    private typealias GetIsPlayingFn = @convention(c) (DispatchQueue, @escaping @convention(block) (Bool) -> Void) -> Void

    private let getInfoFn: GetInfoFn
    private let sendCommandFn: SendCommandFn
    private let getIsPlayingFn: GetIsPlayingFn?

    init?() {
        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
            RTLD_LAZY
        ) else { return nil }

        guard let getInfoPtr = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo"),
              let sendPtr = dlsym(handle, "MRMediaRemoteSendCommand"),
              let registerPtr = dlsym(handle, "MRMediaRemoteRegisterForNowPlayingNotifications")
        else {
            dlclose(handle)
            return nil
        }

        getInfoFn = unsafeBitCast(getInfoPtr, to: GetInfoFn.self)
        sendCommandFn = unsafeBitCast(sendPtr, to: SendCommandFn.self)

        if let isPlayingPtr = dlsym(handle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying") {
            getIsPlayingFn = unsafeBitCast(isPlayingPtr, to: GetIsPlayingFn.self)
        } else {
            getIsPlayingFn = nil
        }

        let register = unsafeBitCast(registerPtr, to: RegisterFn.self)
        register(DispatchQueue.main)
    }

    func fetchNowPlaying(_ completion: @escaping ([String: Any]?) -> Void) {
        getInfoFn(DispatchQueue.main) { dict in
            completion(dict as? [String: Any])
        }
    }

    func fetchIsPlaying(_ completion: @escaping (Bool) -> Void) {
        guard let getIsPlayingFn else {
            completion(false)
            return
        }
        getIsPlayingFn(DispatchQueue.main) { completion($0) }
    }

    @discardableResult
    func send(_ command: Command) -> Bool {
        sendCommandFn(command.rawValue, nil)
    }
}
