import Foundation

/// Time advances only while Velvet is visible and unpaused, never while the app is closed.
struct LifestyleState: Codable, Equatable {
    enum Phase: String, Codable { case idle, snack, attention, phone, ignoring, yawning, nap, waking }
    static let danceInterval = 6.0 * 60...10.0 * 60
    static let napInterval = 30.0 * 60...45.0 * 60
    static let ignoreDuration = 45.0
    var energy = 100.0
    var foodRemaining = Double.random(in: 15 * 60...22 * 60)
    var napRemaining = Double.random(in: Self.napInterval)
    var attentionRemaining = Double.random(in: 8 * 60...14 * 60)
    var phoneRemaining = Double.random(in: 12 * 60...20 * 60)
    var danceRemaining = Double.random(in: Self.danceInterval)
    private(set) var needsAttention = false
    private(set) var phase: Phase = .idle
    private(set) var elapsed = 0.0
    private(set) var remaining = 0.0
    var hungry: Bool { foodRemaining <= 0 }
    var sleepy: Bool { energy < 40 || napRemaining < 120 }
    var ignoring: Bool { phase == .ignoring }
    var occupied: Bool { phase != .idle }
    var readyToDance: Bool { !hungry && !sleepy && !needsAttention && !occupied }
    private enum CodingKeys: String, CodingKey { case energy, foodRemaining, napRemaining, attentionRemaining, phoneRemaining, danceRemaining, needsAttention, phase, elapsed, remaining }
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func number(_ key: CodingKeys, _ fallback: Double, _ range: ClosedRange<Double>) throws -> Double {
            let v = try c.decodeIfPresent(Double.self, forKey: key) ?? fallback
            return v.isFinite ? min(range.upperBound, max(range.lowerBound, v)) : fallback
        }
        energy = try number(.energy, 100, 0...100)
        foodRemaining = try number(.foodRemaining, 18 * 60, 0...25 * 60)
        napRemaining = try number(.napRemaining, 35 * 60, 0...45 * 60)
        attentionRemaining = try number(.attentionRemaining, 10 * 60, 0...14 * 60)
        phoneRemaining = try number(.phoneRemaining, 16 * 60, 0...20 * 60)
        danceRemaining = try number(.danceRemaining, 8 * 60, 0...10 * 60)
        needsAttention = try c.decodeIfPresent(Bool.self, forKey: .needsAttention) ?? false
        phase = try c.decodeIfPresent(Phase.self, forKey: .phase) ?? .idle
        elapsed = try number(.elapsed, 0, 0...240)
        remaining = try number(.remaining, 0, 0...240)
    }
    private mutating func enter(_ next: Phase, duration: Double) { phase = next; elapsed = 0; remaining = duration }
    @discardableResult mutating func feed() -> Bool {
        guard hungry, phase == .idle else { return false }
        foodRemaining = Double.random(in: 18 * 60...25 * 60)
        energy = min(100, energy + 15)
        enter(.snack, duration: 6)
        return true
    }
    @discardableResult mutating func acknowledge() -> Bool {
        guard phase == .attention || (phase == .idle && needsAttention) else { return false }
        needsAttention = false
        attentionRemaining = Double.random(in: 8 * 60...14 * 60)
        enter(.idle, duration: 0)
        return true
    }
    @discardableResult mutating func disturbPhone() -> Bool {
        guard phase == .phone else { return false }
        phoneRemaining = Double.random(in: 12 * 60...20 * 60)
        enter(.ignoring, duration: Self.ignoreDuration)
        return true
    }
    @discardableResult mutating func wake() -> Bool {
        guard phase == .nap || phase == .yawning else { return false }
        napRemaining = energy < 35 ? 5 * 60 : Double.random(in: Self.napInterval)
        enter(.waking, duration: 4.2)
        return true
    }
    mutating func restAfterNight() { energy = 100; napRemaining = Double.random(in: Self.napInterval) }
    mutating func finishDance() { energy = max(0, energy - 10); danceRemaining = Double.random(in: Self.danceInterval) }
    mutating func cancelDanceForNotes() { danceRemaining = Double.random(in: Self.danceInterval) }
    @discardableResult mutating func advanceDance(by seconds: Double, available: Bool) -> Bool {
        guard available, readyToDance, seconds.isFinite, seconds > 0 else { return false }
        danceRemaining = max(0, danceRemaining - seconds)
        guard danceRemaining == 0 else { return false }
        danceRemaining = Double.random(in: Self.danceInterval)
        return true
    }
    mutating func advance(by seconds: Double, available: Bool, awake: Bool, free: Bool, focusNap: Bool = false) {
        guard available, seconds.isFinite, seconds > 0 else { return }
        if focusNap { energy = min(100, energy + seconds / 3) }
        if phase != .idle {
            elapsed += seconds
            if phase == .nap { energy = min(100, energy + seconds * 0.5) }
            remaining = max(0, remaining - seconds)
            if remaining == 0 {
                switch phase {
                case .yawning: enter(.nap, duration: Double.random(in: 120...240))
                case .nap: napRemaining = Double.random(in: Self.napInterval); enter(.waking, duration: 4.2)
                case .attention: attentionRemaining = Double.random(in: 8 * 60...14 * 60); enter(.idle, duration: 0)
                default: enter(.idle, duration: 0)
                }
            }
            return
        }
        guard awake else { return }
        energy = max(0, energy - seconds / 27)
        foodRemaining = max(0, foodRemaining - seconds)
        napRemaining = max(0, napRemaining - seconds)
        attentionRemaining = max(0, attentionRemaining - seconds)
        phoneRemaining = max(0, phoneRemaining - seconds)
        guard free else { return }
        if sleepy { enter(.yawning, duration: 4) }
        else if !hungry && attentionRemaining == 0 { needsAttention = true; enter(.attention, duration: 40) }
        else if !hungry && !needsAttention && phoneRemaining == 0 { phoneRemaining = Double.random(in: 12 * 60...20 * 60); enter(.phone, duration: Double.random(in: 25...45)) }
    }
}
