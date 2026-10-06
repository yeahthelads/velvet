import Foundation

enum Cosmetic: String, Codable, CaseIterable {
    case tribalHeart, navelPiercing
    var title: String { self == .tribalHeart ? "Tribal heart tattoo" : "Navel piercing" }
    var price: Int { 10 }
    var requirement: String { self == .tribalHeart ? "after varied care, including affection" : "after accepting her drawing" }
}

/// Experiences unlock the shop; purchases spend the same claps as dances and care.
struct StylingState: Codable, Equatable {
    private(set) var careKinds: [String] = []
    private(set) var available: [Cosmetic] = []
    private(set) var purchased: [Cosmetic] = []
    private(set) var worn: [Cosmetic] = []
    init() {}
    private enum CodingKeys: String, CodingKey { case careKinds, available, purchased, worn }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        careKinds = Array(Set((try c.decodeIfPresent([String].self, forKey: .careKinds) ?? []).filter { HappinessState.Care(rawValue: $0) != nil })).sorted()
        available = Array(Set(try c.decodeIfPresent([Cosmetic].self, forKey: .available) ?? [])).sorted { $0.rawValue < $1.rawValue }
        purchased = Array(Set(try c.decodeIfPresent([Cosmetic].self, forKey: .purchased) ?? [])).filter { available.contains($0) }.sorted { $0.rawValue < $1.rawValue }
        worn = Array(Set(try c.decodeIfPresent([Cosmetic].self, forKey: .worn) ?? [])).filter { purchased.contains($0) }.sorted { $0.rawValue < $1.rawValue }
    }
    mutating func recordCare(_ kind: HappinessState.Care) {
        if !careKinds.contains(kind.rawValue) { careKinds.append(kind.rawValue); careKinds.sort() }
        if careKinds.count >= 3 && careKinds.contains(HappinessState.Care.pet.rawValue) { unlock(.tribalHeart) }
    }
    mutating func updateHistory(from drawings: DrawingGiftState) {
        for key in drawings.careKinds { if let care = HappinessState.Care(rawValue: key) { recordCare(care) } }
        if !drawings.received.isEmpty { unlock(.navelPiercing) }
    }
    private mutating func unlock(_ item: Cosmetic) {
        if !available.contains(item) { available.append(item); available.sort { $0.rawValue < $1.rawValue } }
    }
    @discardableResult mutating func buy(_ item: Cosmetic, progress: inout DanceProgress) -> Bool {
        guard available.contains(item), !purchased.contains(item), progress.payForCosmetic(cost: item.price) else { return false }
        purchased.append(item); purchased.sort { $0.rawValue < $1.rawValue }
        worn.append(item); worn.sort { $0.rawValue < $1.rawValue }
        return true
    }
    @discardableResult mutating func toggle(_ item: Cosmetic) -> Bool {
        guard purchased.contains(item) else { return false }
        if worn.contains(item) { worn.removeAll { $0 == item } }
        else { worn.append(item); worn.sort { $0.rawValue < $1.rawValue } }
        return true
    }
    var imageKey: Int { (worn.contains(.tribalHeart) ? 1 : 0) | (worn.contains(.navelPiercing) ? 2 : 0) }
}
