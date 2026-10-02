import Foundation

struct CompanionCare: Codable, Equatable {
    enum Upset: String, Codable { case none, annoyed, crying }
    var upset: Upset = .none
    static let tumbleInterval = 30.0 * 60...60.0 * 60
    var timeUntilTumble: TimeInterval
    private var cadenceVersion = 2
    init(upset: Upset = .none, timeUntilTumble: TimeInterval = Double.random(in: Self.tumbleInterval)) {
        self.upset = upset; self.timeUntilTumble = timeUntilTumble
    }
    private enum CodingKeys: String, CodingKey { case upset, timeUntilTumble, cadenceVersion }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        upset = try container.decodeIfPresent(Upset.self, forKey: .upset) ?? .none
        let remaining = try container.decodeIfPresent(Double.self, forKey: .timeUntilTumble) ?? Double.random(in: Self.tumbleInterval)
        let version = try container.decodeIfPresent(Int.self, forKey: .cadenceVersion) ?? 1
        // Rescale an existing countdown once, preserving crying and annoyance.
        timeUntilTumble = version < 2 ? remaining * (2.0 / 3.0) : remaining
        cadenceVersion = 2
    }
    var needsAffection: Bool { upset != .none }
    func canGiveNotes(needsCoffee: Bool) -> Bool { !needsCoffee && !needsAffection }
    mutating func soothe() { upset = .none }
    mutating func annoy() { if upset != .crying { upset = .annoyed } }
    mutating func tumble() {
        upset = .crying
        timeUntilTumble = Double.random(in: Self.tumbleInterval)
    }
    @discardableResult mutating func advanceEligible(by seconds: TimeInterval) -> Bool {
        guard !needsAffection, seconds.isFinite, seconds > 0 else { return false }
        timeUntilTumble = max(0, timeUntilTumble - seconds)
        if timeUntilTumble == 0 { tumble(); return true }
        return false
    }
}
