import AppKit

extension AppDelegate {
    func checkDrawingGifts(previewDirectory: URL) -> [String: Bool] {
        var checks: [String: Bool] = [:]
        character.stop(); character.audio.enabled = false
        character.tutorialActive = false; character.awaitingSong = false; character.wantsCoffee = false
        character.care = CompanionCare(); character.lifestyle = LifestyleState(); character.iron = IronState()
        character.coffeeOverload = CoffeeOverload(); character.happiness = HappinessState()
        character.stimulation = StimulationState(cooldown: 60)
        character.danceProgress = DanceProgress(unlockedDanceIDs: ["ballet"])
        character.mood = .idle; character.moodUntil = .distantPast; character.paused = false
        closeNotes(); tutorialPanel?.orderOut(nil)
        character.drawingGift = DrawingGiftState(timeUntilGift: 0)
        character.receiveCare(.pet); character.receiveCare(.coffee); character.receiveCare(.food)
        checks["drawingArtAndEightPosesBundled"] = character.spriteFrameCount == 124 && Bundle.main.url(forResource: "drawing-robots-kiss-v1", withExtension: "png") != nil
        // A dance invitation must not freeze a gift forever.
        character.makeRestless()
        character.advanceDrawingGift(by: 120)
        checks["careStartsDrawingEvenWithUnansweredDanceInvitation"] = character.drawingGift.phase == .drawing && character.mood == .drawing
        checks["drawingBlocksDancesWithoutGatingNotes"] = !character.danceRequirementsMet && character.canGiveNotes
        let remaining = character.drawingGift.remaining
        openNotes(); character.advanceDrawingGift(by: 10)
        checks["writingSuspendsDrawing"] = notes.isVisible && character.drawingGift.remaining == remaining
        closeNotes(); character.mood = .idle; character.moodUntil = .distantPast
        character.focusRest = .stretch; character.advanceDrawingGift(by: 10)
        checks["focusSuspendsDrawing"] = character.drawingGift.remaining == remaining
        character.focusRest = nil; character.mood = .idle
        character.paused = true; character.advanceDrawingGift(by: 10)
        checks["animationPauseSuspendsDrawing"] = character.drawingGift.remaining == remaining
        character.paused = false; character.mood = .idle
        pet.orderOut(nil); character.advanceDrawingGift(by: 10)
        checks["hiddenCharacterSuspendsDrawing"] = character.drawingGift.remaining == remaining
        pet.orderFrontRegardless(); character.setScreenLocked(true); character.advanceDrawingGift(by: 10)
        checks["screenLockSuspendsDrawing"] = character.drawingGift.remaining == remaining
        character.setScreenLocked(false); character.mood = .idle
        character.wantsCoffee = true; character.advanceDrawingGift(by: 10)
        checks["coffeeNeedTakesPriority"] = character.drawingGift.remaining == remaining && character.baseMood == .grumpy
        character.wantsCoffee = false; character.mood = .idle
        character.advanceDrawingGift(by: 4)
        store.setDrawingGift(character.drawingGift); store.flush()
        let resumed = NoteStore(directory: store.directory)
        checks["midDrawingProgressRestores"] = resumed.drawingGift == character.drawingGift && resumed.drawingGift.remaining == 6
        character.advanceDrawingGift(by: 6)
        checks["drawingEndsWithOfferedPaper"] = character.mood == .offerDrawing && character.showsDrawing && character.displayedSpriteIndex == 120
        character.advanceDrawingGift(by: 1)
        checks["offeringUsesExtendedHandsPose"] = character.displayedSpriteIndex == 121
        let offered = NSPoint(x: character.drawingHitbox.midX, y: character.drawingHitbox.midY)
        checks["offeredPictureHasWorkingHitbox"] = character.interactiveArea(offered) && character.hitTest(character.superview?.convert(offered, from: character) ?? offered) === character
        func snapshot(_ name: String) {
            character.needsDisplay = true; character.displayIfNeeded()
            if let bitmap = character.bitmapImageRepForCachingDisplay(in: character.bounds) {
                character.cacheDisplay(in: character.bounds, to: bitmap)
                try? bitmap.representation(using: .png, properties: [:])?.write(to: previewDirectory.appendingPathComponent(name + ".png"))
            }
        }
        snapshot("drawing-offer")
        character.advanceDrawingGift(by: 5)
        checks["unclaimedPaperStaysBesideHer"] = character.drawingGift.phase == .waiting && character.showsDrawing
        snapshot("drawing-waiting")
        let rect = character.drawingHitbox
        let point = NSPoint(x: rect.midX, y: rect.midY), origin = pet.frame.origin
        let count = store.activeCount, claps = character.danceProgress.clapBalance
        for type: NSEvent.EventType in [.leftMouseDown, .leftMouseUp] {
            let event = NSEvent.mouseEvent(with: type, location: character.convert(point, to: nil), modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: pet.windowNumber,
                context: nil, eventNumber: 1, clickCount: 1, pressure: type == .leftMouseUp ? 0 : 1)!
            pet.sendEvent(event)
        }
        checks["actualPaperClickCollectsWithoutDragging"] = character.drawingGift.received.count == 1 && pet.frame.origin == origin && !character.pointerIsActive
        checks["giftOpensSmallReadOnlyCard"] = drawingPanel?.isVisible == true && drawingPanel?.frame.size == NSSize(width: 360, height: 240)
        checks["giftNeverOpensNotesOrChangesClaps"] = !notes.isVisible && store.activeCount == count && character.danceProgress.clapBalance == claps
        checks["acceptedGiftUsesShyThanks"] = character.mood == .drawingThanks && character.displayedSpriteIndex == 122
        snapshot("drawing-thanks")
        if let card = drawingPanel?.contentView, let bitmap = card.bitmapImageRepForCachingDisplay(in: card.bounds) {
            card.cacheDisplay(in: card.bounds, to: bitmap)
            try? bitmap.representation(using: .png, properties: [:])?.write(to: previewDirectory.appendingPathComponent("drawing-card.png"))
        }
        let saved = NoteStore(directory: store.directory)
        checks["acceptedPictureIsSavedWithNotesIntact"] = saved.drawingGift.received.count == 1 && saved.activeCount == count
        checks["collectionMenuReopensKeepsake"] = makeMenu().items.contains { $0.title == "Her drawings" && $0.submenu?.items.first?.title == "Two little robots" }
        checks["cannotCollectTheSameGiftTwice"] = !character.acceptDrawingGift() && character.drawingGift.received.count == 1
        drawingPanel?.orderOut(nil)
        checks["noForcedNoteAfterClosingDrawing"] = !notes.isVisible && pendingNote == nil
        // Restore needs-free presentation only for an isolated drawing preview.
        character.previewTime = 2; character.mood = .drawing; snapshot("drawing-scribble"); character.previewTime = nil
        let collected = character.drawingGift
        character.drawingGift = DrawingGiftState(timeUntilGift: 0)
        for care: HappinessState.Care in [.pet, .coffee, .food] { character.drawingGift.recordCare(care) }
        character.mood = .idle; character.moodUntil = .distantPast
        character.advanceDrawingGift(by: 120); character.start()
        RunLoop.main.run(until: Date().addingTimeInterval(3.2))
        checks["realAnimationClockAdvancesScribbling"] = character.drawingGift.phase == .drawing && character.drawingGift.remaining < 7.5 && character.drawingGift.remaining > 5
        character.stop(); character.drawingGift = collected
        store.setDrawingGift(collected); store.flush()
        return checks
    }
}
