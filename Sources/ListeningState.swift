import Foundation

/// Reacts to sustained playback, with a grace period for gaps between tracks.
struct ListeningState: Equatable {
    enum Phase: Equatable { case inactive, puttingOn, listening, takingOff }
    static let onsetDelay = 1.0
    static let putOnDuration = 1.6
    static let silenceDelay = 3.0
    static let takeOffDuration = 0.7
    private(set) var phase: Phase = .inactive
    private(set) var elapsed = 0.0
    private var onset = 0.0
    private var silence = 0.0
    var isActive: Bool { phase != .inactive }
    mutating func reset() { self = ListeningState() }
    mutating func advance(by seconds: Double, playing: Bool, available: Bool, paused: Bool = false) {
        guard available else { reset(); return }
        guard !paused, seconds.isFinite, seconds > 0 else { return }
        if playing { silence = 0 } else { silence += seconds }
        switch phase {
        case .inactive:
            onset = playing ? onset + seconds : 0
            if onset >= Self.onsetDelay { phase = .puttingOn; elapsed = 0; onset = 0 }
        case .puttingOn, .listening:
            if silence >= Self.silenceDelay { phase = .takingOff; elapsed = 0 }
            else {
                elapsed += seconds
                if phase == .puttingOn && elapsed >= Self.putOnDuration { phase = .listening; elapsed = 0 }
            }
        case .takingOff:
            if playing { phase = .puttingOn; elapsed = 0 }
            else {
                elapsed += seconds
                if elapsed >= Self.takeOffDuration { reset() }
            }
        }
    }
}
