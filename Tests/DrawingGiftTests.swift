import Foundation

@main struct DrawingGiftTests {
    static func main() throws {
        var gift = DrawingGiftState(timeUntilGift: 0)
        gift.recordCare(.pet); gift.recordCare(.pet); gift.recordCare(.coffee)
        gift.advance(by: 1000, available: true, happiness: 1)
        precondition(gift.phase == .idle && gift.careKinds.count == 2)
        gift.recordCare(.food)
        gift.advance(by: 1, available: true, happiness: 0.2)
        gift.advance(by: 119, available: true, happiness: 1)
        precondition(gift.phase == .idle)
        gift.advance(by: 1000, available: false, happiness: 1)
        precondition(gift.phase == .idle && gift.happySeconds == 119)
        gift.advance(by: 1, available: true, happiness: 1)
        precondition(gift.phase == .drawing && gift.accept() == nil)
        gift.advance(by: 4, available: true, happiness: 1)
        let encoder = JSONEncoder(), decoder = JSONDecoder()
        var restored = try decoder.decode(DrawingGiftState.self, from: encoder.encode(gift))
        precondition(restored == gift && restored.remaining == 6)
        restored.advance(by: 20, available: false, happiness: 1)
        precondition(restored.remaining == 6)
        restored.advance(by: 6, available: true, happiness: 1)
        precondition(restored.phase == .offering)
        restored.advance(by: 6, available: true, happiness: 1)
        precondition(restored.phase == .waiting)
        restored.advance(by: 999999, available: true, happiness: 0)
        precondition(restored.phase == .waiting && restored.hasUnclaimed)
        let accepted = restored.accept(at: Date(timeIntervalSince1970: 100))!
        precondition(accepted.id == DrawingKeepsake.robotsID && restored.received == [accepted])
        precondition(restored.accept() == nil && !restored.hasUnclaimed)
        for care in HappinessState.Care.allCases { restored.recordCare(care) }
        restored.advance(by: 999999, available: true, happiness: 1)
        precondition(restored.phase == .idle && restored.received.count == 1)
        let saved = try decoder.decode(DrawingGiftState.self, from: encoder.encode(restored))
        precondition(saved == restored)
        let defaults = try decoder.decode(DrawingGiftState.self, from: Data("{}".utf8))
        precondition(defaults.phase == .idle && defaults.received.isEmpty)
        var noPet = DrawingGiftState(timeUntilGift: 0)
        for care: HappinessState.Care in [.food, .coffee, .iron] { noPet.recordCare(care) }
        noPet.advance(by: 1000, available: true, happiness: 1)
        precondition(noPet.phase == .idle)
        print("PASS: meaningful care, happy streak, suspended clocks, mid-drawing restart, unclaimed gift persistence and one unique keepsake")
    }
}
