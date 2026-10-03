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
        character.advanceIron(by: 0.3); capture("iron-grab")
        c["grabHoldsReachingPose"] = character.displayedSpriteIndex == 101
        character.advanceIron(by: 0.5); capture("iron-lift")
        c["raisesHandForEating"] = character.displayedSpriteIndex == 96
        character.advanceIron(by: 0.5); capture("iron-bite")
        character.advanceIron(by: 2.2)
        c["biteFinishesAndNotesStayClosed"] = !character.iron.eating && !notes.isVisible
        func requestAgain() {
            character.iron = IronState(timeUntilNeed: 0); character.lifestyle = LifestyleState()
            character.care = CompanionCare(); character.wantsCoffee = false; character.noteIsVisible = false
            character.mood = .idle; character.moodUntil = .distantPast
            character.screwOffset = .zero; character.screwReturnBegan = nil
            character.advanceIron(by: 1)
        }
        requestAgain()
        let pickup = NSPoint(x: character.offeredScrewRect.minX + 2, y: character.offeredScrewRect.midY)
        let parentPickup = character.superview?.convert(pickup, from: character) ?? pickup
        c["offCenterPickupRoutesToCharacter"] = character.hitTest(parentPickup) === character && character.interactiveArea(pickup)
        c["nativeParentCoordinatesRouteScrewsToCharacter"] = character.hitTest(parentPickup) === character
        c["actualNativeReceiver"] = character.hitTest(parentPickup).map { NSStringFromClass(type(of: $0)) } ?? "none"
        c["parentCoordinateY"] = Double(parentPickup.y)
        c["characterCoordinateY"] = Double(pickup.y)
        let body = NSPoint(x: character.screwDropRect.midX, y: character.screwDropRect.midY)
        // Exercise the real AppKit mouse handlers, including their coordinate conversion.
        func mouse(_ type: NSEvent.EventType, _ point: NSPoint) -> NSEvent {
            NSEvent.mouseEvent(with: type, location: character.convert(point, to: nil), modifierFlags: [],
                               timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: pet.windowNumber,
                               context: nil, eventNumber: 1, clickCount: 1, pressure: type == .leftMouseUp ? 0 : 1)!
        }
        // Dispatch through NSWindow, not directly to the view. A transparent
        // NSButton can otherwise eat the complete drag while model tests pass.
        if character.hitTest(parentPickup) === character {
            pet.ignoresMouseEvents = false
            pet.sendEvent(mouse(.leftMouseDown, pickup))
            c["nativeWindowMouseDownStartsScrewGesture"] = character.pointerIsActive
            pet.sendEvent(mouse(.leftMouseDragged, body))
            c["nativeWindowDragReachesWithoutMovingWindow"] = character.isCarryingScrews && character.displayedSpriteIndex == 101 && pet.frame.origin == origin
            pet.sendEvent(mouse(.leftMouseUp, body))
        }
        c["nativeWindowMouseUpFeedsScrews"] = character.iron.eating && !character.iron.needsScrews && pet.frame.origin == origin
        requestAgain()
        character.beginPointer(at: pickup, screenPoint: pickup, time: 10)
        // No intermediate drag callback: mouse-up contains the final movement.
        character.endPointer(at: body, time: 10.2)
        c["fastDragWithCoalescedMovementIsAccepted"] = character.iron.eating && !notes.isVisible
        requestAgain()
        let offsetPickup = NSPoint(x: character.offeredScrewRect.minX - 4, y: character.offeredScrewRect.midY)
        let besideHand = NSPoint(x: character.screwDropRect.minX - 7, y: character.screwDropRect.midY)
        character.beginPointer(at: offsetPickup, screenPoint: offsetPickup, time: 11)
        character.updatePointer(at: besideHand, screenPoint: besideHand, time: 11.2)
        c["objectTouchCountsWithCursorOutsideTarget"] = !character.screwDropRect.contains(besideHand) && character.acceptsScrewDrop(at: besideHand)
        character.endPointer(at: besideHand, time: 11.3)
        c["offsetPickupCanStillBeHandedOver"] = character.iron.eating && pet.frame.origin == origin
        requestAgain()
        character.beginPointer(at: pickup, screenPoint: pickup, time: 12)
        character.endPointer(at: .zero, time: 12.2)
        c["releaseOutsideReturnsScrewsAndKeepsNeed"] = character.iron.needsScrews && !character.iron.eating && character.screwReturnBegan != nil && !notes.isVisible
        return c
    }
}
