import Foundation
import CoreAudio

/// Reads playback activity flags only; no taps, samples, microphone or recording.
final class SystemAudioMonitor {
    var onChange: ((Bool) -> Void)?
    private(set) var playing = false
    private var timer: Timer?
    var supported: Bool { if #available(macOS 14.2, *) { return true }; return false }
    func start() {
        stop()
        guard supported else { return }
        poll()
        // Polling also handles audio processes appearing/disappearing and drivers
        // that don't send running-output property notifications reliably.
        timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in self?.poll() }
        timer?.tolerance = 0.1
        RunLoop.main.add(timer!, forMode: .common)
    }
    func stop() { timer?.invalidate(); timer = nil; setPlaying(false) }
    func poll() { setPlaying(Self.spotifyPlaybackActive()) }
    private func setPlaying(_ value: Bool) {
        guard value != playing else { return }
        playing = value; onChange?(value)
    }
    private static func word(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) -> UInt32? {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var result: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(object, &address, 0, nil, &size, &result) == noErr else { return nil }
        return result
    }
    private static func processes() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyProcessObjectList, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr, size > 0 else { return [] }
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        let status = ids.withUnsafeMutableBytes { AudioObjectGetPropertyData(system, &address, 0, nil, &size, $0.baseAddress!) }
        guard status == noErr else { return [] }
        return Array(ids.prefix(Int(size) / MemoryLayout<AudioObjectID>.size))
    }
    static func spotifyPlaybackActive() -> Bool {
        guard #available(macOS 14.2, *) else { return false }
        let ownPID = UInt32(ProcessInfo.processInfo.processIdentifier)
        return processes().contains { id in
            guard let pid = word(id, kAudioProcessPropertyPID), pid != ownPID else { return false }
            return spotifyProcessPlaying(id)
        }
    }
    static func isSpotifyBundle(_ identifier: String) -> Bool {
        ["com.spotify.client", "com.spotify.client.helper", "com.spotify.client.helper.gpu", "com.spotify.client.helper.renderer", "com.spotify.client.helper.plugin"].contains(identifier)
    }
    private static func bundleID(_ object: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(mSelector: kAudioProcessPropertyBundleID, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var value: Unmanaged<CFString>? = nil
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(object, &address, 0, nil, &size, &value) == noErr else { return nil }
        return value?.takeRetainedValue() as String?
    }
    private static func spotifyProcessPlaying(_ id: AudioObjectID) -> Bool {
        guard let identifier = bundleID(id), isSpotifyBundle(identifier) else { return false }
        return word(id, kAudioProcessPropertyIsRunningOutput) == 1
    }
    static func isSpotifyProcessPlaying(_ pid: Int32) -> Bool {
        guard #available(macOS 14.2, *) else { return false }
        return processes().contains { word($0, kAudioProcessPropertyPID) == UInt32(pid) && spotifyProcessPlaying($0) }
    }
    // Allows a live check against an isolated helper without inspecting app names.
    static func isProcessPlaying(_ pid: Int32) -> Bool {
        guard #available(macOS 14.2, *) else { return false }
        return processes().contains { word($0, kAudioProcessPropertyPID) == UInt32(pid) && word($0, kAudioProcessPropertyIsRunningOutput) == 1 }
    }
    deinit { timer?.invalidate() }
}
