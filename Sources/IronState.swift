import Foundation

/// A robot-only care need: screws replenish iron; sleep and coffee do not.
struct IronState: Codable, Equatable {
    enum Phase: String, Codable { case okay, requested, low }
    static let interval = 25.0 * 60...35.0 * 60
    static let gracePeriod = 120.0
    static let biteDuration = 3.5
    static let rescueClapCost = 1
    static let retryDelay = 5.0 * 60
    static let neglectedDuration = 8.0
    private(set) var phase = Phase.okay
    private(set) var timeUntilNeed: Double
    private(set) var requestRemaining = 0.0
    private(set) var eatingRemaining = 0.0
    private(set) var retryRemaining = Self.retryDelay
    private(set) var neglectedRemaining = 0.0
    var feelsNeglected: Bool { lowIron && neglectedRemaining > 0 }
    var needsScrews: Bool { phase != .okay }
    var freeOfferAvailable: Bool { phase == .requested || (lowIron && requestRemaining > 0) }
    var lowIron: Bool { phase == .low }
    var eating: Bool { eatingRemaining > 0 }
    var deadlineFraction: Double { min(1, max(0, requestRemaining / Self.gracePeriod)) }
    init(timeUntilNeed: Double = Double.random(in: Self.interval)) { self.timeUntilNeed = timeUntilNeed.isFinite ? max(0, timeUntilNeed) : Self.interval.lowerBound }
    private enum CodingKeys: String, CodingKey { case phase, timeUntilNeed, requestRemaining, eatingRemaining, retryRemaining, neglectedRemaining }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        phase = try c.decodeIfPresent(Phase.self, forKey: .phase) ?? .okay
        func bounded(_ key: CodingKeys, _ fallback: Double, _ maximum: Double) throws -> Double {
            let value = try c.decodeIfPresent(Double.self, forKey: key) ?? fallback
            return value.isFinite ? min(maximum, max(0, value)) : fallback
        }
        timeUntilNeed = try bounded(.timeUntilNeed, Self.interval.lowerBound, Self.interval.upperBound)
        requestRemaining = try bounded(.requestRemaining, phase == .requested ? Self.gracePeriod : 0, Self.gracePeriod)
        eatingRemaining = try bounded(.eatingRemaining, 0, Self.biteDuration)
        neglectedRemaining = try bounded(.neglectedRemaining, 0, Self.neglectedDuration)
        retryRemaining = try bounded(.retryRemaining, Self.retryDelay, Self.retryDelay)
        if phase == .requested && requestRemaining == 0 { phase = .low }
        if phase == .okay { requestRemaining = 0 }
    }
    mutating func advance(by seconds: Double, available: Bool) {
        guard available, seconds.isFinite, seconds > 0 else { return }
        if eating { eatingRemaining = max(0, eatingRemaining - seconds); return }
        switch phase {
        case .okay:
            timeUntilNeed = max(0, timeUntilNeed - seconds)
            if timeUntilNeed == 0 { phase = .requested; requestRemaining = Self.gracePeriod }
        case .requested:
            requestRemaining = max(0, requestRemaining - seconds)
            if requestRemaining == 0 { phase = .low }
        case .low:
            neglectedRemaining = max(0, neglectedRemaining - seconds)
            if requestRemaining > 0 {
                requestRemaining = max(0, requestRemaining - seconds)
                if requestRemaining == 0 { retryRemaining = Self.retryDelay }
            } else {
                retryRemaining = max(0, retryRemaining - seconds)
                if retryRemaining == 0 { requestRemaining = Self.gracePeriod }
            }
        }
    }
    mutating func feelNeglected() {
        guard lowIron && !freeOfferAvailable else { return }
        neglectedRemaining = Self.neglectedDuration
    }
    @discardableResult mutating func feed() -> Bool {
        guard needsScrews, !eating else { return false }
        phase = .okay; requestRemaining = 0; retryRemaining = Self.retryDelay; neglectedRemaining = 0
        timeUntilNeed = Double.random(in: Self.interval); eatingRemaining = Self.biteDuration
        return true
    }
}
