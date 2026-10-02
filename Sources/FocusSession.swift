import Foundation

struct FocusSession: Equatable {
    enum Phase { case inactive, running, paused, complete }
    private(set) var phase: Phase = .inactive
    private(set) var duration: TimeInterval = 0
    private(set) var remaining: TimeInterval = 0
    var isActive: Bool { phase == .running || phase == .paused }
    static let stretchDuration = 14.0
    static let stretchInterval = 180.0
    static let wakeDuration = 4.2
    static func wakePoseStep(at elapsed: TimeInterval) -> Int {
        [0.45, 1.0, 1.6, 2.3, 3.2, 3.45].firstIndex { elapsed < $0 } ?? 6
    }
    static let adjustableRange = 60.0...86400.0
    var elapsed: TimeInterval { duration - remaining }
    var stretchElapsed: TimeInterval { elapsed.truncatingRemainder(dividingBy: Self.stretchInterval) }
    static func stretchPoseStep(at elapsed: TimeInterval) -> Int {
        [1.5, 3.5, 6.0, 7.5, 9.0, 10.7, 12.7].firstIndex { elapsed < $0 } ?? 7
    }
    var isStretching: Bool { phase == .running && (duration - remaining).truncatingRemainder(dividingBy: Self.stretchInterval) < Self.stretchDuration }
    var label: String {
        if phase == .complete { return "done ✓" }
        if phase == .inactive { return "focus" }
        return Self.formatTime(remaining)
    }
    static func formatTime(_ value: TimeInterval) -> String {
        let seconds = max(0, Int(ceil(value)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    mutating func adjustRemaining(to seconds: TimeInterval) {
        guard isActive, seconds.isFinite else { return }
        let timeSpent = elapsed
        remaining = min(Self.adjustableRange.upperBound, max(Self.adjustableRange.lowerBound, seconds))
        duration = timeSpent + remaining
    }
    mutating func start(seconds: TimeInterval) {
        guard seconds.isFinite, seconds > 0 else { return }
        duration = seconds; remaining = seconds; phase = .running
    }
    mutating func togglePaused() {
        if phase == .running { phase = .paused }
        else if phase == .paused { phase = .running }
    }
    mutating func end() { self = FocusSession() }
    @discardableResult mutating func advance(by seconds: TimeInterval) -> Bool {
        guard phase == .running, seconds.isFinite, seconds > 0 else { return false }
        remaining = max(0, remaining - seconds)
        if remaining == 0 { phase = .complete; return true }
        return false
    }
}

/// A drag is anchored to the original duration so redraws and repeated events
/// cannot compound the change. Positive vertical distance means dragging up.
struct FocusDurationDrag {
    let originalSeconds: TimeInterval
    private(set) var hasDragged = false
    mutating func update(upwardDistance: Double) -> TimeInterval? {
        guard upwardDistance.isFinite else { return nil }
        if abs(upwardDistance) >= 3 { hasDragged = true }
        guard hasDragged else { return nil }
        let steps = (upwardDistance / 6).rounded()
        let value = originalSeconds + steps * 60
        return min(FocusSession.adjustableRange.upperBound, max(FocusSession.adjustableRange.lowerBound, value))
    }
}
