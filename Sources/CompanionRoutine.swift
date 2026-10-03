import Foundation

/// Care builds a lasting good mood. Repeated taps and lattes do not stack rewards.
struct HappinessState: Codable, Equatable {
    enum Care: String, CaseIterable { case pet, coffee, food, attention }
    static let minimumDanceRest = 120.0
    private(set) var level = 0.35
    private(set) var danceRestRemaining = 0.0
    private(set) var careDanceDelay: Double?
    private var cooldowns: [String: Double] = [:]
    private enum CodingKeys: String, CodingKey { case level, danceRestRemaining, careDanceDelay, cooldowns }
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func number(_ key: CodingKeys, fallback: Double, maximum: Double) throws -> Double {
            let value = try c.decodeIfPresent(Double.self, forKey: key) ?? fallback
            return value.isFinite ? min(maximum, max(0, value)) : fallback
        }
        level = try number(.level, fallback: 0.35, maximum: 1)
        danceRestRemaining = try number(.danceRestRemaining, fallback: 0, maximum: Self.minimumDanceRest)
        if let value = try c.decodeIfPresent(Double.self, forKey: .careDanceDelay), value.isFinite { careDanceDelay = min(20, max(0, value)) }
        for (key, value) in try c.decodeIfPresent([String: Double].self, forKey: .cooldowns) ?? [:] where Care(rawValue: key) != nil && value.isFinite {
            cooldowns[key] = min(8 * 60, max(0, value))
        }
    }
    var danceRate: Double { 1 + level }
    var allowsDance: Bool { danceRestRemaining == 0 }
    var careDanceReady: Bool { level >= 0.35 && careDanceDelay == 0 && allowsDance }
    @discardableResult mutating func receive(_ care: Care, delay: Double = Double.random(in: 8...20)) -> Bool {
        guard cooldowns[care.rawValue, default: 0] == 0 else { return false }
        let reward: Double, cooldown: Double
        switch care {
        case .pet: reward = 0.20; cooldown = 90
        case .coffee: reward = 0.24; cooldown = 8 * 60
        case .food: reward = 0.20; cooldown = 90
        case .attention: reward = 0.12; cooldown = 60
        }
        level = min(1, level + reward); cooldowns[care.rawValue] = cooldown
        if careDanceDelay == nil { careDanceDelay = delay.isFinite ? min(20, max(8, delay)) : 12 }
        return true
    }
    enum Disappointment { case missedAttention, missedApplause, poked, tumble, overwhelmed, phoneInterrupted, caffeineCrash }
    mutating func disappoint(_ reason: Disappointment) {
        let penalty: Double
        switch reason {
        case .missedAttention, .tumble: penalty = 0.10
        case .missedApplause, .poked: penalty = 0.08
        case .overwhelmed: penalty = 0.20
        case .caffeineCrash: penalty = 0.25
        case .phoneInterrupted: penalty = 0.45
        }
        level = max(0, level - penalty); careDanceDelay = nil
    }
    mutating func missedAttention() { disappoint(.missedAttention) }
    mutating func performedDance() { danceRestRemaining = Self.minimumDanceRest; careDanceDelay = nil }
    mutating func advance(by seconds: Double, available: Bool, canDance: Bool) {
        guard available, seconds.isFinite, seconds > 0 else { return }
        level = 0.15 + (level - 0.15) * pow(0.5, seconds / (18 * 60))
        let waiting = danceRestRemaining
        danceRestRemaining = max(0, waiting - seconds)
        for key in Array(cooldowns.keys) { cooldowns[key] = max(0, cooldowns[key]! - seconds) }
        if level < 0.35 { careDanceDelay = nil }
        if canDance, let delay = careDanceDelay { careDanceDelay = max(0, delay - max(0, seconds - waiting)) }
    }
}

/// A cuddle after bedtime is a short visit, never a full-energy morning wake-up.
struct NightVisit {
    static let duration = 30.0
    private(set) var remaining = 0.0
    var active: Bool { remaining > 0 }
    @discardableResult mutating func wake() -> Bool {
        guard !active else { return false }; remaining = Self.duration; return true
    }
    mutating func end() { remaining = 0 }
    @discardableResult mutating func advance(by seconds: Double, available: Bool) -> Bool {
        guard active, available, seconds.isFinite, seconds > 0 else { return false }
        remaining = max(0, remaining - seconds); return !active
    }
}

