import Foundation

/// Pointer intent is tracked independently of windows so a head rub never
/// accidentally becomes a move, and a missed latte drop never feeds her.
struct CompanionGesture {
    enum Target { case body, crown, latte, bar }
    enum Phase { case pressed, moving, petting, carryingLatte, carryingBar }
    enum Completion { case openNotes, poke, pet, moved, giveLatte, returnLatte, giveBar, returnBar }
    let target: Target
    let origin: CGPoint
    let began: Double
    private(set) var last: CGPoint
    private(set) var phase: Phase = .pressed

    init(target: Target, point: CGPoint, time: Double) {
        self.target = target; origin = point; last = point; began = time
    }
    @discardableResult mutating func update(point: CGPoint, time: Double, onCrown: Bool) -> Phase {
        last = point
        let distance = hypot(point.x - origin.x, point.y - origin.y)
        switch target {
        case .latte:
            if distance > 4 { phase = .carryingLatte }
        case .bar:
            if distance > 4 { phase = .carryingBar }
        case .body:
            if distance > 4 { phase = .moving }
        case .crown:
            // A head gesture stays a head gesture even if a stroke leaves the
            // moving silhouette. Move with the body or Option-drag instead.
            if distance >= 8 || time - began >= 0.35 { phase = .petting }
        }
        return phase
    }
    func finish(overCup: Bool = false, overHand: Bool = false, overBarHand: Bool = false) -> Completion {
        switch target {
        case .latte: return (phase == .carryingLatte ? overHand : overCup) ? .giveLatte : .returnLatte
        case .bar: return phase == .carryingBar && overBarHand ? .giveBar : .returnBar
        case .body: return phase == .moving ? .moved : .openNotes
        case .crown:
            if phase == .moving { return .moved }
            return phase == .petting ? .pet : .poke
        }
    }
}

struct AttitudeState {
    private var pokes: [Double] = []
    mutating func poke(at time: Double) -> Bool {
        pokes.removeAll { time - $0 > 3 || time < $0 }
        pokes.append(time)
        return pokes.count >= 4
    }
    mutating func pet() { pokes.removeAll() }
}
