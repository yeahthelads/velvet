import AppKit
extension AppDelegate {
    func checkIron(previewDirectory: URL) -> [String: Any] {
        var c: [String: Any] = [:]
        character.audio.enabled = false; character.paused = false; character.tutorialActive = false
        character.dailyRoutine = DailyRoutine(); character.care = CompanionCare(); character.lifestyle = LifestyleState()
        character.coffeeOverload = CoffeeOverload(); character.wantsCoffee = false; character.awaitingSong = false
        character.stimulation = StimulationState(cooldown: 60); character.focusRest = nil; character.noteIsVisible = false
        character.mood = .idle; character.moodUntil = .distantPast
        character.iron = IronState(timeUntilNeed: 0)
        character.advanceIron(by: 1)
        c["requestGetsFullTwoMinutes"] = character.iron.phase == .requested && character.iron.requestRemaining == 120
        c["screwsOfferedAndDanceBlockedButNotesAvailable"] = character.showsScrews && !character.danceRequirementsMet && character.canGiveNotes
        func capture(_ name: String) {
            character.previewTime = 0.2
            if let bitmap = character.bitmapImageRepForCachingDisplay(in: character.bounds) {
                character.cacheDisplay(in: character.bounds, to: bitmap)
                try? bitmap.representation(using: .png, properties: [:])?.write(to: previewDirectory.appendingPathComponent(name + ".png"))
            }
            character.previewTime = nil
        }
        syncIronRequest(announce: true)
        c["boundedIronBubble"] = ironBubble?.bubbleSize.width == 216 && (ironBubble?.bubbleSize.height ?? 500) < 150
        capture("iron-request")
        let origin = pet.frame.origin, screws = NSPoint(x: character.offeredScrewRect.midX, y: character.offeredScrewRect.midY)
        character.beginPointer(at: screws, screenPoint: screws, time: 1)
        character.endPointer(at: screws, time: 1.1)
        c["tapDoesNotFeedOrOpenNotes"] = character.iron.needsScrews && !notes.isVisible
        character.beginPointer(at: screws, screenPoint: screws, time: 2)
        character.updatePointer(at: .zero, screenPoint: .zero, time: 2.2)
        character.endPointer(at: .zero, time: 2.3)
        c["missDoesNotFeedOrMoveWindow"] = character.iron.needsScrews && pet.frame.origin == origin
        character.screwReturnBegan = nil; character.screwOffset = .zero
        let deadline = character.iron.requestRemaining
        character.paused = true; character.advanceIron(by: 200); character.paused = false
        c["pauseFreezesDeadline"] = character.iron.requestRemaining == deadline
        character.focusRest = .focusNap; character.advanceIron(by: 200); character.focusRest = nil
        c["focusFreezesDeadline"] = character.iron.requestRemaining == deadline
        character.tutorialActive = true; character.advanceIron(by: 200); character.tutorialActive = false
        c["tutorialFreezesDeadline"] = character.iron.requestRemaining == deadline
        character.noteIsVisible = true; character.advanceIron(by: 200); character.noteIsVisible = false
        c["notesFreezeDeadline"] = character.iron.requestRemaining == deadline
        character.wantsCoffee = true; character.advanceIron(by: 200); character.wantsCoffee = false
        c["otherCareNeedFreezesDeadline"] = character.iron.requestRemaining == deadline
        pet.orderOut(nil); character.advanceIron(by: 200); pet.orderFrontRegardless()
        c["hiddenFreezesDeadline"] = character.iron.requestRemaining == deadline
        var nightCalendar = Calendar(identifier: .gregorian); nightCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let midnight = nightCalendar.date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 0))!
        character.dailyRoutine.update(at: midnight, calendar: nightCalendar); character.advanceIron(by: 200); character.dailyRoutine = DailyRoutine()
        c["bedtimeFreezesDeadline"] = character.iron.requestRemaining == deadline
        store.setIron(character.iron); store.flush()
        c["requestedDeadlineSurvivesRestart"] = NoteStore(directory: store.directory).iron.requestRemaining == deadline
        character.setScreenLocked(true); character.advanceIron(by: 200); character.setScreenLocked(false)
        c["lockFreezesDeadline"] = character.iron.requestRemaining == deadline
        character.mood = character.baseMood; character.moodUntil = .distantPast
        character.advanceIron(by: 119)
        c["notLowBeforeDeadline"] = !character.iron.lowIron
        character.advanceIron(by: 1)
        c["lowAfterTwoMinutes"] = character.iron.lowIron && character.mood == .ironLow
        capture("iron-low")
        store.setIron(character.iron); store.flush()
        c["deficiencySurvivesRestart"] = NoteStore(directory: store.directory).iron.lowIron
        character.lifestyle.restAfterNight()
        c["sleepCannotCureIron"] = character.iron.lowIron
        let food = character.lifestyle.foodRemaining, happy = character.happiness.level
        character.lifestyle.energy = 70
        let hand = NSPoint(x: character.barHandRect.midX, y: character.barHandRect.midY)
        character.beginPointer(at: screws, screenPoint: screws, time: 3)
        character.updatePointer(at: hand, screenPoint: hand, time: 3.2)
        c["reachesForDraggedScrews"] = character.displayedSpriteIndex == 101 && pet.frame.origin == origin
        capture("iron-reaching")
        character.endPointer(at: hand, time: 3.3)
        c["dropCuresIronAndStartsEating"] = !character.iron.needsScrews && character.iron.eating && character.mood == .ironSnack
        c["modestEnergyAndHappinessWithoutFoodReset"] = character.lifestyle.energy == 78 && character.happiness.level > happy && character.lifestyle.foodRemaining == food
        c["noRepeatedFeeding"] = !character.giveScrews()
        c["eatingBlocksCareInterruptions"] = !character.acceptCharacterInteraction()
        character.advanceIron(by: 0.6); capture("iron-bite")
        character.advanceIron(by: 2.9)
        c["biteFinishesAndNotesStayClosed"] = !character.iron.eating && !notes.isVisible
        return c
    }
}
