import AppKit
import Darwin

extension AppDelegate {
    func checkRenderingWork() -> [String: Bool] {
        var checks: [String: Bool] = [:]
        character.stop(); character.audio.enabled = false; character.paused = false
        character.dailyRoutine = DailyRoutine(); character.awaitingSong = false
        character.lifestyle = LifestyleState(); character.care = CompanionCare(); character.wantsCoffee = false
        character.stimulation = StimulationState(cooldown: 60); character.tutorialActive = false
        character.mood = .idle; character.moodUntil = .distantFuture
        checks["idleUsesLowerCadence"] = character.animationInterval == 1.0 / 12
        character.paused = true
        checks["pausedUsesQuietCadence"] = character.animationInterval == 0.25
        func capture() -> Data? {
            guard let bitmap = character.bitmapImageRepForCachingDisplay(in: character.bounds) else { return nil }
            character.cacheDisplay(in: character.bounds, to: bitmap)
            return bitmap.representation(using: .png, properties: [:])
        }
        let first = capture(), count = character.rasterizationCount
        let second = capture()
        checks["unchangedPoseReusesPixelsWithoutChangingImage"] = first != nil && first == second && character.rasterizationCount == count
        character.mood = .wave; _ = capture()
        checks["changedPoseInvalidatesPixels"] = character.rasterizationCount > count
        let previous = character.rasterizationCount, bounds = character.bounds
        character.bounds.size.width += 8; _ = capture()
        checks["resizeInvalidatesPixels"] = character.rasterizationCount > previous
        character.bounds = bounds; character.paused = false
        character.mood = .house
        checks["dancesKeepFullCadence"] = character.animationInterval == 1.0 / 24
        character.mood = .idle
        let head = NSPoint(x: character.crownRect.midX, y: character.crownRect.minY + character.crownRect.height * 0.3)
        let now = ProcessInfo.processInfo.systemUptime
        character.beginPointer(at: head, screenPoint: head, time: now)
        checks["headGesturesImmediatelyUseFullCadence"] = character.animationInterval == 1.0 / 24
        character.endPointer(at: head, time: now + 0.4)
        checks["headHoldRemainsAffection"] = character.mood == .affection
        return checks
    }
    /// Real window drawing and CPU time, using temporary notes and silent audio.
    func profileCPU(to url: URL) {
        coffeeTimer?.invalidate(); systemAudio.stop(); dismissTutorial(); closeNotes()
        character.audio.enabled = false; character.tutorialActive = false
        let checks = checkRenderingWork()
        var results: [[String: Any]] = []
        let scenarios = ["idle", "sleeping", "paused", "dancing", "hidden"]
        func cpuTime() -> Double {
            var usage = rusage(); getrusage(RUSAGE_SELF, &usage)
            return Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec) + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000_000
        }
        func run(_ index: Int) {
            guard index < scenarios.count else {
                let data: [String: Any] = ["scenarios": results, "checks": checks, "spotifyPlaybackStarted": false]
                try? JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys]).write(to: url)
                NSApp.terminate(nil); return
            }
            character.stop(); character.paused = false; character.awaitingSong = false
            character.lifestyle = LifestyleState(); character.care = CompanionCare()
            character.stimulation = StimulationState(cooldown: 60); character.wantsCoffee = false
            character.activity = ActivityState(); character.dailyRoutine = DailyRoutine()
            character.danceProgress = DanceProgress(completedClaps: 1000, unlockedDanceIDs: DanceProgress.danceIDs)
            character.tutorialActive = scenarios[index] != "sleeping"
            pet.orderFrontRegardless(); character.start(); character.react(.idle)
            if scenarios[index] == "sleeping" {
                var routine = DailyRoutine()
                var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
                routine.update(at: calendar.date(from: DateComponents(year: 2026, month: 10, day: 3, hour: 23))!, calendar: calendar, bellyChoice: false)
                character.applyDailyRoutine(routine)
            }
            if scenarios[index] == "paused" { character.paused = true }
            if scenarios[index] == "dancing" {
                character.tutorialActive = false; character.chooseDance(.house)
            }
            if scenarios[index] == "hidden" { pet.orderOut(nil); character.stop() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [self] in
                let start = ProcessInfo.processInfo.systemUptime, cpu = cpuTime()
                let ticks = character.tickCount, draws = character.drawCount
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [self] in
                    let elapsed = ProcessInfo.processInfo.systemUptime - start
                    results.append(["mode": scenarios[index], "seconds": elapsed, "cpuPercentOfOneCore": 100 * (cpuTime() - cpu) / elapsed,
                                    "ticks": character.tickCount - ticks, "draws": character.drawCount - draws])
                    run(index + 1)
                }
            }
        }
        run(0)
    }
}
