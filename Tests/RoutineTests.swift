import Foundation

@main struct RoutineTests {
    static func main() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        func date(_ day: Int, _ hour: Int, _ minute: Int = 0, month: Int = 10) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
        }
        precondition(DailyRoutine.period(at: date(3, 21, 59), calendar: calendar) == .awake)
        precondition(DailyRoutine.period(at: date(3, 22), calendar: calendar) == .windingDown)
        precondition(DailyRoutine.period(at: date(3, 23), calendar: calendar) == .asleep)
        precondition(DailyRoutine.period(at: date(4, 7, 59), calendar: calendar) == .asleep)
        precondition(DailyRoutine.period(at: date(4, 8), calendar: calendar) == .awake)
        var night = DailyRoutine()
        precondition(night.update(at: date(24, 23), calendar: calendar, bellyChoice: true) && night.bellySleep)
        precondition(!night.update(at: date(25, 3), calendar: calendar, bellyChoice: false) && night.bellySleep, "DST and midnight must keep the same night pose")
        var restored = try JSONDecoder().decode(DailyRoutine.self, from: JSONEncoder().encode(night))
        restored.update(at: date(25, 7), calendar: calendar, bellyChoice: false)
        precondition(restored.period == .asleep && restored.bellySleep)
        restored.update(at: date(25, 8), calendar: calendar)
        precondition(restored.period == .awake)
        restored.update(at: date(25, 23), calendar: calendar, bellyChoice: false)
        precondition(!restored.bellySleep)
        var activity = ActivityState(); let initial = activity.level
        activity.advance(by: 3600, available: false)
        precondition(activity.level == initial)
        activity.advance(by: 3600, available: true)
        precondition(activity.withdrawn && activity.automaticDanceRate == 0)
        precondition(activity.interact(.hover, at: 10))
        let hovered = activity.level
        precondition(!activity.interact(.hover, at: 20) && activity.level == hovered)
        precondition(activity.interact(.pet, at: 20) && activity.interact(.move, at: 20))
        precondition(activity.automaticDanceRate > 0)
        activity.missedAttention(); activity.missedAttention()
        precondition(activity.withdrawn && activity.automaticDanceRate == 0)
        activity.interact(.attention, at: 40); activity.interact(.pet, at: 40)
        precondition(!activity.withdrawn && activity.missedBids == 0)
        let saved = try JSONDecoder().decode(ActivityState.self, from: JSONEncoder().encode(activity))
        precondition(saved.level == activity.level && saved.missedBids == activity.missedBids)
        var bar = CompanionGesture(target: .bar, point: CGPoint(x: 0, y: 0), time: 0)
        precondition(bar.finish(overBarHand: true) == .returnBar, "A tap is not a handoff")
        bar.update(point: CGPoint(x: 20, y: 10), time: 0.2, onCrown: false)
        precondition(bar.phase == .carryingBar && bar.finish(overBarHand: false) == .returnBar)
        precondition(bar.finish(overBarHand: true) == .giveBar)
        print("PASS: local-time boundaries, midnight/DST/restart, stable sleep choice, activity decay/throttling/reconciliation, bar tap/miss/handoff")
    }
}
