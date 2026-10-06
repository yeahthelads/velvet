import Foundation

enum Cosmetic: String, Codable, CaseIterable {
    case tribalHeart, navelPiercing, legWarmers, heartCharm
    var title: String {
        switch self {
        case .tribalHeart: return "Tribal heart tattoo"
        case .navelPiercing: return "Navel piercing"
        case .legWarmers: return "Leg warmers"
        case .heartCharm: return "Heart charm"
        }
    }
    var price: Int { 10 }
    var requirement: String {
        switch self {
        case .tribalHeart: return "after varied care, including affection"
        case .navelPiercing: return "after accepting her drawing"
        case .legWarmers: return "after earning three claps"
        case .heartCharm: return "after affection and answering her attention bid"
        }
    }
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
        available = Array(Set((try c.decodeIfPresent([String].self, forKey: .available) ?? []).compactMap(Cosmetic.init(rawValue:)))).sorted { $0.rawValue < $1.rawValue }
        purchased = Array(Set((try c.decodeIfPresent([String].self, forKey: .purchased) ?? []).compactMap(Cosmetic.init(rawValue:)))).filter { available.contains($0) }.sorted { $0.rawValue < $1.rawValue }
        worn = Array(Set((try c.decodeIfPresent([String].self, forKey: .worn) ?? []).compactMap(Cosmetic.init(rawValue:)))).filter { purchased.contains($0) }.sorted { $0.rawValue < $1.rawValue }
    }
    mutating func recordCare(_ kind: HappinessState.Care) {
        if !careKinds.contains(kind.rawValue) { careKinds.append(kind.rawValue); careKinds.sort() }
        if careKinds.contains(HappinessState.Care.pet.rawValue) && careKinds.contains(HappinessState.Care.attention.rawValue) { unlock(.heartCharm) }
        if careKinds.count >= 3 && careKinds.contains(HappinessState.Care.pet.rawValue) { unlock(.tribalHeart) }
    }
    mutating func updateHistory(from drawings: DrawingGiftState) {
        for key in drawings.careKinds { if let care = HappinessState.Care(rawValue: key) { recordCare(care) } }
        if !drawings.received.isEmpty { unlock(.navelPiercing) }
    }
    mutating func updateProgress(from progress: DanceProgress) {
        if progress.completedClaps >= 3 { unlock(.legWarmers) }
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
    var imageKey: Int { (worn.contains(.tribalHeart) ? 1 : 0) | (worn.contains(.navelPiercing) ? 2 : 0) | (worn.contains(.legWarmers) ? 4 : 0) | (worn.contains(.heartCharm) ? 8 : 0) }
}
