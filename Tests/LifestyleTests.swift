import Foundation

@main enum LifestyleTests {
    static func main() throws {
        var state = LifestyleState()
        state.foodRemaining = 5; state.attentionRemaining = 800; state.phoneRemaining = 1000
        let frozen = state
        state.advance(by: 100, available: false, awake: true, free: true)
        precondition(state == frozen, "Hidden and paused time cannot accrue needs")
        state.advance(by: .nan, available: true, awake: true, free: true)
        state.advance(by: -1, available: true, awake: true, free: true)
        precondition(state == frozen)
        state.advance(by: 5, available: true, awake: true, free: false)
        precondition(state.hungry && !state.readyToDance)
        precondition(state.feed() && !state.feed(), "One snack resolves one food need")
        precondition(!state.readyToDance && state.phase == .snack)
        state.advance(by: 6, available: true, awake: true, free: true)
        precondition(state.phase == .idle && state.readyToDance)
        state.phoneRemaining = 0
        state.advance(by: 1, available: true, awake: true, free: true)
        precondition(state.phase == .phone && !state.readyToDance)
        precondition(state.disturbPhone() && !state.disturbPhone(), "Only the first interruption starts the sulk")
        state.advance(by: 15, available: true, awake: true, free: true)
        let sulk = state
        precondition(state.ignoring && state.remaining == 30)
        precondition(!state.feed() && !state.acknowledge() && !state.wake() && !state.disturbPhone())
        precondition(state == sulk, "Care cannot shorten or extend her cold shoulder")
        let saved = try JSONDecoder().decode(LifestyleState.self, from: JSONEncoder().encode(state))
        precondition(saved == state, "Restart preserves the remaining cold shoulder")
        state.advance(by: 30, available: true, awake: true, free: true)
        precondition(!state.ignoring && state.phase == .idle)
        state.attentionRemaining = 0
        state.advance(by: 1, available: true, awake: true, free: true)
        precondition(state.phase == .attention && !state.readyToDance)
        state.advance(by: 40, available: true, awake: true, free: true)
        precondition(state.needsAttention && !state.readyToDance, "A missed request cannot count as care")
        precondition(state.acknowledge() && state.readyToDance)
        state.energy = 25
        state.advance(by: 1, available: true, awake: true, free: true)
        precondition(state.phase == .yawning)
        state.advance(by: 4, available: true, awake: true, free: true)
        precondition(state.phase == .nap && !state.readyToDance)
        let sleepingEnergy = state.energy
        state.advance(by: state.remaining, available: true, awake: true, free: true)
        precondition(state.phase == .waking && state.energy > sleepingEnergy)
        state.advance(by: 4.2, available: true, awake: true, free: true)
        precondition(state.phase == .idle && state.readyToDance)
        let energy = state.energy
        precondition(state.startDance() && state.energy == energy - LifestyleState.danceEnergyCost)
        state.finishDance()
        precondition(state.energy == energy - LifestyleState.danceEnergyCost && LifestyleState.danceInterval.contains(state.danceRemaining), "Finishing must not charge twice")
        let food = state.foodRemaining, nap = state.napRemaining
        state.advance(by: 30, available: true, awake: false, free: false, focusNap: true)
        precondition(state.energy > energy - LifestyleState.danceEnergyCost && state.foodRemaining == food && state.napRemaining == nap)
        let dance = state.danceRemaining
        precondition(!state.advanceDance(by: 2000, available: false) && state.danceRemaining == dance)
        precondition(state.advanceDance(by: dance, available: true))
        var spam = LifestyleState()
        for _ in 0..<4 { precondition(spam.startDance()) }
        let exhausted = spam
        precondition(spam.energy == 20 && !spam.startDance() && spam == exhausted, "Starts alone exhaust her, even without finishing")
        let tiredSaved = try JSONDecoder().decode(LifestyleState.self, from: JSONEncoder().encode(spam))
        precondition(!tiredSaved.readyToDance && tiredSaved.energy == 20, "Restart cannot erase fatigue")
        spam.advance(by: 1, available: true, awake: true, free: true)
        precondition(spam.phase == .yawning)
        spam.advance(by: 4, available: true, awake: true, free: true)
        spam.advance(by: spam.remaining, available: true, awake: true, free: true)
        spam.advance(by: 4.2, available: true, awake: true, free: true)
        precondition(spam.readyToDance && spam.startDance(), "A completed nap permits dancing again")
        var lockRest = LifestyleState(); lockRest.energy = 20
        let foodBeforeLock = lockRest.foodRemaining, attentionBeforeLock = lockRest.attentionRemaining
        lockRest.restWhileLocked(by: 120)
        precondition(lockRest.energy == 50 && lockRest.foodRemaining == foodBeforeLock && lockRest.attentionRemaining == attentionBeforeLock)
        lockRest.restWhileLocked(by: 600)
        precondition(lockRest.energy == 100)
        lockRest.danceRemaining = 1
        precondition(!lockRest.advanceDance(by: 2, available: true, canStart: false) && lockRest.danceRemaining == 0)
        precondition(lockRest.advanceDance(by: 1, available: true), "A due spontaneous dance is retained until its rest ends")

        var lesson = TutorialState(), progress = DanceProgress()
        precondition(!progress.allows("ballet") && !lesson.petted())
        lesson.closedNote(); lesson.fed(); lesson.finishedSnack()
        precondition(lesson.step == .welcome, "Tutorial steps cannot be skipped with unrelated actions")
        lesson.continueDialogue(); lesson.continueDialogue(); precondition(lesson.step == .openNote, "Continue cannot skip a requested action")
        lesson.openedNote(); lesson.closedNote(); lesson.fed()
        let resumed = try JSONDecoder().decode(TutorialState.self, from: JSONEncoder().encode(lesson))
        precondition(resumed.step == .snacking && !resumed.complete)
        lesson.finishedSnack(); precondition(lesson.petted() && !lesson.petted())
        precondition(lesson.step == .balletUnlocked && !lesson.complete)
        lesson.continueDialogue(); precondition(lesson.complete)
        progress.earnTutorialBallet(); progress.earnTutorialBallet()
        precondition(progress.unlockedDanceIDs == ["ballet"] && progress.clapBalance == 0)
        for _ in 0..<3 { progress.recordClap() }
        precondition(progress.unlock("contemporary") && progress.clapBalance == 0)
        progress.recordClap(); precondition(progress.payForReplay("contemporary") && progress.refundReplay())
        precondition(progress.clapBalance == 1 && !progress.refundReplay())
        var lost = DanceProgress(completedClaps: 3, unlockedDanceIDs: ["ballet", "house"])
        precondition(lost.revokeDance("house") && !lost.revokeDance("ballet") && !lost.allows("house") && lost.clapBalance == 0)
        let lostAgain = try JSONDecoder().decode(DanceProgress.self, from: JSONEncoder().encode(lost))
        precondition(lostAgain == lost && lostAgain.clapBalance == 0)
        for _ in 0..<3 { lost.recordClap() }
        precondition(lost.unlock("house") && lost.clapBalance == 0)
        print("PASS: eligible clocks, food, phone privacy, persistent sulk, attention, naps/waking, energy, dance cadence, focus rest, resumable tutorial, Ballet reward, Contemporary economy and refund")
    }
}
