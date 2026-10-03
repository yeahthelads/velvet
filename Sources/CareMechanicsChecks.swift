import AppKit

extension AppDelegate {
    /// Uses temporary notes, actual care callbacks, and simulated OS notifications.
    func checkCareMechanics() -> [String: Bool] {
        var checks: [String: Bool] = [:]
        func rested() {
            character.audio.enabled = false; character.returnToBed()
            screenLockActive = false; sessionInactive = false; updateScreenRest()
            dismissTutorial(); closeNotes(); store.focus.end(); updateFocusRest()
            dailyRoutine = DailyRoutine(); character.applyDailyRoutine(dailyRoutine)
            character.awaitingSong = false; character.paused = false; character.listensToAudio = false
            character.care = CompanionCare(); character.lifestyle = LifestyleState()
            character.activity = ActivityState(); character.happiness = HappinessState()
            character.stimulation = StimulationState(cooldown: 60); character.wantsCoffee = false
            character.danceProgress = DanceProgress(completedClaps: 1000, unlockedDanceIDs: DanceProgress.danceIDs)
            character.react(.idle); character.mood = .idle; character.moodUntil = .distantPast
        }
        rested()
        let head = NSPoint(x: character.crownRect.midX, y: character.crownRect.minY + character.crownRect.height * 0.3)
        let now = ProcessInfo.processInfo.systemUptime, initial = character.happiness.level
        character.beginPointer(at: head, screenPoint: head, time: now)
        character.endPointer(at: head, time: now + 0.4)
        checks["realHeadHoldBuildsHappiness"] = character.happiness.level > initial && character.happiness.careDanceDelay != nil && character.mood == .affection
        let petted = character.happiness.level
        character.rubCrown()
        checks["repeatedHeadRubsDoNotStackHappiness"] = character.happiness.level == petted
        character.moodUntil = .distantPast; character.react(.idle)
        let claps = character.danceProgress.clapBalance
        character.advanceLifestyle(by: 20)
        checks["careStartsAnUnlockedSpontaneousDance"] = character.mood.isChoreography && Mood.automaticDances.contains(character.mood) && character.danceProgress.allows(character.mood.rawValue)
        checks["careDanceCostsEnergyButNoClapsOrMusic"] = character.lifestyle.energy < 81 && character.danceProgress.clapBalance == claps && !character.audio.isAnyDancePlaying
        checks["careDanceClearsItsPendingRewardAndRests"] = character.happiness.careDanceDelay == nil && character.happiness.danceRestRemaining == 120
        character.react(.idle); character.advanceLifestyle(by: 30)
        checks["careCannotCauseBackToBackAutomaticDances"] = !character.mood.isChoreography
        rested(); giveCoffee()
        let latteHappy = character.happiness.level
        checks["actualLatteBuildsHappiness"] = character.mood == .coffee && latteHappy > initial
        character.moodUntil = .distantPast; character.react(.idle); giveCoffee()
        checks["extraLatteDoesNotStackHappiness"] = character.happiness.level == latteHappy
        rested(); character.lifestyle.foodRemaining = 0
        character.mood = .hungry; character.syncCompanionButtons()
        let bar = NSPoint(x: character.snackButtonRect.midX, y: character.snackButtonRect.midY)
        let hand = NSPoint(x: character.barHandRect.midX, y: character.barHandRect.midY)
        let petOrigin = pet.frame.origin
        character.beginPointer(at: bar, screenPoint: bar, time: now + 2)
        character.endPointer(at: bar, time: now + 2.1)
        checks["proteinBarTapDoesNotFeedOrOpenNotes"] = character.lifestyle.hungry && !notes.isVisible && character.happiness.level == initial
        character.beginPointer(at: bar, screenPoint: bar, time: now + 3)
        character.updatePointer(at: hand, screenPoint: hand, time: now + 3.2)
        checks["draggingProteinBarMakesHerReachWithoutMovingWindow"] = character.displayedSpriteIndex == 101 && pet.frame.origin == petOrigin
        character.endPointer(at: hand, time: now + 3.3)
        checks["realFoodDropBuildsHappinessAndStartsEating"] = character.mood == .snack && character.displayedSpriteIndex == 102 && character.happiness.level > initial
        let fed = character.happiness.level
        checks["extraFoodCannotStackHappiness"] = !character.giveProteinBar() && character.happiness.level == fed
        rested(); character.lifestyle.attentionRemaining = 0; character.advanceLifestyle(by: 1)
        checks["answeringAttentionBuildsHappiness"] = character.acknowledgeAttention() && character.happiness.level > initial
        rested(); character.rubCrown(); character.moodUntil = .distantPast; character.react(.idle)
        openNotes(); character.advanceLifestyle(by: 20)
        checks["happinessDoesNotBypassOpenNotes"] = !character.mood.isDance && character.happiness.careDanceDelay != nil
        closeNotes(); character.moodUntil = .distantPast; character.react(.idle)
        character.lifestyle.energy = 25; character.advanceLifestyle(by: 20)
        checks["happinessDoesNotBypassTiredness"] = !character.mood.isDance && !character.canChooseDance

        rested(); openNotes(); store.focus.start(seconds: 60); updateFocusRest()
        character.lifestyle.energy = 25
        let lifeBefore = character.lifestyle, happinessBefore = character.happiness, focusBefore = store.focus.remaining
        let progressBefore = character.danceProgress
        screenDidLock()
        checks["screenLockDisplaysSleepAndStopsAnimationClock"] = character.screenLocked && character.mood == .nightSleep && !character.animationClockRunning
        checks["screenLockBlocksCareAndNotes"] = !character.canInteract && !character.canGiveNotes && !character.canChooseDance && !notes.isVisible
        advanceActivity(by: 1000); character.advanceLifestyle(by: 1000); character.advanceNightVisit(by: 1000)
        checks["screenLockFreezesNeedsHappinessFocusAndRewards"] = character.lifestyle == lifeBefore && character.happiness == happinessBefore && store.focus.remaining == focusBefore && character.danceProgress == progressBefore
        let lockedAt = screenRestBegan
        screenDidLock()
        checks["duplicateScreenLockDoesNotRestartRest"] = screenRestBegan == lockedAt
        sessionDidResign(); screenDidUnlock()
        checks["inactiveSessionStillRestsAfterUnlockNotification"] = character.screenLocked
        screenRestBegan = Date().addingTimeInterval(-120); sessionDidBecomeActive()
        checks["screenUnlockRecoversEnergyWithoutAdvancingNeeds"] = !character.screenLocked && character.lifestyle.energy >= 55 && character.lifestyle.foodRemaining == lifeBefore.foodRemaining && character.lifestyle.attentionRemaining == lifeBefore.attentionRemaining
        checks["unlockResumesClocksWithoutFocusCatchUp"] = character.animationClockRunning && store.focus.remaining == focusBefore
        checks["unlockRestoresPreviouslyVisibleNotes"] = notes.isVisible && character.noteIsVisible

        rested()
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        func date(_ hour: Int) -> Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: 3, hour: hour))! }
        character.lifestyle.energy = 23
        updateDailyRoutine(at: date(23), calendar: calendar, bellyChoice: true)
        let sleepyEnergy = character.lifestyle.energy
        let nightHead = NSPoint(x: character.crownRect.midX, y: character.crownRect.midY)
        character.beginPointer(at: nightHead, screenPoint: nightHead, time: now + 10)
        character.endPointer(at: nightHead, time: now + 10.1)
        checks["bedtimeTapWakesForBriefCuddleWithoutOpeningNotes"] = character.isNightVisit && character.mood == .wakeUp && !notes.isVisible && character.lifestyle.energy == sleepyEnergy
        checks["nightVisitExplainsReturningToBedInSmallBubble"] = sleepyPanel?.isVisible == true && sleepyPanel?.frame.width == 216 && (sleepyPanel?.frame.height ?? 1000) < 150 && sleepyBubble?.primaryButton.title == "Back to bed"
        let nightHappy = character.happiness
        character.rubCrown()
        checks["sleepyCuddleIsAffectionWithoutMorningEnergyOrDanceBoost"] = character.mood == .affection && character.happiness == nightHappy && character.lifestyle.energy == sleepyEnergy
        character.chooseDance(.ballet); character.react(.house)
        checks["nightCuddleCannotStartDancesOrSongRequests"] = !character.mood.isDance && !character.canChooseDance && !canRequestSong(spotifySupported: true, metadataAvailable: true)
        let nightNeeds = character.lifestyle
        character.advanceLifestyle(by: 1000); advanceActivity(by: 1000)
        checks["nightVisitDoesNotAccrueDaytimeNeeds"] = character.lifestyle == nightNeeds
        character.advanceNightVisit(by: 29); character.rubCrown()
        checks["morePettingDoesNotExtendNightVisit"] = character.nightVisit.remaining == 1
        character.advanceNightVisit(by: 1)
        checks["nightVisitReturnsToOriginalBellySleep"] = !character.isNightVisit && character.mood == .bellySleep && sleepyPanel?.isVisible == false && character.lifestyle.energy == sleepyEnergy
        _ = character.wakeForNightVisit(); sleepyBubble?.primaryButton.performClick(nil)
        checks["backToBedButtonEndsVisit"] = !character.isNightVisit && character.mood == .bellySleep
        screenDidLock()
        checks["lockedScreenCannotWakeNightVisitor"] = !character.wakeForNightVisit()
        screenDidUnlock()
        checks["nightUnlockKeepsHerInBed"] = character.mood == .bellySleep && !character.isNightVisit
        updateDailyRoutine(at: date(8), calendar: calendar)
        checks["morningStillRestoresEnergyAndProperWakeUp"] = character.lifestyle.energy == 100 && character.mood == .wakeUp && !character.isNightVisit

        rested(); let noteID = store.create(); store.update(noteID, title: "Reset fixture", body: "Preserve this note")
        store.setDanceProgress(character.danceProgress); store.setHappiness(character.happiness); store.flush()
        let originalNotes = store.archive.notes
        checks["safeResetCompletes"] = store.resetCompanion()
        let fresh = NoteStore(directory: store.directory)
        checks["safeResetPreservesNotes"] = fresh.archive.notes == originalNotes
        checks["safeResetStartsFreshTutorialAndDanceEconomy"] = fresh.tutorial.step == .welcome && fresh.danceProgress.unlockedDanceIDs.isEmpty && fresh.danceProgress.clapBalance == 0 && fresh.preferences.hasMetVelvet == false && !fresh.preferences.paused
        checks["safeResetClearsCareSongHappinessAndFatigue"] = fresh.happiness == HappinessState() && fresh.lifestyle.energy == 100 && !fresh.coffee.needsCoffee && !fresh.care.needsAffection && !fresh.songRequest.waiting
        checks["safeResetKeepsRecoverableBackup"] = (try? FileManager.default.contentsOfDirectory(at: store.directory, includingPropertiesForKeys: nil).contains { $0.lastPathComponent.hasPrefix("before-companion-reset-") }) == true
        return checks
    }
}
