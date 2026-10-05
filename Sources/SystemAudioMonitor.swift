import Foundation
import CoreAudio

/// Reads Spotify activity flags and local track notifications; no audio recording.
final class SystemAudioMonitor {
    var onChange: ((Bool) -> Void)?
    private(set) var playing = false
    private var timer: Timer?
    private var trackObserver: NSObjectProtocol?
    private var processListListener: AudioObjectPropertyListenerBlock?
    private var spotifyProcesses: [AudioObjectID] = []
    private var lastProcessScan = -Double.infinity
    private var monitoring = false
    private(set) var processScanCount = 0
    // Core Audio's stable FourCC selectors, from AudioHardware.h. Declaring
    // them here allows builds with SDKs predating the macOS 14.2 process API.
    // Runtime availability is checked before querying these properties.
    private enum ProcessProperty {
        static let list: AudioObjectPropertySelector = 0x70727323 // 'prs#'
        static let pid: AudioObjectPropertySelector = 0x70706964 // 'ppid'
        static let bundleID: AudioObjectPropertySelector = 0x70626964 // 'pbid'
        static let runningOutput: AudioObjectPropertySelector = 0x7069726F // 'piro'
    }
    private static var processListAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: ProcessProperty.list, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    }
    private(set) var playback: SpotifyPlayback?
    private(set) var hasTrackUpdates = false
    var supported: Bool {
        guard #available(macOS 14.2, *) else { return false }
        var address = Self.processListAddress
        return AudioObjectHasProperty(AudioObjectID(kAudioObjectSystemObject), &address)
    }
    func start() {
        stop()
        guard supported else { return }
        trackObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"), object: nil, queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            self.playback = notification.userInfo.flatMap { SpotifyPlayback(notification: $0) }
            self.hasTrackUpdates = self.playback != nil
            self.poll()
        }
        monitoring = true
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            guard let self, self.monitoring else { return }
            self.refreshSpotifyProcesses(); self.poll()
        }
        var address = Self.processListAddress
        if AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, listener) == noErr {
            processListListener = listener
        }
        refreshSpotifyProcesses(); poll()
    }
    func stop() {
        monitoring = false
        timer?.invalidate(); timer = nil
        if let listener = processListListener {
            var address = Self.processListAddress
            AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main, listener)
        }
        processListListener = nil; spotifyProcesses = []; lastProcessScan = -.infinity
        if let observer = trackObserver { DistributedNotificationCenter.default().removeObserver(observer) }
        trackObserver = nil; playback = nil; hasTrackUpdates = false; setPlaying(false)
    }
    private func refreshSpotifyProcesses() {
        guard monitoring else { return }
        processScanCount += 1
        lastProcessScan = ProcessInfo.processInfo.systemUptime
        let ownPID = UInt32(ProcessInfo.processInfo.processIdentifier)
        spotifyProcesses = Self.processes().filter {
            guard let pid = Self.word($0, ProcessProperty.pid), pid != ownPID,
                  let identifier = Self.bundleID($0) else { return false }
            return Self.isSpotifyBundle(identifier)
        }
        // New audio processes wake the listener immediately. The slow fallback
        // handles drivers that omit process-list notifications.
        let interval: TimeInterval = spotifyProcesses.isEmpty ? 10 : 0.5
        if timer?.timeInterval != interval {
            timer?.invalidate()
            timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.poll() }
            timer?.tolerance = interval * 0.2
            RunLoop.main.add(timer!, forMode: .common)
        }
    }
    func poll() {
        guard monitoring else { return }
        if ProcessInfo.processInfo.systemUptime - lastProcessScan >= 10 { refreshSpotifyProcesses() }
        var stale = false
        let active = spotifyProcesses.contains { id in
            guard let running = Self.word(id, ProcessProperty.runningOutput) else { stale = true; return false }
            return running == 1
        }
        if stale { refreshSpotifyProcesses() }
        setPlaying(active)
    }
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
        var address = processListAddress
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
            guard let pid = word(id, ProcessProperty.pid), pid != ownPID else { return false }
            return spotifyProcessPlaying(id)
        }
    }
    static func isSpotifyBundle(_ identifier: String) -> Bool {
        ["com.spotify.client", "com.spotify.client.helper", "com.spotify.client.helper.gpu", "com.spotify.client.helper.renderer", "com.spotify.client.helper.plugin"].contains(identifier)
    }
    private static func bundleID(_ object: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(mSelector: ProcessProperty.bundleID, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var value: Unmanaged<CFString>? = nil
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(object, &address, 0, nil, &size, &value) == noErr else { return nil }
        return value?.takeRetainedValue() as String?
    }
    private static func spotifyProcessPlaying(_ id: AudioObjectID) -> Bool {
        guard let identifier = bundleID(id), isSpotifyBundle(identifier) else { return false }
        return word(id, ProcessProperty.runningOutput) == 1
    }
    static func isSpotifyProcessPlaying(_ pid: Int32) -> Bool {
        guard #available(macOS 14.2, *) else { return false }
        return processes().contains { word($0, ProcessProperty.pid) == UInt32(pid) && spotifyProcessPlaying($0) }
    }
    // Allows a live check against an isolated helper without inspecting app names.
    static func isProcessPlaying(_ pid: Int32) -> Bool {
        guard #available(macOS 14.2, *) else { return false }
        return processes().contains { word($0, ProcessProperty.pid) == UInt32(pid) && word($0, ProcessProperty.runningOutput) == 1 }
    }
    deinit { stop() }
}
