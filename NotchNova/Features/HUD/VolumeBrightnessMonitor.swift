import Foundation
import CoreAudio
import CoreGraphics

/// Watches system output volume (CoreAudio listeners) and display brightness
/// (private DisplayServices, polled) and emits HUD events on change.
@MainActor
final class VolumeBrightnessMonitor {
    var onEvent: (@MainActor (HUDEvent) -> Void)?

    // 'vmvc' — virtual main volume, same selector AudioHardwareService uses.
    private let virtualMainVolume = AudioObjectPropertySelector(0x766D_7663)

    private var deviceID = AudioObjectID(kAudioObjectUnknown)
    private var listenerBlock: AudioObjectPropertyListenerBlock?
    private var defaultDeviceBlock: AudioObjectPropertyListenerBlock?
    private var brightnessTimer: Timer?
    private var lastBrightness: Float?

    private typealias GetBrightnessFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private var getBrightness: GetBrightnessFn?

    func start() {
        setupVolumeListeners()
        setupBrightnessPolling()
    }

    func stop() {
        removeVolumeListeners()
        brightnessTimer?.invalidate()
        brightnessTimer = nil
    }

    // MARK: - Volume

    private func setupVolumeListeners() {
        // Track the default output device, re-attach when it changes
        // (AirPods connect, speaker switch, …).
        var defaultAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor in
                self?.removeVolumeListeners()
                self?.attachToDefaultDevice()
            }
        }
        defaultDeviceBlock = block
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &defaultAddr, DispatchQueue.main, block
        )
        attachToDefaultDevice()
    }

    private func attachToDefaultDevice() {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var device = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &device
        )
        guard status == noErr, device != kAudioObjectUnknown else { return }
        deviceID = device

        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor in self?.emitVolume() }
        }
        listenerBlock = block

        for selector in [virtualMainVolume, kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyMute] {
            var listenAddr = AudioObjectPropertyAddress(
                mSelector: selector,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            if AudioObjectHasProperty(device, &listenAddr) {
                AudioObjectAddPropertyListenerBlock(device, &listenAddr, DispatchQueue.main, block)
            }
        }
    }

    private func removeVolumeListeners() {
        guard deviceID != kAudioObjectUnknown, let block = listenerBlock else { return }
        for selector in [virtualMainVolume, kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyMute] {
            var addr = AudioObjectPropertyAddress(
                mSelector: selector,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(deviceID, &addr, DispatchQueue.main, block)
        }
        deviceID = AudioObjectID(kAudioObjectUnknown)
        listenerBlock = nil
    }

    private func emitVolume() {
        guard deviceID != kAudioObjectUnknown else { return }

        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var addr = AudioObjectPropertyAddress(
            mSelector: virtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var status = AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &volume)
        if status != noErr {
            addr.mSelector = kAudioDevicePropertyVolumeScalar
            size = UInt32(MemoryLayout<Float32>.size)
            status = AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &volume)
        }
        guard status == noErr else { return }

        var muted: UInt32 = 0
        var muteAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        if AudioObjectHasProperty(deviceID, &muteAddr) {
            var muteSize = UInt32(MemoryLayout<UInt32>.size)
            AudioObjectGetPropertyData(deviceID, &muteAddr, 0, nil, &muteSize, &muted)
        }

        onEvent?(HUDEvent(kind: .volume, level: Double(volume), muted: muted == 1))
    }

    // MARK: - Brightness

    private func setupBrightnessPolling() {
        guard let handle = dlopen(
            "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices",
            RTLD_LAZY
        ), let sym = dlsym(handle, "DisplayServicesGetBrightness") else { return }
        getBrightness = unsafeBitCast(sym, to: GetBrightnessFn.self)

        brightnessTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollBrightness() }
        }
    }

    private func pollBrightness() {
        guard let getBrightness else { return }
        var value: Float = 0
        guard getBrightness(CGMainDisplayID(), &value) == 0 else { return }
        defer { lastBrightness = value }
        guard let last = lastBrightness else { return }
        if abs(value - last) > 0.004 {
            onEvent?(HUDEvent(kind: .brightness, level: Double(value)))
        }
    }
}