/// A rare quiet-time opportunity, independent of the regular idle playlist.
struct SolitaryYoga {
    static let interval = 15.0 * 60...25.0 * 60
    static let minimumSolitude = 5.0 * 60
    private(set) var aloneSeconds = 0.0
    private(set) var remaining: Double
    init(remaining: Double = Double.random(in: Self.interval)) { self.remaining = remaining }
    var ready: Bool { aloneSeconds >= Self.minimumSolitude && remaining <= 0 }
    mutating func interact() { aloneSeconds = 0 }
    mutating func advance(by seconds: Double, alone: Bool, available: Bool) {
        if !alone { interact(); return }
        guard available, seconds.isFinite, seconds > 0 else { return }
        aloneSeconds += seconds
        remaining = max(0, remaining - seconds)
    }
    mutating func performed() { remaining = Double.random(in: Self.interval) }
}

/// Recent company changes her enthusiasm gradually, not by counting rapid taps.
struct ActivityState: Codable, Equatable {
    enum Interaction { case hover, pet, move, attention }
    private(set) var level = 0.45
    private(set) var missedBids = 0
    private var lastHover = -Double.infinity
    private var lastPet = -Double.infinity
    private var lastMove = -Double.infinity
    private enum CodingKeys: String, CodingKey { case level, missedBids }
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let value = try c.decodeIfPresent(Double.self, forKey: .level) ?? 0.45
        level = value.isFinite ? min(1, max(0, value)) : 0.45
        missedBids = min(4, max(0, try c.decodeIfPresent(Int.self, forKey: .missedBids) ?? 0))
    }
    var withdrawn: Bool { level < 0.25 || missedBids >= 2 }
    var automaticDanceRate: Double { withdrawn ? 0 : 0.9 + level * 0.35 }
    var idleInterval: Double { 65 - level * 43 + Double(missedBids) * 8 }
    mutating func advance(by seconds: Double, available: Bool) {
        guard available, seconds.isFinite, seconds > 0 else { return }
        level = 0.08 + (level - 0.08) * pow(0.5, seconds / (12 * 60))
    }
    @discardableResult mutating func interact(_ kind: Interaction, at time: Double) -> Bool {
        guard time.isFinite else { return false }
        let amount: Double
        switch kind {
        case .hover:
            guard time - lastHover >= 30 else { return false }; lastHover = time; amount = 0.07
        case .pet:
            guard time - lastPet >= 4 else { return false }; lastPet = time; amount = 0.14
        case .move:
            guard time - lastMove >= 8 else { return false }; lastMove = time; amount = 0.10
        case .attention: amount = 0.16
        }
        level = min(1, level + amount)
        if kind != .hover { missedBids = max(0, missedBids - 1) }
        return true
    }
    mutating func missedAttention() { missedBids = min(4, missedBids + 1); level = max(0.08, level - 0.12) }
}

/// Wall-clock bedtime, including launches after midnight and DST transitions.
struct DailyRoutine: Codable, Equatable {
    enum Period { case awake, windingDown, asleep }
    private(set) var period = Period.awake
    private(set) var bellySleep = false
    private var sleepDay: Int?
    private enum CodingKeys: String, CodingKey { case bellySleep, sleepDay }
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bellySleep = try c.decodeIfPresent(Bool.self, forKey: .bellySleep) ?? false
        sleepDay = try c.decodeIfPresent(Int.self, forKey: .sleepDay)
    }
    static func period(at date: Date, calendar: Calendar = .autoupdatingCurrent) -> Period {
        let hour = calendar.component(.hour, from: date)
        if hour >= 23 || hour < 8 { return .asleep }
        return hour >= 22 ? .windingDown : .awake
    }
    @discardableResult mutating func update(at date: Date, calendar: Calendar = .autoupdatingCurrent, bellyChoice: Bool? = nil) -> Bool {
        let next = Self.period(at: date, calendar: calendar)
        if next == .asleep {
            let night = calendar.component(.hour, from: date) < 8 ? calendar.date(byAdding: .day, value: -1, to: date)! : date
            let c = calendar.dateComponents([.year, .month, .day], from: night)
            let day = c.year! * 10000 + c.month! * 100 + c.day!
            if sleepDay != day { sleepDay = day; bellySleep = bellyChoice ?? (Int.random(in: 0..<4) == 0) }
        }
        let changed = period != next
        period = next
        return changed
    }
}
