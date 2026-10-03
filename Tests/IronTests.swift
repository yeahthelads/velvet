import Foundation
@main enum IronTests {
    static func main() throws {
        var iron = IronState(timeUntilNeed: 0)
        iron.advance(by: 200, available: true)
        precondition(iron.phase == .requested && iron.requestRemaining == 120, "A new visible request gets its full two minutes")
        iron.advance(by: 119.9, available: true); precondition(!iron.lowIron)
        let paused = iron
        iron.advance(by: 1000, available: false); iron.advance(by: -.infinity, available: true)
        precondition(iron == paused)
        iron.advance(by: 0.11, available: true); precondition(iron.lowIron)
        precondition(!iron.freeOfferAvailable, "Expired screws disappear")
        iron.feelNeglected(); precondition(iron.feelsNeglected)
        iron.advance(by: 8, available: true)
        precondition(!iron.feelsNeglected && iron.lowIron && !iron.freeOfferAvailable, "Crying ends without curing iron or skipping cooldown")
        iron.advance(by: 291, available: true); precondition(iron.lowIron && !iron.freeOfferAvailable)
        iron.advance(by: 1, available: true)
        precondition(iron.lowIron && iron.freeOfferAvailable && iron.requestRemaining == 120, "Retry offers screws without curing deficiency")
        iron.advance(by: 120, available: true); precondition(iron.lowIron && !iron.freeOfferAvailable)
        iron.advance(by: 10000, available: false); precondition(iron.lowIron && iron.retryRemaining == 300)
        let restored = try JSONDecoder().decode(IronState.self, from: JSONEncoder().encode(iron))
        precondition(restored == iron && restored.lowIron)
        precondition(iron.feed() && !iron.lowIron && iron.eating && !iron.feed())
        iron.advance(by: 3.5, available: true); precondition(!iron.eating && !iron.feed())
        precondition(IronState.interval.contains(iron.timeUntilNeed))
        var normal = LifestyleState(); normal.energy = 90; normal.napRemaining = 1000
        var low = normal
        normal.advance(by: 120, available: true, awake: true, free: false)
        low.advance(by: 120, available: true, awake: true, free: false, lowIron: true)
        precondition(low.energy < normal.energy && low.napRemaining < normal.napRemaining)
        var healthy = IronState(timeUntilNeed: 10)
        healthy.advance(by: 1000, available: false); precondition(healthy.timeUntilNeed == 10)
        print("PASS: two-minute grace, unavailable-clock freezing, persistent deficiency, screws-only recovery, feeding duration, increased low-iron fatigue")
    }
}
