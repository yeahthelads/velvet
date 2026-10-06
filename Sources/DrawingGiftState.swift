import Foundation

struct DrawingKeepsake: Codable, Equatable, Identifiable {
    let id: String
    let receivedAt: Date
    static let robotsID = "robots-kiss-v1"
    var title: String { "Two little robots" }
    var resourceName: String { "drawing-robots-kiss-v1" }
}

/// An affectionate surprise, earned once for each available illustration.
/// Clocks accrue only during eligible desktop time; gifts never expire.
struct DrawingGiftState: Codable, Equatable {
    enum Phase: String, Codable { case idle, drawing, offering, waiting }
    static let interval = 35.0 * 60...55.0 * 60
    static let drawingDuration = 10.0
    static let offeringDuration = 6.0
    static let happyDuration = 120.0
    static let minimumHappiness = 0.55
    private(set) var phase = Phase.idle
    private(set) var remaining = 0.0
    private(set) var happySeconds = 0.0
    private(set) var careKinds: [String] = []
    private(set) var received: [DrawingKeepsake] = []
    var timeUntilGift: Double
    var working: Bool { phase == .drawing || phase == .offering }
    var hasUnclaimed: Bool { phase == .offering || phase == .waiting }
    var hasPicture: Bool { phase != .idle }
    var elapsed: Double {
        max(0, (phase == .drawing ? Self.drawingDuration : Self.offeringDuration) - remaining)
    }
    init(timeUntilGift: Double = Double.random(in: Self.interval)) {
        self.timeUntilGift = timeUntilGift.isFinite ? min(Self.interval.upperBound, max(0, timeUntilGift)) : Self.interval.lowerBound
    }
    private enum CodingKeys: String, CodingKey { case phase, remaining, happySeconds, careKinds, received, timeUntilGift }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(timeUntilGift: try c.decodeIfPresent(Double.self, forKey: .timeUntilGift) ?? Self.interval.lowerBound)
        phase = try c.decodeIfPresent(Phase.self, forKey: .phase) ?? .idle
        let duration = phase == .drawing ? Self.drawingDuration : Self.offeringDuration
        let value = try c.decodeIfPresent(Double.self, forKey: .remaining) ?? duration
        remaining = value.isFinite ? min(duration, max(0, value)) : duration
        let happy = try c.decodeIfPresent(Double.self, forKey: .happySeconds) ?? 0
        happySeconds = happy.isFinite ? min(Self.happyDuration, max(0, happy)) : 0
        careKinds = Array(Set((try c.decodeIfPresent([String].self, forKey: .careKinds) ?? []).filter { HappinessState.Care(rawValue: $0) != nil })).sorted()
        received = (try c.decodeIfPresent([DrawingKeepsake].self, forKey: .received) ?? []).filter { $0.id == DrawingKeepsake.robotsID }.prefix(1).map { $0 }
        if !received.isEmpty || !working { remaining = 0 }
        if !received.isEmpty { phase = .idle }
    }
    mutating func recordCare(_ kind: HappinessState.Care) {
        guard phase == .idle, received.isEmpty, !careKinds.contains(kind.rawValue) else { return }
        careKinds.append(kind.rawValue); careKinds.sort()
    }
    mutating func advance(by seconds: Double, available: Bool, happiness: Double) {
        guard available, seconds.isFinite, seconds > 0 else { return }
        if working {
            remaining = max(0, remaining - seconds)
            if remaining == 0 {
                if phase == .drawing { phase = .offering; remaining = Self.offeringDuration }
                else { phase = .waiting }
            }
            return
        }
        guard phase == .idle, received.isEmpty else { return }
        timeUntilGift = max(0, timeUntilGift - seconds)
        happySeconds = happiness >= Self.minimumHappiness ? min(Self.happyDuration, happySeconds + seconds) : 0
        guard timeUntilGift == 0, happySeconds == Self.happyDuration,
              careKinds.count >= 3, careKinds.contains(HappinessState.Care.pet.rawValue) else { return }
        phase = .drawing; remaining = Self.drawingDuration
    }
    @discardableResult mutating func accept(at date: Date = Date()) -> DrawingKeepsake? {
        guard hasUnclaimed, received.isEmpty else { return nil }
        let picture = DrawingKeepsake(id: DrawingKeepsake.robotsID, receivedAt: date)
        received.append(picture); phase = .idle; remaining = 0
        return picture
    }
}
