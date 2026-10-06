import Foundation

@main struct StylingTests {
    static func main() throws {
        var style = StylingState(), poor = DanceProgress(completedClaps: 9, unlockedDanceIDs: ["ballet"])
        precondition(!style.buy(.tribalHeart, progress: &poor) && poor.clapBalance == 9)
        style.recordCare(.pet); style.recordCare(.pet); style.recordCare(.coffee)
        precondition(style.available.isEmpty)
        style.recordCare(.food)
        precondition(style.available == [.tribalHeart] && style.purchased.isEmpty && style.worn.isEmpty)
        precondition(!style.buy(.tribalHeart, progress: &poor) && poor.clapBalance == 9)
        poor.recordClap()
        precondition(style.buy(.tribalHeart, progress: &poor) && poor.clapBalance == 0 && poor.cosmeticClapsSpent == 10)
        precondition(!style.buy(.tribalHeart, progress: &poor) && poor.cosmeticClapsSpent == 10)
        precondition(style.toggle(.tribalHeart) && style.worn.isEmpty && poor.clapBalance == 0)
        precondition(style.toggle(.tribalHeart) && style.worn == [.tribalHeart])
        precondition(!style.toggle(.navelPiercing))
        var gift = DrawingGiftState(timeUntilGift: 0)
        for care: HappinessState.Care in [.pet, .food, .coffee] { gift.recordCare(care) }
        gift.advance(by: 120, available: true, happiness: 1)
        gift.advance(by: 10, available: true, happiness: 1)
        style.updateHistory(from: gift)
        precondition(!style.available.contains(.navelPiercing))
        _ = gift.accept(); style.updateHistory(from: gift)
        precondition(style.available.contains(.navelPiercing) && !style.purchased.contains(.navelPiercing))
        for _ in 0..<10 { poor.recordClap() }
        precondition(style.buy(.navelPiercing, progress: &poor) && poor.clapBalance == 0 && poor.cosmeticClapsSpent == 20)
        style.updateProgress(from: DanceProgress(completedClaps: 2))
        precondition(!style.available.contains(.legWarmers))
        style.updateProgress(from: poor)
        precondition(style.available.contains(.legWarmers) && !style.purchased.contains(.legWarmers))
        for _ in 0..<10 { poor.recordClap() }
        precondition(style.buy(.legWarmers, progress: &poor) && poor.clapBalance == 0 && poor.cosmeticClapsSpent == 30 && style.imageKey == 7)
        precondition(style.toggle(.legWarmers) && style.imageKey == 3 && poor.clapBalance == 0)
        precondition(style.toggle(.legWarmers) && style.imageKey == 7)
        style.recordCare(.attention)
        precondition(style.available.contains(.heartCharm) && !style.purchased.contains(.heartCharm))
        for _ in 0..<10 { poor.recordClap() }
        precondition(style.buy(.heartCharm, progress: &poor) && poor.clapBalance == 0 && poor.cosmeticClapsSpent == 40 && style.imageKey == 15)
        let future = try JSONDecoder().decode(StylingState.self, from: Data(#"{"available":["legWarmers","futureHat"],"purchased":["legWarmers","futureHat"],"worn":["legWarmers","futureHat"]}"#.utf8))
        precondition(future.purchased == [.legWarmers] && future.worn == [.legWarmers])
        let encoder = JSONEncoder(), decoder = JSONDecoder()
        let saved = try decoder.decode(StylingState.self, from: encoder.encode(style))
        let balance = try decoder.decode(DanceProgress.self, from: encoder.encode(poor))
        precondition(saved == style && balance == poor)
        let legacy = try decoder.decode(DanceProgress.self, from: Data(#"{"completedClaps":15,"unlockedDanceIDs":["ballet"],"careClapsSpent":1}"#.utf8))
        precondition(legacy.cosmeticClapsSpent == 0 && legacy.clapBalance == 14)
        var noAffection = StylingState()
        for care: HappinessState.Care in [.food, .coffee, .iron] { noAffection.recordCare(care) }
        precondition(noAffection.available.isEmpty)
        print("PASS: experience unlocks purchase only, exact 10-clap price, insufficient funds, no duplicate spending, free toggles and persistent ownership/balance")
    }
}
