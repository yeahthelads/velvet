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

/// Three unnecessary lattes within five eligible minutes bring a short rush
/// followed by a long quiet crash. Persisting it prevents a restart escape.
struct CoffeeOverload: Codable, Equatable {
    enum Phase: String, Codable { case idle, sipping, hyped, crashed }
    private(set) var phase = Phase.idle
    private(set) var remaining = 0.0
    private(set) var extraCoffees = 0
    private(set) var windowRemaining = 0.0
    var occupied: Bool { phase != .idle }
    var crashed: Bool { phase == .crashed }
    @discardableResult mutating func accepted(needed: Bool) -> Bool {
        guard !occupied else { return false }
        if needed { extraCoffees = 0; windowRemaining = 0; return false }
        if windowRemaining == 0 { extraCoffees = 0; windowRemaining = 300 }
        extraCoffees += 1
        guard extraCoffees >= 3 else { return false }
        phase = .sipping; remaining = 6; extraCoffees = 0; windowRemaining = 0
        return true
    }
    mutating func advance(by seconds: Double, available: Bool) {
        guard available, seconds.isFinite, seconds > 0 else { return }
        if phase == .idle {
            windowRemaining = max(0, windowRemaining - seconds)
            if windowRemaining == 0 { extraCoffees = 0 }; return
        }
        var elapsed = seconds
        while phase != .idle && elapsed >= remaining {
            elapsed -= remaining
            switch phase {
            case .sipping: phase = .hyped; remaining = 8
            case .hyped: phase = .crashed; remaining = 180
            case .crashed: phase = .idle; remaining = 0
            case .idle: break
            }
        }
        if phase != .idle { remaining -= elapsed }
    }
}
