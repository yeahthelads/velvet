import Foundation

/// These playful needs never gate notes. Time accrues only while she is awake
/// and available; completing a chosen dance settles restlessness.
struct PerformanceState: Equatable {
    /// A twelve-second phrase: toprock, go-down, alternating footwork,
    /// baby freeze, backspin, and a held side-freeze finish.
    static func breakdancePose(at elapsed: Double) -> Int {
        guard elapsed.isFinite else { return 0 }
        let thresholds = [1.0, 2.0, 2.75, 3.4, 4.05, 4.7, 5.35, 6.7, 7.7, 8.4, 9.2]
        let poses = [0, 1, 2, 3, 4, 3, 4, 5, 6, 3, 5, 7]
        return poses[thresholds.firstIndex { elapsed < $0 } ?? 11]
    }
    /// Standing breath, arabesque, contraction, spiral, floor reach, roll, rise.
    static func contemporaryPose(at elapsed: Double) -> (index: Int, tilt: Double, travel: Double) {
        let boundaries = [1.0, 2.2, 3.3, 4.4, 5.5, 6.8, 8.0, 9.2, 10.3, 11.2]
        let poses = [0, 8, 9, 45, 12, 70, 72, 14, 75, 44, 8]
        let step = boundaries.firstIndex { elapsed < $0 } ?? 10
        let tilt = [0.0, -0.04, -0.07, 0.08, 0.12, -0.04, 0.02, -0.1, 0.05, -0.02, 0][step]
        let travel = [0.0, -2, -4, -2, 1, 3, 4, 2, 0, -1, 0][step]
        return (poses[step], tilt, travel)
    }
    static let applauseDuration = 6.0
    private(set) var restless = false
    private(set) var awaitingApplause = false
    private(set) var applauseRemaining = 0.0
    private(set) var applauseEarnsUnlock = false
    var applauseFraction: Double { min(1, max(0, applauseRemaining / Self.applauseDuration)) }
    var timeUntilRestless: Double = Double.random(in: 12 * 60...18 * 60)
    var isEngaged: Bool { restless || awaitingApplause }
    mutating func makeRestless() { restless = true }
    mutating func settleRestless() { restless = false; timeUntilRestless = Double.random(in: 12 * 60...18 * 60) }
    mutating func beginDance() { cancelApplause() }
    mutating func finishDance(chosen: Bool, earnsUnlock: Bool = true) {
        if chosen {
            restless = false
            timeUntilRestless = Double.random(in: 12 * 60...18 * 60)
        }
        guard !chosen else { cancelApplause(); return }
        awaitingApplause = true
        applauseRemaining = Self.applauseDuration
        applauseEarnsUnlock = earnsUnlock
    }
    @discardableResult mutating func applaud() -> Bool {
        guard awaitingApplause, applauseRemaining > 0 else { return false }
        cancelApplause()
        return true
    }
    mutating func cancelApplause() { awaitingApplause = false; applauseRemaining = 0; applauseEarnsUnlock = false }
    @discardableResult mutating func advanceApplause(by seconds: Double, available: Bool) -> Bool {
        guard awaitingApplause, available, seconds.isFinite, seconds > 0 else { return false }
        applauseRemaining = max(0, applauseRemaining - seconds)
        guard applauseRemaining == 0 else { return false }
        cancelApplause()
        return true
    }
    @discardableResult mutating func advance(by seconds: Double, available: Bool) -> Bool {
        guard available, !isEngaged, seconds.isFinite, seconds > 0 else { return false }
        timeUntilRestless = max(0, timeUntilRestless - seconds)
        if timeUntilRestless == 0 { restless = true; return true }
        return false
    }
}


/// Every three timely claps pays for one dance of the user's choice.
struct DanceProgress: Codable, Equatable {
    static let clapCost = 3
    static let replayCost = 1
    static let danceIDs = ["ballet", "breakdance", "contemporary", "floorwork", "house", "disco", "vogue", "waacking"]
    private(set) var forfeitedUnlocks: Int = 0
    private(set) var replayClapsSpent: Int
    private(set) var careClapsSpent: Int
    private(set) var completedClaps: Int
    private(set) var unlockedDanceIDs: [String]
    init(completedClaps: Int = 0, unlockedDanceIDs: [String] = [], replayClapsSpent: Int = 0, careClapsSpent: Int = 0) {
        self.completedClaps = max(0, completedClaps)
        self.replayClapsSpent = min(max(0, replayClapsSpent), self.completedClaps)
        self.careClapsSpent = min(max(0, careClapsSpent), self.completedClaps - self.replayClapsSpent)
        self.unlockedDanceIDs = Array(Set(unlockedDanceIDs.filter { Self.danceIDs.contains($0) })).sorted()
    }
    private enum CodingKeys: String, CodingKey { case completedClaps, unlockedDanceIDs, replayClapsSpent, careClapsSpent, forfeitedUnlocks }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(completedClaps: try values.decodeIfPresent(Int.self, forKey: .completedClaps) ?? 0, unlockedDanceIDs: try values.decodeIfPresent([String].self, forKey: .unlockedDanceIDs) ?? ["ballet"], replayClapsSpent: try values.decodeIfPresent(Int.self, forKey: .replayClapsSpent) ?? 0, careClapsSpent: try values.decodeIfPresent(Int.self, forKey: .careClapsSpent) ?? 0)
        forfeitedUnlocks = min(completedClaps / Self.clapCost, max(0, try values.decodeIfPresent(Int.self, forKey: .forfeitedUnlocks) ?? 0))
    }
    @discardableResult mutating func revokeDance(_ id: String) -> Bool {
        guard id != "ballet", unlockedDanceIDs.contains(id) else { return false }
        unlockedDanceIDs.removeAll { $0 == id }; forfeitedUnlocks += 1
        return true
    }
    var spentUnlocks: Int { forfeitedUnlocks + unlockedDanceIDs.filter { $0 != "ballet" }.count }
    var clapBalance: Int { max(0, completedClaps - spentUnlocks * Self.clapCost - replayClapsSpent - careClapsSpent) }
    var availableUnlocks: Int { allows("ballet") ? min(Self.danceIDs.count - unlockedDanceIDs.count, clapBalance / Self.clapCost) : 0 }
    var clapsToNextUnlock: Int { max(0, Self.clapCost - clapBalance) }
    func canReplay(_ danceID: String) -> Bool { allows(danceID) && clapBalance >= Self.replayCost }
    @discardableResult mutating func payForReplay(_ danceID: String) -> Bool {
        guard canReplay(danceID) else { return false }
        replayClapsSpent += Self.replayCost
        return true
    }
    @discardableResult mutating func refundReplay() -> Bool {
        guard replayClapsSpent >= Self.replayCost else { return false }
        replayClapsSpent -= Self.replayCost
        return true
    }
    @discardableResult mutating func payForCare(cost: Int) -> Bool {
        guard cost > 0, clapBalance >= cost else { return false }
        careClapsSpent += cost
        return true
    }
    func allows(_ danceID: String) -> Bool { unlockedDanceIDs.contains(danceID) }
    mutating func earnTutorialBallet() {
        if !allows("ballet") { unlockedDanceIDs.append("ballet"); unlockedDanceIDs.sort() }
    }
    mutating func recordClap() { if completedClaps < Int.max { completedClaps += 1 } }
    @discardableResult mutating func unlock(_ danceID: String) -> Bool {
        guard allows("ballet"), availableUnlocks > 0, Self.danceIDs.contains(danceID), !allows(danceID) else { return false }
        unlockedDanceIDs.append(danceID); unlockedDanceIDs.sort()
        return true
    }
}
