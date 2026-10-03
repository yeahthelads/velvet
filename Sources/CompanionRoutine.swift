import Foundation

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
    var automaticDanceRate: Double { level < 0.35 || withdrawn ? 0 : 0.25 + level }
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
