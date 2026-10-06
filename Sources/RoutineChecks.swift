import AppKit

extension AppDelegate {
    func checkRoutine(previewDirectory: URL) -> [String: Bool] {
        var checks: [String: Bool] = [:]
        character.coffeeOverload = CoffeeOverload()
        character.audio.enabled = false
        tutorialPanel?.orderOut(nil); character.tutorialActive = false; closeNotes()
        character.tutorialActive = false; character.awaitingSong = false
        character.care = CompanionCare(); character.lifestyle = LifestyleState()
        character.stimulation = StimulationState(cooldown: 60); character.wantsCoffee = false
        character.paused = false; character.dailyRoutine = DailyRoutine(); dailyRoutine = DailyRoutine()
        character.mood = .idle; character.moodUntil = .distantPast
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        func date(_ hour: Int) -> Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: 3, hour: hour))! }
        func capture(_ name: String, mood: Mood, time: Double) {
            character.mood = mood; character.previewTime = time
            if let bitmap = character.bitmapImageRepForCachingDisplay(in: character.bounds) {
                character.cacheDisplay(in: character.bounds, to: bitmap)
                try? bitmap.representation(using: .png, properties: [:])?.write(to: previewDirectory.appendingPathComponent(name))
            }
            character.previewTime = nil
        }
        checks["dailySpritesBundled"] = character.hasDailyAnimation && character.spriteFrameCount == 128
        checks["cuteYogaSpritesBundled"] = Bundle.main.url(forResource: "yoga-sprites-v2", withExtension: "png") != nil
        updateDailyRoutine(at: date(22), calendar: calendar)
        checks["tenPMWatchesSeriesAndBlocksDancing"] = character.mood == .windDown && character.displayedSpriteIndex == 104 && !character.canChooseDance
        checks["nightPreventsSongRequests"] = !canRequestSong(spotifySupported: true, metadataAvailable: true)
        openNotes()
        checks["nightRoutineKeepsNotesAvailable"] = notes.isVisible && character.mood == .windDown
        closeNotes(); capture("series-preview.png", mood: .windDown, time: 0.2)
        updateDailyRoutine(at: date(23), calendar: calendar, bellyChoice: true)
        checks["bedtimeClosesLaptop"] = character.mood == .bellySleep && character.displayedSpriteIndex == 106
        capture("belly-sleep-preview.png", mood: .bellySleep, time: 2)
        checks["bedtimeHasBellyPose"] = character.mood == .bellySleep
        let care = character.lifestyle
        character.advanceLifestyle(by: 2000)
        checks["overnightNeedsRest"] = character.lifestyle == care
        updateDailyRoutine(at: date(8), calendar: calendar)
        checks["eightAMWakesAndRestoresEnergy"] = character.mood == .wakeUp && character.lifestyle.energy == 100
        character.previewTime = 2
        checks["morningHasNewWakeStretch"] = character.displayedSpriteIndex == 111
        character.previewTime = nil
        capture("morning-preview.png", mood: .wakeUp, time: 2)
        character.mood = .idle; character.moodUntil = .distantPast
        character.solitaryYoga = SolitaryYoga(remaining: 0)
        character.react(.yoga)
        checks["yogaRequiresSolitudeEvenWhenDue"] = character.mood == .idle
        character.advanceSolitaryYoga(by: 299)
        checks["yogaWaitsFiveMinutesWithoutCompany"] = character.mood == .idle
        character.advanceSolitaryYoga(by: 1)
        checks["soloYogaStartsAndReschedulesRareOpportunity"] = character.mood == .yoga && SolitaryYoga.interval.contains(character.solitaryYoga.remaining)
        character.mood = .idle; character.moodUntil = .distantPast
        character.solitaryYoga = SolitaryYoga(remaining: 0)
        character.solitaryYoga.advance(by: 300, alone: true, available: true)
        character.recordActivity(.pet)
        character.react(.yoga)
        checks["affectionPostponesDueYoga"] = character.mood == .idle && !character.solitaryYoga.ready
        openNotes(); character.advanceSolitaryYoga(by: 1000)
        checks["openNotesPreventSoloYoga"] = character.mood != .yoga && !character.solitaryYoga.ready
        closeNotes(); character.mood = .idle; character.moodUntil = .distantPast
        character.solitaryYoga.advance(by: 300, alone: true, available: true)
        character.focusRest = .stretch; character.react(.yoga)
        checks["focusStretchingCannotBecomeYoga"] = character.mood == .stretch
        character.focusRest = nil; character.mood = .idle; character.moodUntil = .distantPast
        checks["yogaIsAbsentFromActionMenu"] = makeMenu().items.first { $0.title == "Try a little attitude" }?.submenu?.items.contains { $0.representedObject as? String == Mood.yoga.rawValue } == false
        for (step, time) in [0.2, 3.8, 7.4, 11.0].enumerated() {
            character.mood = .yoga; character.previewTime = time
            checks["yogaPose\(step)"] = character.displayedSpriteIndex == 112 + step
            capture("yoga-\(step).png", mood: .yoga, time: time)
        }
        character.moodUntil = .distantPast; character.lifestyle.foodRemaining = 0
        character.react(.hungry)
        let originalPosition = pet.frame.origin, originalCount = store.activeCount
        let bar = NSPoint(x: character.snackButtonRect.midX, y: character.snackButtonRect.midY)
        let now = ProcessInfo.processInfo.systemUptime
        character.beginPointer(at: bar, screenPoint: bar, time: now)
        character.endPointer(at: bar, time: now + 0.1)
        checks["barTapDoesNotFeedOrOpenNotes"] = character.lifestyle.hungry && !notes.isVisible && store.activeCount == originalCount
        character.beginPointer(at: bar, screenPoint: bar, time: now + 1)
        let miss = NSPoint(x: 15, y: 180)
        character.updatePointer(at: miss, screenPoint: miss, time: now + 1.2)
        checks["dragBarTriggersReachingPose"] = character.isCarryingBar && character.displayedSpriteIndex == 101
        character.endPointer(at: miss, time: now + 1.3)
        checks["missedBarReturnsWithoutMovingHer"] = character.lifestyle.hungry && pet.frame.origin == originalPosition && !character.isCarryingBar
        let returned = NSPoint(x: character.snackButtonRect.midX, y: character.snackButtonRect.midY)
        character.beginPointer(at: returned, screenPoint: returned, time: now + 2)
        let hand = NSPoint(x: character.barHandRect.midX, y: character.barHandRect.midY)
        character.updatePointer(at: hand, screenPoint: hand, time: now + 2.2)
        capture("bar-handoff-preview.png", mood: .hungry, time: 0.2)
        character.endPointer(at: hand, time: now + 2.3)
        checks["handDropCatchesBarAndFeeds"] = character.lifestyle.phase == .snack && character.displayedSpriteIndex == 102 && !notes.isVisible && pet.frame.origin == originalPosition
        let audio = character.audio
        audio.volume = 0.8
        checks["latteSequenceQuieterThanMaster"] = abs(audio.coffeeVolume - 0.52) < 0.0001
        audio.volume = 0.2
        checks["latteAttenuationFollowsVolumeChanges"] = abs(audio.coffeeVolume - 0.13) < 0.0001
        audio.volume = 0
        checks["latteStillRespectsMute"] = audio.coffeeVolume == 0
        character.activity.advance(by: 7200, available: true)
        checks["littleCompanyStopsAutomaticDances"] = character.activity.automaticDanceRate == 0
        for n in 0..<4 { character.recordActivity(.pet, at: now + Double(n * 5 + 20)) }
        checks["affectionRestoresEnthusiasm"] = character.activity.automaticDanceRate > 0
        character.activity.missedAttention(); character.activity.missedAttention()
        checks["missedAttentionMakesHerWithdrawn"] = character.activity.withdrawn && character.activity.automaticDanceRate == 0
        store.setActivity(character.activity); store.setDailyRoutine(dailyRoutine); store.flush()
        let resumed = NoteStore(directory: store.directory)
        checks["newRoutineStatePersists"] = resumed.activity.level == character.activity.level && resumed.dailyRoutine.bellySleep == dailyRoutine.bellySleep
        return checks
    }
}
