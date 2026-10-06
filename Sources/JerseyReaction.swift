import Foundation

enum JerseyReaction: String, CaseIterable {
    case laugh, shy, attitude, pleased
}

/// One shared cooldown keeps different gestures from farming a chorus of clips.
struct JerseyCadence {
    static let cooldown = 45.0
    private(set) var lastPlayed: Double?
    mutating func accept(now: Double, chance: Double, roll: Double) -> Bool {
        guard now.isFinite, chance > 0, roll >= 0, roll < min(1, chance),
            lastPlayed.map({ now - $0 >= Self.cooldown }) ?? true else { return false }
        lastPlayed = now
        return true
    }
}
