import AppKit

extension AppDelegate {
    func checkStyling(previewDirectory: URL) -> [String: Bool] {
        var checks: [String: Bool] = [:]
        character.stop(); character.audio.enabled = false; tutorialPanel?.orderOut(nil); closeNotes()
        character.tutorialActive = false; character.awaitingSong = false; character.wantsCoffee = false
        character.care = CompanionCare(); character.lifestyle = LifestyleState(); character.iron = IronState()
        character.coffeeOverload = CoffeeOverload(); character.stimulation = StimulationState(cooldown: 60)
        character.happiness = HappinessState(); character.drawingGift = DrawingGiftState()
        character.styling = StylingState(); character.danceProgress = DanceProgress(completedClaps: 41, unlockedDanceIDs: ["ballet"])
        character.mood = .idle; character.moodUntil = .distantPast; character.paused = false
        checks["stylingPosesBundled"] = character.spriteFrameCount == 128
        checks["jerseyReactionsBundled"] = character.audio.hasJersey
        checks["mutingPreventsReactionAndCooldown"] = !character.audio.playJersey(.pleased, roll: 0, now: 100) && character.audio.jerseyCadence.lastPlayed == nil
        character.audio.volume = 0; character.audio.enabled = true
        checks["reactionPlaysOnce"] = character.audio.playJersey(.pleased, roll: 0, now: 100)
        checks["rapidDifferentReactionBlocked"] = !character.audio.playJersey(.attitude, roll: 0, now: 101)
        character.audio.stopAll(); character.audio.playQuiet()
        checks["jerseyYieldsToShutdownSound"] = !character.audio.playJersey(.laugh, roll: 0, now: 200) && character.audio.jerseyCadence.lastPlayed == 100
        character.audio.stopAll(); character.audio.updateDance(vogue: true, breaking: false)
        checks["jerseyDoesNotInterruptDanceMusic"] = !character.audio.playJersey(.shy, roll: 0, now: 200) && character.audio.isChantPlaying
        character.audio.enabled = false
        checks["lockedItemCannotBeBoughtEvenWithFunds"] = !character.selectStyle(.tribalHeart) && character.danceProgress.clapBalance == 41
        for care: HappinessState.Care in [.pet, .coffee, .food] { character.receiveCare(care) }
        checks["careUnlocksShopWithoutFreeOwnership"] = character.styling.available.contains(.tribalHeart) && character.styling.purchased.isEmpty && character.styling.worn.isEmpty
        openNotes(); closeNotes(); character.mood = .idle; character.moodUntil = .distantPast
        let count = store.activeCount
        checks["tattooPurchaseSpendsTenAndStartsMirror"] = character.selectStyle(.tribalHeart, sideEye: false) && character.danceProgress.clapBalance == 31 && character.mood == .styling && character.displayedSpriteIndex == 124
        character.previewTime = 1.8
        checks["mirrorHasSecondPose"] = character.displayedSpriteIndex == 125
        character.previewTime = 3
        checks["confidentFinishUsesThirdPose"] = character.displayedSpriteIndex == 126
        character.stylingSideEye = true
        checks["brattyFinishUsesSideEyePose"] = character.displayedSpriteIndex == 127
        character.previewTime = nil; character.mood = .idle; character.moodUntil = .distantPast
        var drawing = DrawingGiftState(timeUntilGift: 0)
        for care: HappinessState.Care in [.pet, .food, .coffee] { drawing.recordCare(care) }
        drawing.advance(by: 120, available: true, happiness: 1); drawing.advance(by: 10, available: true, happiness: 1)
        character.drawingGift = drawing; character.mood = .offerDrawing
        _ = character.acceptDrawingGift(); drawingPanel?.orderOut(nil)
        checks["drawingUnlocksPiercingShopOnly"] = character.styling.available.contains(.navelPiercing) && !character.styling.purchased.contains(.navelPiercing)
        character.mood = .idle; character.moodUntil = .distantPast
        checks["piercingCostsAnotherTen"] = character.selectStyle(.navelPiercing, sideEye: false) && character.danceProgress.clapBalance == 21 && character.styling.worn.count == 2
        character.mood = .idle; character.moodUntil = .distantPast
        checks["legWarmersEarnedWithoutFreeOwnership"] = character.styling.available.contains(.legWarmers) && !character.styling.purchased.contains(.legWarmers)
        checks["legWarmersCostTenAndJoinExistingLook"] = character.selectStyle(.legWarmers, sideEye: false) && character.danceProgress.clapBalance == 11 && character.styling.worn.count == 3 && character.styling.imageKey == 7
        character.receiveCare(.attention)
        checks["attentionAndAffectionUnlockCharmShopOnly"] = character.styling.available.contains(.heartCharm) && !character.styling.purchased.contains(.heartCharm)
        character.mood = .idle; character.moodUntil = .distantPast
        checks["charmPurchaseCostsTenAndCompletesLook"] = character.selectStyle(.heartCharm, sideEye: false) && character.danceProgress.clapBalance == 1 && character.styling.worn.count == 4 && character.styling.imageKey == 15
        store.flush()
        let resumed = NoteStore(directory: store.directory)
        checks["purchaseAndBalanceSaveTogether"] = resumed.styling == character.styling && resumed.danceProgress.clapBalance == 1 && resumed.danceProgress.cosmeticClapsSpent == 40
        character.mood = .idle; character.moodUntil = .distantPast
        checks["takingOffPurchasedItemIsFree"] = character.selectStyle(.tribalHeart) && character.danceProgress.clapBalance == 1 && !character.styling.worn.contains(.tribalHeart)
        character.mood = .idle; character.moodUntil = .distantPast
        checks["puttingItBackOnIsFree"] = character.selectStyle(.tribalHeart) && character.danceProgress.clapBalance == 1 && character.styling.worn.contains(.tribalHeart)
        character.mood = .idle; character.moodUntil = .distantPast
        let menus = makeStylingMenu().items.filter { $0.representedObject != nil }
        checks["stylingMenuIsSortedAndMarksWornItems"] = menus.map(\.title) == ["Heart charm", "Leg warmers", "Navel piercing", "Tribal heart tattoo"] && menus.allSatisfy { $0.state == .on }
        let staleMenu = makeMenu()
        character.mood = .styling; character.moodUntil = Date().addingTimeInterval(4)
        menuNeedsUpdate(staleMenu)
        let disabled = staleMenu.items.first { $0.title == "Styling" }?.submenu?.items.first { $0.representedObject as? String == Cosmetic.legWarmers.rawValue }
        checks["outfitBusyMenuDisablesActions"] = disabled?.isEnabled == false
        character.mood = .idle; character.moodUntil = .distantPast
        menuNeedsUpdate(staleMenu)
        checks["menuRefreshesAfterMirrorFinishes"] = staleMenu.items.first { $0.title == "Styling" }?.submenu?.items.first { $0.representedObject as? String == Cosmetic.legWarmers.rawValue }?.isEnabled == true
        character.mood = .sleep
        checks["sleepDoesNotAllowOutfitChange"] = !character.selectStyle(.legWarmers)
        character.mood = .idle
        openNotes(); let before = character.styling
        checks["writingPreventsOutfitAnimation"] = !character.selectStyle(.tribalHeart) && character.styling == before
        closeNotes(); character.mood = .idle; character.moodUntil = .distantPast
        character.focusRest = .stretch
        checks["focusPreventsOutfitAnimation"] = !character.selectStyle(.tribalHeart)
        character.focusRest = nil; character.mood = .idle
        character.makeOverstimulated()
        checks["overwhelmPreventsCosmeticInteraction"] = !character.selectStyle(.tribalHeart)
        checks["stylingPreservesNotes"] = store.activeCount == count
        checks["backAndCoveredPosesConcealJewelry"] = [27, 35, 93, 94, 95, 103, 104, 105, 108, 109, 110, 116, 117, 118, 119, 120, 121].allSatisfy { BodyStyling.placement(for: $0) == nil }
        character.stimulation = StimulationState(cooldown: 60)
        checks["allStylesPreserveSpriteSilhouetteAlpha"] = character.styledSilhouettesMatch()
        character.renderStyleSheets(to: previewDirectory)
        character.mood = .styling; character.previewTime = 3; character.stylingSideEye = false
        if let bitmap = character.bitmapImageRepForCachingDisplay(in: character.bounds) {
            character.cacheDisplay(in: character.bounds, to: bitmap)
            try? bitmap.representation(using: .png, properties: [:])?.write(to: previewDirectory.appendingPathComponent("styling-desktop.png"))
        }
        character.previewTime = nil
        return checks
    }
}
