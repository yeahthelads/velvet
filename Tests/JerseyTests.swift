import Foundation

@main struct JerseyTests {
    static func main() {
        var cadence = JerseyCadence()
        precondition(!cadence.accept(now: 100, chance: 0.25, roll: 0.3))
        precondition(cadence.lastPlayed == nil)
        precondition(cadence.accept(now: 100, chance: 0.25, roll: 0.1))
        for moment in [100.0, 101, 120, 144.99] {
            precondition(!cadence.accept(now: moment, chance: 1, roll: 0))
        }
        precondition(cadence.accept(now: 145, chance: 1, roll: 0.9))
        precondition(!cadence.accept(now: 90, chance: 1, roll: 0))
        precondition(!cadence.accept(now: .infinity, chance: 1, roll: 0))
        precondition(!cadence.accept(now: 200, chance: 0, roll: 0))
        precondition(cadence.accept(now: 200, chance: 1, roll: 0))
        print("PASS: probabilistic reactions, shared 45-second cooldown, rejected rolls do not consume cooldown")
    }
}
