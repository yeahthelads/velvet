import Foundation

/// Ordinary note use never counts as stimulation. Six deliberate pets, moves,
/// or dance choices in twenty seconds ask for a little quiet company.
struct StimulationState: Equatable {
    static let recoveryDuration = 30.0
    private(set) var overstimulated = false
    private(set) var quietRemaining = 0.0
    private(set) var cooldownRemaining = 0.0
    private var interactions: [Double] = []

    init(cooldown: Double = 0) { cooldownRemaining = max(0, cooldown) }

    @discardableResult mutating func interact(at time: Double) -> Bool {
        guard time.isFinite else { return false }
        guard !overstimulated else { return false }
        guard cooldownRemaining == 0 else { return false }
        interactions.removeAll { time - $0 > 20 || time < $0 }
        interactions.append(time)
        guard interactions.count >= 6 else { return false }
        makeOverstimulated()
        return true
    }
    mutating func makeOverstimulated() {
        guard !overstimulated else { return }
        overstimulated = true; quietRemaining = Self.recoveryDuration
        interactions.removeAll()
    }
    @discardableResult mutating func advance(by seconds: Double, available: Bool) -> Bool {
        guard available, seconds.isFinite, seconds > 0 else { return false }
        if overstimulated {
            quietRemaining = max(0, quietRemaining - seconds)
            if quietRemaining == 0 {
                overstimulated = false; cooldownRemaining = 60
                return true
            }
        } else { cooldownRemaining = max(0, cooldownRemaining - seconds) }
        return false
    }
}
