import AppKit

extension AppDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        guard !diagnostics else { return }
        let distributed = DistributedNotificationCenter.default()
        distributed.addObserver(self, selector: #selector(screenDidLock), name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
        distributed.addObserver(self, selector: #selector(screenDidUnlock), name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(sessionDidResign), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        workspace.addObserver(self, selector: #selector(sessionDidBecomeActive), name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
    }
    @objc func screenDidLock() { screenLockActive = true; updateScreenRest() }
    @objc func screenDidUnlock() { screenLockActive = false; updateScreenRest() }
    @objc func sessionDidResign() { sessionInactive = true; updateScreenRest() }
    @objc func sessionDidBecomeActive() { sessionInactive = false; updateScreenRest() }
    func saveCompanionState() {
        store.setCoffee(coffee); store.setCare(character.care); store.setLifestyle(character.lifestyle); store.setIron(character.iron)
        store.setSongRequest(songRequest); store.setActivity(character.activity)
        store.setHappiness(character.happiness); store.setCoffeeOverload(character.coffeeOverload); store.setDailyRoutine(dailyRoutine); store.flush()
    }
    func updateScreenRest(at date: Date = Date()) {
        guard let character, let notes, store != nil else { return }
        let resting = screenLockActive || sessionInactive
        guard resting != character.screenLocked else { return }
        if resting {
            screenRestBegan = date; notesVisibleBeforeScreenRest = notes.isVisible
            tutorialVisibleBeforeScreenRest = tutorialPanel?.isVisible == true
            character.setScreenLocked(true); character.displayIfNeeded()
            notes.orderOut(nil); tutorialPanel?.orderOut(nil); songPanel?.orderOut(nil); sleepyPanel?.orderOut(nil); consequencePanel?.orderOut(nil); ironPanel?.orderOut(nil)
            systemAudio.stop(); coffeeTimer?.invalidate(); saveCompanionState()
        } else {
            let seconds = max(0, date.timeIntervalSince(screenRestBegan ?? date)); screenRestBegan = nil
            character.setScreenLocked(false, restedSeconds: seconds)
            if !diagnostics { updateDailyRoutine(at: date) }
            if pet.isVisible {
                character.start()
                if character.scheduledMood == nil && character.canInteract && !character.tutorialActive && [.idle, .waking].contains(character.lifestyle.phase) { character.react(.wakeUp) }
                if notesVisibleBeforeScreenRest && character.canGiveNotes { notes.orderFrontRegardless(); anchorNotes() }
                if tutorialVisibleBeforeScreenRest { showTutorial() }
                if songRequest.waiting && character.scheduledMood == nil { showSongRequest() }
            }
            notesVisibleBeforeScreenRest = false
            tutorialVisibleBeforeScreenRest = false
            if !diagnostics && (character.listensToAudio || songRequest.waiting) { systemAudio.start() }
            startCoffeeClock(); saveCompanionState()
        }
        rebuildMenu()
    }
    func showConsequence(_ text: String) {
        if consequencePanel == nil {
            let bubble = TutorialView(frame: NSRect(x: 0, y: 0, width: 216, height: 96))
            bubble.begin = { [weak self] in self?.consequencePanel?.orderOut(nil) }
            let panel = NotesPanel(contentRect: bubble.bounds, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.title = "Velvet says"; panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
            panel.hidesOnDeactivate = false; panel.isReleasedWhenClosed = false; panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]; panel.contentView = bubble
            consequencePanel = panel; consequenceBubble = bubble
        }
        consequenceBubble?.update(text: text, primaryTitle: "Continue", complete: true)
        consequenceBubble?.dismissButton.isHidden = true
        if pet.isVisible && !character.screenLocked { consequencePanel?.orderFrontRegardless(); anchorConsequence() }
    }
    func anchorConsequence() {
        guard let panel = consequencePanel, panel.isVisible, let bubble = consequenceBubble, let screen = pet.screen ?? NSScreen.main else { return }
        anchorSpeech(panel: panel, bubble: bubble, screen: screen)
    }
    func anchorNightVisit() {
        guard let panel = sleepyPanel, panel.isVisible, let bubble = sleepyBubble, let screen = pet.screen ?? NSScreen.main else { return }
        anchorSpeech(panel: panel, bubble: bubble, screen: screen)
    }
    func syncNightVisit() {
        guard let character, character.isNightVisit, !character.screenLocked else { sleepyPanel?.orderOut(nil); return }
        if sleepyPanel == nil {
            let bubble = TutorialView(frame: NSRect(x: 0, y: 0, width: TutorialView.bubbleWidth, height: 96))
            bubble.begin = { [weak self] in self?.character.returnToBed() }
            let panel = NotesPanel(contentRect: bubble.bounds, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.title = "Sleepy Velvet"; panel.isOpaque = false; panel.backgroundColor = .clear
            panel.hasShadow = true; panel.isReleasedWhenClosed = false; panel.hidesOnDeactivate = false
            panel.becomesKeyOnlyIfNeeded = true; panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]; panel.contentView = bubble
            sleepyPanel = panel; sleepyBubble = bubble
        }
        sleepyBubble?.update(text: "You woke me… one tiny cuddle, then I’m going back to bed.", primaryTitle: "Back to bed", complete: false)
        sleepyBubble?.dismissButton.isHidden = true
        if pet.isVisible, let panel = sleepyPanel, let bubble = sleepyBubble, let screen = pet.screen ?? NSScreen.main {
            panel.orderFrontRegardless(); anchorSpeech(panel: panel, bubble: bubble, screen: screen)
        }
        rebuildMenu()
    }
}
