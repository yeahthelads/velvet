import Foundation

/// These playful needs never gate notes. Time accrues only while she is awake
/// and available; completing a chosen dance settles restlessness.
struct PerformanceState: Equatable {
    static let applauseChance = 0.15
    static func asksForApplause(roll: Double = Double.random(in: 0..<1), chance: Double = applauseChance) -> Bool {
        roll.isFinite && roll >= 0 && roll < 1 && roll < chance
    }
    private(set) var restless = false
    private(set) var awaitingApplause = false
    var timeUntilRestless: Double = Double.random(in: 6 * 60...10 * 60)
    var isEngaged: Bool { restless || awaitingApplause }
    mutating func makeRestless() { restless = true }
    mutating func beginDance() { awaitingApplause = false }
    mutating func finishDance(chosen: Bool, asksForApplause: Bool) {
        if chosen {
            restless = false
            timeUntilRestless = Double.random(in: 6 * 60...10 * 60)
        }
        awaitingApplause = asksForApplause
    }
    @discardableResult mutating func applaud() -> Bool {
        guard awaitingApplause else { return false }
        awaitingApplause = false
        return true
    }
    mutating func cancelApplause() { awaitingApplause = false }
    @discardableResult mutating func advance(by seconds: Double, available: Bool) -> Bool {
        guard available, !isEngaged, seconds.isFinite, seconds > 0 else { return false }
        timeUntilRestless = max(0, timeUntilRestless - seconds)
        if timeUntilRestless == 0 { restless = true; return true }
        return false
    }
}
