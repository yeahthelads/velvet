import AppKit

extension AppDelegate {
    /// Isolated native checks use the same UI callbacks as the real tutorial.
    func checkLifestyle(previewDirectory: URL) -> [String: Any] {
        var checks: [String: Any] = [:]
        character.audio.enabled = false
        character.lifestyle = LifestyleState(); character.care = CompanionCare()
        character.wantsCoffee = false; character.stimulation = StimulationState(cooldown: 60)
        character.danceProgress = DanceProgress(); store.setTutorial(TutorialState())
        closeNotes(); character.mood = .idle; character.moodUntil = .distantPast
        showTutorial()
        checks["tutorialStartsWithSmallSpeechBubble"] = tutorialPanel?.frame.width == 216 && (tutorialPanel?.frame.height ?? 1000) < 130 && tutorialBubble?.dialogue == store.tutorial.text
        let headFrame = pet.convertToScreen(character.convert(character.crownRect, to: nil))
        checks["speechTailTouchesCharacterNotWindowPadding"] = abs((tutorialPanel?.frame.minY ?? 0) - headFrame.maxY - 4) < 1
        if let bubble = tutorialBubble, let bitmap = bubble.bitmapImageRepForCachingDisplay(in: bubble.bounds) {
            bubble.cacheDisplay(in: bubble.bounds, to: bitmap)
            try? bitmap.representation(using: .png, properties: [:])?.write(to: previewDirectory.appendingPathComponent("tutorial-bubble.png"))
        }
        let originalPosition = pet.frame.origin
        if let screen = pet.screen {
            pet.setFrameOrigin(NSPoint(x: screen.visibleFrame.minX, y: screen.visibleFrame.maxY - pet.frame.height))
            anchorTutorial()
            checks["bubbleFitsAtTopLeftAndPointsUp"] = tutorialBubble?.tailAtTop == true && screen.visibleFrame.contains(tutorialPanel!.frame)
            pet.setFrameOrigin(originalPosition); anchorTutorial()
            checks["bubbleFollowsCharacterMovement"] = tutorialBubble?.tailAtTop == false && abs(tutorialPanel!.frame.minY - headFrame.maxY - 4) < 1
        }
        tutorialBubble?.primaryButton.performClick(nil)
        checks["tutorialShowsRealFirstInteraction"] = tutorialPanel?.isVisible == true && character.tutorialActive && store.tutorial.step == .openNote
        character.react(.ballet); character.chooseDance(.house)
        checks["tutorialDoesNotPerformLockedDance"] = !character.mood.isDance && character.availableDances.isEmpty
        let before = character.lifestyle
        character.advanceLifestyle(by: 900); advanceActivity(by: 900)
        checks["tutorialFreezesNeeds"] = character.lifestyle == before && !coffee.needsCoffee
        openNotes()
        checks["tutorialLeavesNoteAndHeadUncovered"] = tutorialPanel?.frame.intersects(notes.frame) == false && tutorialPanel?.frame.intersects(headFrame) == false
        checks["tutorialRemainsBoundedAfterStepChange"] = tutorialPanel?.frame.width == 216 && tutorialPanel?.contentView?.frame.size == tutorialPanel?.frame.size && (tutorialPanel?.frame.height ?? 1000) < 130
        checks["realNoteAdvancesTutorial"] = notes.isVisible && store.tutorial.step == .closeNote
        closeNotes(); checks["closingNoteOffersProtein"] = store.tutorial.step == .snack && character.mood == .hungry
        let bar = NSPoint(x: character.snackButtonRect.midX, y: character.snackButtonRect.midY)
        checks["proteinHasClickableHitbox"] = character.interactiveArea(bar) && character.hitTest(bar) != nil
        let clickTime = ProcessInfo.processInfo.systemUptime
        character.beginPointer(at: bar, screenPoint: bar, time: clickTime)
        let hand = NSPoint(x: character.barHandRect.midX, y: character.barHandRect.midY)
        character.updatePointer(at: hand, screenPoint: hand, time: clickTime + 0.2)
        character.endPointer(at: hand, time: clickTime + 0.3)
        checks["feedingShowsGrippedBar"] = store.tutorial.step == .snacking && character.mood == .snack && character.displayedSpriteIndex == 102 && !notes.isVisible
        character.advanceLifestyle(by: 2)
        checks["snackRaisesBarForBite"] = character.displayedSpriteIndex == 87
        character.advanceLifestyle(by: 4)
        checks["finishedSnackAsksForHeadStroke"] = store.tutorial.step == .affection && !character.lifestyle.hungry
        character.mood = .idle; character.moodUntil = .distantPast
        let head = NSPoint(x: character.crownRect.midX, y: character.crownRect.minY + character.crownRect.height * 0.3)
        let now = ProcessInfo.processInfo.systemUptime
        character.beginPointer(at: head, screenPoint: head, time: now)
        character.endPointer(at: head, time: now + 0.4)
        checks["realHeadHoldEarnsBalletOnly"] = store.tutorial.complete && character.availableDances == [.ballet] && character.danceProgress.clapBalance == 0 && !character.tutorialActive
        checks["tutorialCareDoesNotOpenNotes"] = !notes.isVisible
        tutorialBubble?.dismissButton.performClick(nil)
        checks["bubbleDismissButtonClosesOnlyDialogue"] = tutorialPanel?.isVisible == false && !notes.isVisible && pet.isVisible && store.preferences.hasMetVelvet == true
        // A paused/restarted lesson must offer an actionable instruction.
        store.setTutorial(TutorialState()); showTutorial(); togglePaused()
        tutorialBubble?.primaryButton.performClick(nil)
        checks["tutorialStartResumesPausedCharacter"] = !character.paused && store.tutorial.step == .openNote
        openNotes(); dismissTutorial(); showTutorial()
        checks["tutorialResumesWithAlreadyOpenNote"] = store.tutorial.step == .closeNote
        closeNotes(); feedVelvet(); dismissTutorial(); character.advanceLifestyle(by: 6); showTutorial()
        checks["tutorialResumesAfterSnackFinished"] = store.tutorial.step == .affection
        togglePaused(); syncTutorial()
        checks["pausedTutorialExplainsHowToContinue"] = tutorialBubble?.primaryButton.title == "Resume" && tutorialBubble?.primaryButton.isHidden == false
        tutorialBubble?.primaryButton.performClick(nil)
        character.wantsCoffee = true
        checks["tutorialExplainsExistingCoffeeGate"] = tutorialBubble?.dialogue.contains("Latte first") == true && !character.canGiveNotes
        character.wantsCoffee = false; character.rubCrown(); dismissTutorial()
        character.mood = .idle; character.moodUntil = .distantPast
        character.lifestyle.phoneRemaining = 0; character.lifestyle.attentionRemaining = 600
        character.advanceLifestyle(by: 1)
        checks["phoneTimeHasRenderedProp"] = character.mood == .phone && (89...91).contains(character.displayedSpriteIndex ?? -1)
        let position = pet.frame.origin
        character.beginPointer(at: head, screenPoint: head, time: now + 1)
        checks["phoneInterruptionStartsSulk"] = character.lifestyle.ignoring && !character.canInteract && character.mood == .phoneSulk
        character.advanceLifestyle(by: 2)
        checks["sulkTurnsWholeBodyAway"] = character.displayedSpriteIndex == 94
        let remaining = character.lifestyle.remaining
        character.rubCrown(); giveCoffee(); character.chooseDance(.ballet)
        checks["sulkCannotBeShortenedOrRestarted"] = character.lifestyle.remaining == remaining && !character.canInteract && pet.frame.origin == position
        openNotes()
        checks["sulkLeavesNotesReachableFromMenu"] = notes.isVisible && character.mood == .phoneSulk
        closeNotes(); character.paused = true; character.advanceLifestyle(by: 100)
        checks["pauseFreezesSulk"] = character.lifestyle.remaining == remaining
        character.paused = false
        let sulkSaved = character.lifestyle; store.setLifestyle(sulkSaved); store.flush()
        checks["sulkSurvivesRestart"] = NoteStore(directory: store.directory).lifestyle == sulkSaved
        character.advanceLifestyle(by: remaining)
        checks["sulkEndsAfterQuietInterval"] = character.canInteract && !character.lifestyle.ignoring
        character.lifestyle.attentionRemaining = 0; character.mood = .idle; character.moodUntil = .distantPast
        character.advanceLifestyle(by: 1)
        checks["attentionHasOwnPose"] = character.mood == .attention && character.displayedSpriteIndex == 99
        character.beginPointer(at: head, screenPoint: head, time: now + 2)
        checks["acknowledgingAttentionKeepsNotesClosed"] = character.mood == .acknowledged && !notes.isVisible && character.lifestyle.phase == .idle
        character.mood = .idle; character.moodUntil = .distantPast
        character.lifestyle.energy = 25; character.advanceLifestyle(by: 1)
        checks["tirednessStopsDances"] = character.mood == .yawn && !character.canChooseDance
        character.advanceLifestyle(by: 4)
        checks["naturalNapUsesApprovedPose"] = character.mood == .naturalNap && character.displayedSpriteIndex == 97
        let lowEnergy = character.lifestyle.energy
        character.advanceLifestyle(by: character.lifestyle.remaining)
        checks["napRestoresEnergyAndWakes"] = character.mood == .wakeUp && character.lifestyle.energy > lowEnergy
        character.advanceLifestyle(by: 4.2)
        character.lifestyle.foodRemaining = 0; character.mood = character.baseMood
        checks["hungerBlocksDanceWithoutBlockingNotes"] = !character.canChooseDance && character.canGiveNotes
        feedVelvet(); character.advanceLifestyle(by: 6)
        character.mood = .idle; character.moodUntil = .distantPast
        character.danceProgress = DanceProgress(completedClaps: 1000, unlockedDanceIDs: DanceProgress.danceIDs)
        character.chooseDance(.contemporary)
        checks["contemporaryStartsOnlyWhenChosen"] = character.mood == .contemporary && !Mood.automaticDances.contains(.contemporary)
        let spent = character.danceProgress.clapBalance
        openNotes()
        checks["openingNoteStopsDanceAndRefundsReplay"] = !character.mood.isDance && character.danceProgress.clapBalance == spent + 1 && !character.performance.awaitingApplause
        character.chooseDance(.ballet); character.react(.house)
        checks["openNotesPreventAllDances"] = !character.mood.isDance && !character.canChooseDance
        closeNotes(); character.mood = .idle; character.moodUntil = .distantPast
        character.lifestyle.danceRemaining = 1
        character.advanceLifestyle(by: 2)
        checks["eligibleCadenceStartsUnlockedSpontaneousDance"] = character.mood.isChoreography && Mood.automaticDances.contains(character.mood) && character.danceProgress.allows(character.mood.rawValue)
        character.react(.idle); character.lifestyle = LifestyleState()
        character.mood = .idle; character.moodUntil = .distantPast
        character.chooseDance(.house)
        let paidBalance = character.danceProgress.clapBalance
        let finishTime = character.moodUntil
        checks["menuDanceChargesEnergyAtStart"] = character.mood == .house && character.lifestyle.energy == 80
        character.chooseDance(.house); character.chooseDance(.vogue); character.react(.ballet)
        checks["activeDanceCannotRestartOrSwitch"] = character.mood == .house && character.moodUntil == finishTime && character.lifestyle.energy == 80 && character.danceProgress.clapBalance == paidBalance && !character.canChooseDance && character.makeDanceMenu().items.filter { $0.representedObject != nil }.allSatisfy { !$0.isEnabled }
        openNotes()
        checks["noteCancellationKeepsFatigueButRefundsClap"] = character.lifestyle.energy == 80 && character.danceProgress.clapBalance == paidBalance + 1 && !character.mood.isDance
        closeNotes(); character.react(.idle)
        for _ in 0..<3 { character.chooseDance(.house); character.react(.idle) }
        let tiredBalance = character.danceProgress.clapBalance
        character.chooseDance(.ballet); character.react(.house)
        checks["interruptedDanceSpamStillExhaustsHer"] = character.lifestyle.energy == 20 && !character.mood.isDance && !character.canChooseDance && character.danceProgress.clapBalance == tiredBalance
        store.setLifestyle(character.lifestyle); store.flush()
        checks["danceFatigueSurvivesRestart"] = NoteStore(directory: store.directory).lifestyle.energy == 20
        character.advanceLifestyle(by: 1)
        checks["danceExhaustionStartsRest"] = character.mood == .yawn && !character.canChooseDance
        character.advanceLifestyle(by: 4)
        checks["danceExhaustionLeadsToNap"] = character.mood == .naturalNap
        character.advanceLifestyle(by: character.lifestyle.remaining); character.advanceLifestyle(by: 4.2)
        character.react(.idle); character.chooseDance(.house)
        checks["completedNapAllowsNextDance"] = character.mood == .house
        character.react(.idle)
        character.lifestyle = LifestyleState(); character.activity = ActivityState()
        character.solitaryYoga = SolitaryYoga()
        character.lifestyle.danceRemaining = 600
        character.lifestyle.attentionRemaining = 1200
        character.mood = .idle; character.moodUntil = .distantPast
        character.makeRestless()
        var spontaneousWait = 0
        while spontaneousWait < 600 && !character.mood.isChoreography {
            character.advanceLifestyle(by: 1); spontaneousWait += 1
        }
        checks["ordinaryCompanyStillGetsSpontaneousDanceWithinTenEligibleMinutes"] = character.mood.isChoreography && (360...600).contains(spontaneousWait)
        checks["restlessnessDoesNotPermanentlyBlockSpontaneousDance"] = character.performance.restless && character.mood.isChoreography
        checks["spontaneousDanceAlsoCostsEnergy"] = character.lifestyle.energy < 80
        character.react(.idle)
        checks["careSpritesAreBundled"] = character.hasLifestyleAnimation && character.spriteFrameCount == 116
        checks["contemporaryMusicIsBundled"] = character.audio.hasContemporary
        let menu = makeMenu()
        checks["musicCreditsAtBottom"] = menu.items.dropLast().last?.title == "Music credits"
        checks["tutorialPersists"] = store.flush() && NoteStore(directory: store.directory).tutorial.complete
        character.previewTime = nil
        for (name, mood, time) in [("care-phone", Mood.phone, 3.0), ("care-back", .phoneSulk, 3.0), ("care-bite", .snack, 2.0), ("care-nap", .naturalNap, 3.0)] {
            character.mood = mood; character.previewTime = time
            if let bitmap = character.bitmapImageRepForCachingDisplay(in: character.bounds) {
                character.cacheDisplay(in: character.bounds, to: bitmap)
                try? bitmap.representation(using: .png, properties: [:])?.write(to: previewDirectory.appendingPathComponent(name + ".png"))
            }
        }
        character.previewTime = nil; character.mood = .idle
        return checks
    }
}
