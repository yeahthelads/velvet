import Foundation

struct CoffeeState: Codable, Equatable {
    static let patience: TimeInterval = 15 * 60
    var awakeSeconds: TimeInterval = 0
    var coffeesGiven = 0
    var needsCoffee: Bool { awakeSeconds >= Self.patience }

    mutating func advance(by seconds: TimeInterval) {
        guard seconds.isFinite, seconds > 0 else { return }
        awakeSeconds = min(Self.patience, awakeSeconds + seconds)
    }
    mutating func makeGrumpy() { awakeSeconds = Self.patience }
    mutating func giveCoffee() {
        awakeSeconds = 0
        coffeesGiven += 1
    }
}
