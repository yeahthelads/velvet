import AppKit
import SwiftUI
import Carbon
import Darwin

final class NotesPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var pet: PetPanel!
    var character: CharacterView!
    var notes: NotesPanel!
    var store: NoteStore!
    var status: NSStatusItem!
    var hotKey: EventHotKeyRef?
    var hotKeyHandler: EventHandlerRef?
    var lastPositionSave = Date.distantPast
    var terminationSignal: DispatchSourceSignal?
    var coffee = CoffeeState()
    var coffeeTimer: Timer?
    var lastCoffeeTick = ProcessInfo.processInfo.systemUptime
    var lastCoffeeCheckpoint = ProcessInfo.processInfo.systemUptime
    var adjustingFocusTime = false
    enum PendingNote { case open, new }
    var pendingNote: PendingNote?
    let shortcutLabels = ["⌃⌥N", "⌃⇧N", "⌘⇧J"]
    let shortcutModifiers = [UInt32(controlKey | optionKey), UInt32(controlKey | shiftKey), UInt32(cmdKey | shiftKey)]
    let shortcutCodes = [UInt32(kVK_ANSI_N), UInt32(kVK_ANSI_N), UInt32(kVK_ANSI_J)]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let args = CommandLine.arguments
        let directory: URL
        if let i = args.firstIndex(of: "--data-dir"), args.count > i + 1 {
            directory = URL(fileURLWithPath: args[i + 1], isDirectory: true)
        } else {
            directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Velvet", isDirectory: true)
        }
        store = NoteStore(directory: directory)
        coffee = store.coffee
        signal(SIGTERM, SIG_IGN)
        terminationSignal = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        terminationSignal?.setEventHandler { NSApp.terminate(nil) }
        terminationSignal?.resume()
        createMainMenu()
        createPet()
        createNotes()
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Velvet")
        status.button?.toolTip = "Velvet · your thoughts, with attitude"
        rebuildMenu()
        if !args.contains("--render-preview") {
            installHotKeyHandler()
            registerShortcut(store.preferences.shortcut)
        }
        store.onSaved = { [weak self] in
            guard let self, self.character.canGiveNotes, !self.store.focus.isActive, !self.character.hasGentleResponse, !self.character.performance.isEngaged, !self.character.stimulation.overstimulated, !self.character.isBusy, self.character.mood != .pickedUp, !self.character.mood.isDance else { return }
            self.character.react(.celebrate, duration: 1.2)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(willSleep), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
        character.start()
        startCoffeeClock()
        pet.orderFrontRegardless()
        if args.contains("--show-notes") { openNotes() }
        if args.contains("--dance") { character.react(.ballet, duration: 12) }
        if args.contains("--grumpy") { makeGrumpy() }
        if let i = args.firstIndex(of: "--render-preview"), args.count > i + 1 {
            renderPreview(to: URL(fileURLWithPath: args[i + 1]))
            NSApp.terminate(nil)
        }
        if let i = args.firstIndex(of: "--smoke-test"), args.count > i + 1 {
            runSmokeTest(to: URL(fileURLWithPath: args[i + 1]))
        }
    }

    func createMainMenu() {
        let main = NSMenu()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Velvet", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appItem = NSMenuItem(); appItem.submenu = appMenu; main.addItem(appItem)
        let edit = NSMenu(title: "Edit")
        for (title, action, key) in [("Undo", "undo:", "z"), ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            edit.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
        }
        let item = NSMenuItem(title: "Edit", action: nil, keyEquivalent: ""); item.submenu = edit; main.addItem(item)
        NSApp.mainMenu = main
    }
    func createPet() {
        pet = PetPanel(contentRect: NSRect(x: 0, y: 0, width: 190, height: 200), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        pet.title = "Velvet companion"
        pet.isOpaque = false; pet.backgroundColor = .clear; pet.hasShadow = false
        pet.hidesOnDeactivate = false; pet.isReleasedWhenClosed = false
        pet.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        pet.level = store.preferences.alwaysOnTop ? .floating : .normal
        pet.becomesKeyOnlyIfNeeded = true
        character = CharacterView(frame: NSRect(x: 0, y: 0, width: 190, height: 200))
        character.paused = store.preferences.paused
        character.care = store.care
        store.setCare(character.care)
        character.wantsCoffee = coffee.needsCoffee
        character.onNeedsChanged = { [weak self] in self?.careStateChanged() }
        character.onPerformanceChanged = { [weak self] in self?.rebuildMenu() }
        character.onCoffee = { [weak self] in self?.giveCoffee() }
        character.onClick = { [weak self] in self?.toggleNotes() }
        character.onMove = { [weak self] in self?.petMoved() }
        character.onDrop = { [weak self] in
            guard let self else { return }
            self.constrainPet()
            self.store.setPreferences { $0.x = Double(self.pet.frame.minX); $0.y = Double(self.pet.frame.minY) }
            if self.notes.isVisible { self.anchorNotes() }
        }
        character.contextMenu = { [weak self] in self?.makeMenu() ?? NSMenu() }
        pet.contentView = character
        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        pet.setFrameOrigin(NSPoint(x: store.preferences.x ?? Double(visible.maxX - 225), y: store.preferences.y ?? Double(visible.minY + 38)))
        constrainPet()
    }
    func createNotes() {
        notes = NotesPanel(contentRect: NSRect(x: 0, y: 0, width: 340, height: 350), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        notes.title = "Velvet notes"
        notes.isOpaque = false; notes.backgroundColor = .clear; notes.hasShadow = true
        notes.isReleasedWhenClosed = false; notes.hidesOnDeactivate = false
        notes.level = .floating
        notes.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        notes.delegate = self
        notes.contentView = NSHostingView(rootView: NotesView(store: store, close: { [weak self] in self?.closeNotes() }, export: { [weak self] note in self?.export(note) }, create: { [weak self] in self?.quickCapture() }, trash: { [weak self] note in self?.trashNote(note) }, focusToggle: { [weak self] in self?.toggleFocus() }, focusStart: { [weak self] minutes in self?.startFocus(minutes: minutes) }, focusEnd: { [weak self] in self?.endFocus() }, focusAdjust: { [weak self] seconds in self?.adjustFocus(to: seconds) }, focusEditing: { [weak self] editing in self?.adjustingFocusTime = editing }))
    }
    func constrainPet() {
        guard let pet else { return }
        let screens = NSScreen.screens
        let center = NSPoint(x: pet.frame.midX, y: pet.frame.midY)
        let screen = screens.first { $0.frame.contains(center) } ?? screens.max {
            let a = $0.frame.intersection(pet.frame), b = $1.frame.intersection(pet.frame)
            return a.width * a.height < b.width * b.height
        }
        guard let frame = screen?.visibleFrame else { return }
        let x = min(max(pet.frame.minX, frame.minX), frame.maxX - pet.frame.width)
        let y = min(max(pet.frame.minY, frame.minY), frame.maxY - pet.frame.height)
        pet.setFrameOrigin(NSPoint(x: x, y: y))
    }
    func petMoved() {
        if !characterIsDragging { constrainPet() }
        if notes.isVisible { anchorNotes() }
        if Date().timeIntervalSince(lastPositionSave) > 0.25 {
            store.setPreferences { $0.x = Double(pet.frame.minX); $0.y = Double(pet.frame.minY) }
            lastPositionSave = Date()
        }
    }
    var characterIsDragging: Bool { character.mood == .pickedUp }
    func anchorNotes() {
        let frame = pet.screen?.visibleFrame ?? NSScreen.main!.visibleFrame
        let width = min(340.0, frame.width - 16), height = min(350.0, frame.height - 16)
        let inset = 24 + (1 - CharacterView.presentationRatio) * 60
        let preferredX = pet.frame.midX > frame.midX ? pet.frame.minX - width + inset : pet.frame.maxX - inset
        let x = min(max(preferredX, frame.minX + 8), frame.maxX - width - 8)
        let y = min(max(pet.frame.midY - height / 2 + 55 - (1 - CharacterView.presentationRatio) * 86, frame.minY + 8), frame.maxY - height - 8)
        notes.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        character.noteDirection = notes.frame.midX < pet.frame.midX ? -1 : 1
    }
    @objc func openNotes() {
        requestNotes(createNew: false)
    }
    func requestNotes(createNew: Bool) {
        guard character.canGiveNotes else {
            if createNew || pendingNote == .new { pendingNote = .new } else { pendingNote = .open }
            character.react(character.baseMood)
            rebuildMenu()
            return
        }
        pendingNote = nil
        if createNew { store.create() }
        if store.selected == nil || store.selected?.deletedAt != nil { store.create() }
        if !pet.isVisible { character.start() }
        pet.orderFrontRegardless()
        anchorNotes()
        notes.makeKeyAndOrderFront(nil)
        character.noteIsVisible = true
        // AppKit may finish resigning key after a close in this same event.
        // Reassert editor focus on the next turn, only if it is still visible.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.notes.isVisible else { return }
            self.notes.makeKey()
        }
        character.react(.paperOpen)
        rebuildMenu()
    }
    @objc func closeNotes() { hideNotes(preservingRequest: false) }
    func hideNotes(preservingRequest: Bool) {
        adjustingFocusTime = false
        if !preservingRequest { pendingNote = nil }
        let wasVisible = notes.isVisible
        store.flush(); notes.orderOut(nil)
        character.noteIsVisible = false
        if wasVisible { character.react(.paperClose) }
        rebuildMenu()
    }
    @objc func toggleNotes() { notes.isVisible ? closeNotes() : openNotes() }
    @objc func quickCapture() { requestNotes(createNew: true) }
    func careStateChanged() {
        store.setCare(character.care)
        if !character.canGiveNotes {
            if notes?.isVisible == true {
                if pendingNote == nil { pendingNote = .open }
                hideNotes(preservingRequest: true)
                character.react(character.baseMood)
            }
        } else if pendingNote != nil {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.character.canGiveNotes, let request = self.pendingNote else { return }
                self.requestNotes(createNew: request == .new)
            }
        }
        if status != nil { rebuildMenu() }
    }
    @objc func toggleFocus() {
        if store.focus.isActive { store.focus.togglePaused(); updateFocusRest(); rebuildMenu() }
        else { startFocus(seconds: store.focusDuration) }
    }
    func startFocus(minutes: Int) {
        startFocus(seconds: Double(minutes) * 60)
    }
    func startFocus(seconds: TimeInterval) {
        guard character.canGiveNotes else { character.react(character.baseMood); return }
        store.focusDuration = seconds
        store.focus.start(seconds: seconds)
        updateFocusRest(); rebuildMenu()
    }
    func adjustFocus(to seconds: TimeInterval) {
        guard seconds.isFinite else { return }
        let value = min(FocusSession.adjustableRange.upperBound, max(FocusSession.adjustableRange.lowerBound, seconds))
        store.focusDuration = value
        if store.focus.isActive { store.focus.adjustRemaining(to: value) }
        else if store.focus.phase == .complete { store.focus.end() }
        updateFocusRest(); rebuildMenu()
    }
    @objc func chooseFocus(_ sender: NSMenuItem) { startFocus(minutes: sender.tag) }
    @objc func endFocus() { adjustingFocusTime = false; store.focus.end(); updateFocusRest(); rebuildMenu() }
    func updateFocusRest() {
        character.focusStretchElapsed = store.focus.isStretching ? store.focus.stretchElapsed : nil
        character.focusRest = store.focus.isActive ? (store.focus.isStretching ? .stretch : .focusNap) : nil
    }
    func trashNote(_ note: Note) {
        guard note.deletedAt == nil else { return }
        store.trash(note.id)
        if store.activeCount == 0 { store.create() }
        character.react(.paperToss)
    }
    @objc func togglePet() {
        if pet.isVisible { closeNotes(); pet.orderOut(nil); character.stop() }
        else { pet.orderFrontRegardless(); character.start(); character.react(.wave) }
        rebuildMenu()
    }
    @objc func togglePaused() {
        store.setPreferences { $0.paused.toggle() }
        character.paused = store.preferences.paused
        character.needsDisplay = true
        rebuildMenu()
    }
    @objc func toggleOnTop() {
        store.setPreferences { $0.alwaysOnTop.toggle() }
        pet.level = store.preferences.alwaysOnTop ? .floating : .normal
        rebuildMenu()
    }
    @objc func centerPet() {
        let frame = NSScreen.main!.visibleFrame
        pet.setFrameOrigin(NSPoint(x: frame.maxX - 225, y: frame.minY + 38))
        pet.orderFrontRegardless(); character.start(); character.react(.wave)
        petMoved(); rebuildMenu()
    }
    @objc func showStorage() { NSWorkspace.shared.open(store.directory) }
    @objc func screenChanged() { constrainPet(); petMoved() }
    @objc func willSleep() { store.setCoffee(coffee); store.setCare(character.care); store.flush(); character.stop(); coffeeTimer?.invalidate() }
    @objc func didWake() { if pet.isVisible { character.start() }; startCoffeeClock() }
    func startCoffeeClock() {
        coffeeTimer?.invalidate()
        lastCoffeeTick = ProcessInfo.processInfo.systemUptime
        coffeeTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tickCoffeeClock() }
        coffeeTimer?.tolerance = 0.15
        RunLoop.main.add(coffeeTimer!, forMode: .common)
    }
    func tickCoffeeClock() {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = min(5, max(0, now - lastCoffeeTick))
        lastCoffeeTick = now
        advanceActivity(by: elapsed)
        if now - lastCoffeeCheckpoint >= 30 {
            store.setCoffee(coffee); store.setCare(character.care); lastCoffeeCheckpoint = now
        }
    }
    func advanceActivity(by elapsed: Double) {
        if store.focus.isActive {
            guard !adjustingFocusTime else { return }
            let finished = store.focus.advance(by: elapsed)
            updateFocusRest()
            if finished { character.react(.wakeUp) }
            rebuildMenu()
            return
        }
        guard pet.isVisible && !character.paused else { return }
        character.advanceTumble(by: elapsed)
        let wasGrumpy = coffee.needsCoffee
        coffee.advance(by: elapsed)
        if coffee.needsCoffee != wasGrumpy {
            character.wantsCoffee = coffee.needsCoffee
            store.setCoffee(coffee)
            rebuildMenu()
        }
    }
    @objc func giveCoffee() {
        guard character.mood != .coffee else { return }
        coffee.giveCoffee()
        store.setCoffee(coffee)
        character.wantsCoffee = false
        character.react(.coffee)
        rebuildMenu()
    }
    @objc func makeGrumpy() {
        coffee.makeGrumpy()
        store.setCoffee(coffee)
        character.wantsCoffee = true
        rebuildMenu()
    }
    @objc func previewMood(_ sender: NSMenuItem) {
        guard let mood = Mood(rawValue: sender.representedObject as? String ?? "") else { return }
        if mood == .annoyed { character.makeAnnoyed(); return }
        if mood == .tumble || mood == .crying { character.stumble(); return }
        if mood == .restless { character.makeRestless(); return }
        if mood == .showOff { character.showOff(); return }
        if mood == .overstimulated { character.makeOverstimulated(); return }
        if mood.isChoreography { character.chooseDance(mood); return }
        character.react(mood, duration: mood == .stretch ? FocusSession.stretchDuration : (mood.isDance ? 12 : 5))
    }
    @objc func petHead() { character.rubCrown() }
    @objc func applaudHer() { character.applaud() }
    func item(_ title: String, _ selector: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: ""); item.target = self; return item
    }
    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let heading = NSMenuItem(title: "VELVET · tiny diva, good memory", action: nil, keyEquivalent: ""); heading.isEnabled = false
        menu.addItem(heading); menu.addItem(.separator())
        menu.addItem(item("Open thoughts", #selector(openNotes)))
        menu.addItem(item("New thought    \(shortcutLabels[max(0, min(2, store.preferences.shortcut))])", #selector(quickCapture)))
        menu.addItem(item("Give her an iced latte", #selector(giveCoffee)))
        menu.addItem(item("A little head rub", #selector(petHead)))
        if character.performance.awaitingApplause { menu.addItem(item("Applaud her", #selector(applaudHer))) }
        let focusMenu = NSMenu()
        focusMenu.autoenablesItems = false
        for minutes in [15, 25, 45] {
            let choice = item("\(minutes) minutes", #selector(chooseFocus(_:)))
            choice.tag = minutes; choice.isEnabled = character.canGiveNotes; focusMenu.addItem(choice)
        }
        if store.focus.isActive {
            focusMenu.addItem(.separator())
            focusMenu.addItem(item(store.focus.phase == .paused ? "Resume" : "Pause", #selector(toggleFocus)))
            focusMenu.addItem(item("Stop focus", #selector(endFocus)))
        }
        let focus = NSMenuItem(title: store.focus.isActive ? "Focus · \(store.focus.label)" : "Focus mode", action: nil, keyEquivalent: "")
        focus.submenu = focusMenu; menu.addItem(focus)
        let dances = NSMenuItem(title: character.showsDanceChooser ? "Choose a dance · she’s restless" : "Choose a dance", action: nil, keyEquivalent: "")
        dances.submenu = character.makeDanceMenu()
        menu.addItem(dances)
        menu.addItem(item("Make her grumpy", #selector(makeGrumpy)))
        menu.addItem(.separator())
        menu.addItem(item(pet.isVisible ? "Hide Velvet" : "Show Velvet", #selector(togglePet)))
        let top = item("Always on top", #selector(toggleOnTop)); top.state = store.preferences.alwaysOnTop ? .on : .off; menu.addItem(top)
        let pause = item("Pause animations", #selector(togglePaused)); pause.state = store.preferences.paused ? .on : .off; menu.addItem(pause)
        menu.addItem(item("Bring Velvet home", #selector(centerPet)))
        let shortcuts = NSMenu()
        for i in 0..<shortcutLabels.count {
            let choice = item(shortcutLabels[i], #selector(changeShortcut(_:)))
            choice.tag = i; choice.state = i == store.preferences.shortcut ? .on : .off; shortcuts.addItem(choice)
        }
        let shortcut = NSMenuItem(title: "Quick-capture shortcut", action: nil, keyEquivalent: ""); shortcut.submenu = shortcuts; menu.addItem(shortcut)
        let moods = NSMenu()
        for mood in Mood.allCases {
            if mood == .grumpy || mood == .coffee { continue }
            let entry = item(mood.label, #selector(previewMood(_:))); entry.representedObject = mood.rawValue; moods.addItem(entry)
        }
        let animations = NSMenuItem(title: "Try a little attitude", action: nil, keyEquivalent: ""); animations.submenu = moods; menu.addItem(animations)
        menu.addItem(.separator()); menu.addItem(item("Show notes folder", #selector(showStorage)))
        let quit = NSMenuItem(title: "Quit Velvet", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"); menu.addItem(quit)
        return menu
    }
    func rebuildMenu() {
        status?.menu = makeMenu()
        if character.needsAffection { status?.button?.toolTip = "She needs affection · Stroke or hold her head to get your notes back." }
        else if coffee.needsCoffee { status?.button?.toolTip = "Iced latte. Now. · Drag the drink into her hand for your notes." }
        else if store.focus.isActive { status?.button?.toolTip = "Focus · \(store.focus.label) · \(store.focus.phase == .paused ? "paused" : (store.focus.isStretching ? "stretching" : "napping"))" }
        else if character.stimulation.overstimulated { status?.button?.toolTip = "A little quiet, please · Let her rest for thirty seconds, or start focus." }
        else if character.performance.awaitingApplause { status?.button?.toolTip = "A little applause, please · Click the 👏 beside her." }
        else if character.performance.restless { status?.button?.toolTip = "Needs a dance break · Click the 🩰 beside her to choose a dance." }
        else { status?.button?.toolTip = "Velvet · Stroke or hold her head; click for notes." }
    }
    func installHotKeyHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { delegate.quickCapture() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &hotKeyHandler)
    }
    @discardableResult func registerShortcut(_ index: Int) -> Bool {
        let i = max(0, min(2, index))
        if let hotKey { UnregisterEventHotKey(hotKey); self.hotKey = nil }
        let id = EventHotKeyID(signature: OSType(0x564C5654), id: 1)
        let result = RegisterEventHotKey(shortcutCodes[i], shortcutModifiers[i], id, GetApplicationEventTarget(), 0, &hotKey)
        if result != noErr {
            let alert = NSAlert(); alert.messageText = "That shortcut is already taken."
            alert.informativeText = "Choose another quick-capture shortcut from Velvet's menu. Notes still open when you click Velvet."
            alert.runModal(); return false
        }
        return true
    }
    @objc func changeShortcut(_ sender: NSMenuItem) {
        let old = store.preferences.shortcut
        if registerShortcut(sender.tag) { store.setPreferences { $0.shortcut = sender.tag } }
        else { _ = registerShortcut(old) }
        rebuildMenu()
    }
    func export(_ note: Note) {
        let panel = NSSavePanel()
        panel.title = "Export your thought"
        panel.nameFieldStringValue = String(note.displayTitle.prefix(80)).replacingOccurrences(of: "/", with: "-") + ".md"
        panel.beginSheetModal(for: notes) { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }
            do { try self.store.markdown(note).write(to: url, atomically: true, encoding: .utf8) }
            catch { let alert = NSAlert(error: error); alert.beginSheetModal(for: self.notes) }
        }
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        store.setCoffee(coffee)
        store.setCare(character.care)
        store.setPreferences { $0.x = Double(pet.frame.minX); $0.y = Double(pet.frame.minY) }
        if !store.flush() {
            let alert = NSAlert()
            alert.messageText = "Your latest changes haven't been saved."
            alert.informativeText = store.saveError ?? "Velvet couldn't write your notes."
            alert.addButton(withTitle: "Keep Velvet open"); alert.addButton(withTitle: "Quit anyway")
            if alert.runModal() == .alertFirstButtonReturn { return .terminateCancel }
        }
        character.stop()
        coffeeTimer?.invalidate()
        if let hotKey { UnregisterEventHotKey(hotKey) }
        return .terminateNow
    }

    func renderPreview(to directory: URL) {
        character.onNeedsChanged = nil
        character.care = CompanionCare()
        character.focusRest = nil
        character.noteIsVisible = true
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        character.wantsCoffee = false
        for mood in Mood.allCases {
            if mood == .showOff { character.showOff() }
            character.mood = mood; character.paused = true; character.previewTime = mood == .idle ? 1 : 0.2
            character.syncCompanionButtons()
            let bitmap = character.bitmapImageRepForCachingDisplay(in: character.bounds)!
            character.cacheDisplay(in: character.bounds, to: bitmap)
            if let data = bitmap.representation(using: .png, properties: [:]) {
                try? data.write(to: directory.appendingPathComponent("\(mood.rawValue).png"))
            }
            if mood.isDance || mood == .coffee {
                for i in 0..<(mood == .coffee ? 6 : 4) {
                    switch mood {
                    case .disco: character.previewTime = Double(i) * 0.65 + 0.2
                    case .house: character.previewTime = Double(i) * 0.28 + 0.05
                    case .waacking: character.previewTime = Double(i) * 0.24 + 0.05
                    default: character.previewTime = Double(i) * (mood == .coffee ? 0.8 : 0.4) + (mood == .coffee ? 0.2 : 0.05)
                    }
                    let frame = character.bitmapImageRepForCachingDisplay(in: character.bounds)!
                    character.cacheDisplay(in: character.bounds, to: frame)
                    if let data = frame.representation(using: .png, properties: [:]) {
                        try? data.write(to: directory.appendingPathComponent("\(mood.rawValue)-\(i).png"))
                    }
                }
            }
            if mood == .coffee {
                for (label, time) in [("transition", 1.68), ("nod", 4.95), ("wink", 5.7), ("finish", 5.8)] {
                    character.previewTime = time
                    let frame = character.bitmapImageRepForCachingDisplay(in: character.bounds)!
                    character.cacheDisplay(in: character.bounds, to: frame)
                    if let data = frame.representation(using: .png, properties: [:]) {
                        try? data.write(to: directory.appendingPathComponent("coffee-\(label).png"))
                    }
                }
            }
            if mood == .zoomies {
                for (i, time) in [0.1, 0.7, 1.3, 2.2, 3.1, 4.0, 5.1, 5.9, 7.0, 7.9].enumerated() {
                    character.previewTime = time
                    let frame = character.bitmapImageRepForCachingDisplay(in: character.bounds)!
                    character.cacheDisplay(in: character.bounds, to: frame)
                    if let data = frame.representation(using: .png, properties: [:]) {
                        try? data.write(to: directory.appendingPathComponent("zoomies-sequence-\(i).png"))
                    }
                }
            }
            if mood.isPaper || [.affection, .annoyed, .stretch, .focusNap, .wakeUp, .tumble, .crying, .recover, .restless, .takeBow, .overstimulated].contains(mood) {
                let times: [Double]
                switch mood {
                case .paperOpen: times = [0.2, 0.6, 1.0]
                case .paperClose: times = [0.2, 0.8]
                case .paperToss: times = [0.2, 0.48, 0.8, 1.2]
                case .affection: times = [0.2, 0.6, 1.0]
                case .stretch: times = [0.2, 2.3, 4.5, 6.8, 8.2, 9.8, 11.7, 13.4]
                case .focusNap: times = [0.2, 7.2]
                case .wakeUp: times = [0.2, 0.7, 1.3, 1.9, 2.7, 3.3, 3.8]
                case .tumble: times = [0.2, 0.6]
                case .recover: times = [0.2, 0.8]
                case .restless: times = [0.2, 0.55, 0.9]
                case .takeBow: times = [0.2, 0.9, 1.5]
                case .overstimulated: times = [0.2, 4, 15]
                default: times = [0.2, 1.8]
                }
                for (i, time) in times.enumerated() {
                    character.previewTime = time
                    let frame = character.bitmapImageRepForCachingDisplay(in: character.bounds)!
                    character.cacheDisplay(in: character.bounds, to: frame)
                    if let data = frame.representation(using: .png, properties: [:]) {
                        try? data.write(to: directory.appendingPathComponent("\(mood.rawValue)-\(i).png"))
                    }
                }
            }
        }
        character.wantsCoffee = true
        for (label, progress) in [("reaching", 0.5), ("handoff", 1.0)] {
            character.stop(); character.mood = .grumpy; character.previewTime = 0.2
            let cup = NSPoint(x: character.coffeeButtonRect.midX, y: character.coffeeButtonRect.midY)
            let hand = NSPoint(x: character.latteHandRect.midX, y: character.latteHandRect.midY)
            let target = NSPoint(x: cup.x + (hand.x - cup.x) * progress, y: cup.y + (hand.y - cup.y) * progress)
            let now = ProcessInfo.processInfo.systemUptime
            character.beginPointer(at: cup, screenPoint: cup, time: now)
            character.updatePointer(at: target, screenPoint: target, time: now + 0.3)
            let frame = character.bitmapImageRepForCachingDisplay(in: character.bounds)!
            character.cacheDisplay(in: character.bounds, to: frame)
            if let data = frame.representation(using: .png, properties: [:]) {
                try? data.write(to: directory.appendingPathComponent("latte-\(label).png"))
            }
        }
        character.stop(); character.wantsCoffee = false
    }
    func checkResponses(completion: @escaping ([String: Any]) -> Void) {
        var checks: [String: Any] = [:]
        character.mood = .idle; character.moodUntil = .distantPast
        giveCoffee(); openNotes()
        character.advanceResponses(by: 8)
        checks["zoomiesWaitForSip"] = character.mood == .coffee && character.responses.latteWaiting
        character.moodUntil = .distantPast
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            checks["paperBeforeZoomies"] = character.mood == .paperOpen && character.responses.latteWaiting && notes.isVisible
            character.moodUntil = .distantPast
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
                checks["latteStartsZoomies"] = character.mood == .zoomies && character.responses.phase == .zoomies
                character.advanceResponses(by: 2.2)
                checks["latteZoomiesUseHouseInsteadOfVogue"] = (60...63).contains(character.displayedSpriteIndex ?? -1)
                openNotes()
                let zoomTime = character.responses.zoomiesRemaining
                character.advanceResponses(by: 8)
                checks["notesInterruptZoomiesImmediately"] = notes.isVisible && character.mood == .paperOpen && character.responses.zoomiesRemaining == zoomTime
                character.moodUntil = .distantPast
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
                    checks["zoomiesResumeAfterPaper"] = character.mood == .zoomies && character.responses.zoomiesRemaining > 0
                    character.advanceResponses(by: 8)
                    checks["zoomiesSettle"] = character.responses.phase != .zoomies && character.mood != .zoomies
                    character.react(.zoomies)
                    startFocus(minutes: 25)
                    checks["focusCancelsZoomies"] = character.mood == .stretch && !character.responses.latteWaiting && character.responses.zoomiesRemaining == 0
                    endFocus()
                    character.makeAnnoyed(); character.rubCrown()
                    checks["comfortStartsReconciliation"] = character.hasGentleResponse && character.mood == .affection && !character.needsAffection
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
                        character.mood = .reconcile; character.moodUntil = .distantFuture
                        character.advanceResponses(by: 12)
                        checks["reconciliationSmilesBesideNote"] = character.mood == .shySmile && character.noteIsVisible && notes.isVisible && abs(character.noteDirection) == 1
                        let gentleTime = character.responses.reconciliationRemaining
                        character.paused = true; character.advanceResponses(by: 20)
                        checks["pauseFreezesGentleResponse"] = character.responses.reconciliationRemaining == gentleTime
                        character.paused = false; startFocus(minutes: 25); character.advanceResponses(by: 20)
                        checks["focusPreservesQuietReconciliation"] = character.mood == .stretch && character.responses.reconciliationRemaining == gentleTime
                        endFocus()
                        character.makeAnnoyed()
                        checks["newUpsetOverridesReconciliation"] = !character.hasGentleResponse && !character.canGiveNotes && !notes.isVisible
                        character.rubCrown()
                        character.mood = .reconcile; character.moodUntil = .distantFuture
                        character.advanceResponses(by: 90)
                        checks["reconciliationExpires"] = !character.hasGentleResponse && character.mood == .idle
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { completion(checks) }
                    }
                }
            }
        }
    }
    func checkFocusControls(previewDirectory: URL, completion: @escaping ([String: Any]) -> Void) {
        var checks: [String: Any] = [:]
        // Verify stop against a deliberately opened note, independently of
        // the preceding care check's asynchronous note restoration.
        openNotes()
        let noteID = store.selectedID, body = store.selected?.body
        character.mood = .idle; character.moodUntil = .distantPast
        startFocus(minutes: 25)
        func capture(_ name: String) {
            guard let view = notes.contentView, let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            try? bitmap.representation(using: .png, properties: [:])?.write(to: previewDirectory.appendingPathComponent(name))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            capture("focus-running-preview.png")
            checks["focusHasVisibleStretch"] = character.mood == .stretch && store.focus.isStretching
            toggleFocus()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
                capture("focus-paused-preview.png")
                endFocus()
                checks["stopPausedFocus"] = !store.focus.isActive && store.focus.phase == .inactive && character.focusRest == nil
                startFocus(minutes: 15); endFocus()
                checks["stopRunningFocus"] = store.focus.phase == .inactive && character.focusRest == nil
                checks["stopPreservesNotes"] = notes.isVisible && store.selectedID == noteID && store.selected?.body == body
                character.react(.disco)
                checks["discoRoutineLoaded"] = character.hasDiscoAnimation && character.mood == .disco
                startFocus(minutes: 25); character.react(.disco)
                checks["discoRespectsFocus"] = character.mood == .stretch
                endFocus(); makeGrumpy(); character.react(.disco)
                checks["discoRespectsCoffee"] = character.mood == .grumpy && !character.canGiveNotes
                giveCoffee()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { completion(checks) }
            }
        }
    }
    func checkPerformance(previewDirectory: URL, completion: @escaping ([String: Any]) -> Void) {
        var checks: [String: Any] = [:]
        let position = pet.frame.origin
        let originalChance = character.applauseChance
        checks["applauseHasFifteenPercentChance"] = originalChance == 0.15
        character.applauseChance = 1 // Make this branch deterministic; check the zero-chance branch below.
        func capture(_ name: String) -> Data? {
            guard let bitmap = character.bitmapImageRepForCachingDisplay(in: character.bounds) else { return nil }
            character.cacheDisplay(in: character.bounds, to: bitmap)
            let data = bitmap.representation(using: .png, properties: [:])
            try? data?.write(to: previewDirectory.appendingPathComponent(name))
            return data
        }
        let steps: [() -> Void] = [
            { [self] in
                character.mood = .idle; character.moodUntil = .distantPast
                character.stop(); character.advanceResponses(by: 8); character.start()
            },
            { [self] in
                character.makeRestless()
                checks["restlessUsesFidgetMood"] = character.mood == .restless && character.performance.restless
                checks["restlessKeepsNotesAvailable"] = character.canGiveNotes
                let button = NSPoint(x: character.applauseButtonRect.midX, y: character.applauseButtonRect.midY)
                checks["restlessShowsClickableDanceChooser"] = character.showsDanceChooser && character.interactiveArea(button) && character.hitTest(button) is NSButton
                checks["danceMenuOffersSixClearChoices"] = character.makeDanceMenu().items.map(\.title) == ["Ballet", "Floorwork", "Vogue Fem", "Robot disco", "House", "Waacking"]
                checks["contextMenuClearlyOffersDanceChooser"] = makeMenu().items.contains { $0.title == "Choose a dance · she’s restless" && $0.submenu?.items.count == 6 }
                _ = capture("restless-preview.png")
                openNotes()
                checks["restlessCanOpenNotes"] = notes.isVisible && character.performance.restless
                character.moodUntil = .distantPast
            },
            { [self] in
                checks["restlessReturnsAfterPaper"] = character.mood == .restless
                character.makeDanceMenu().performActionForItem(at: 3)
                checks["chosenDanceStartsWithoutPrematureRelief"] = character.mood == .disco && character.performance.restless && !character.showsDanceChooser
                character.moodUntil = .distantPast
            },
            { [self] in
                checks["completedDanceSettlesAndHoldsFinish"] = !character.performance.restless && character.performance.awaitingApplause && character.mood == .showOff
                checks["heldFinishOffersApplauseMenu"] = makeMenu().items.contains { $0.title == "Applaud her" }
                let original = capture("held-finish-preview.png")
                character.previewTime = 120
                checks["heldFinishStaysStill"] = original != nil && original == capture("held-finish-later-preview.png")
                character.previewTime = nil
                let head = NSPoint(x: character.crownRect.midX, y: character.crownRect.midY)
                let now = ProcessInfo.processInfo.systemUptime
                let visible = notes.isVisible
                character.beginPointer(at: head, screenPoint: head, time: now)
                character.endPointer(at: head, time: now + 0.1)
                checks["headTapStillTogglesNotesWhileWaiting"] = character.performance.awaitingApplause && pet.frame.origin == position && notes.isVisible != visible
                character.moodUntil = .distantPast
            },
            { [self] in
                let clap = NSPoint(x: character.applauseButtonRect.midX, y: character.applauseButtonRect.midY)
                checks["applauseEmojiVisibleAndClickable"] = character.showsApplause && character.interactiveArea(clap) && character.hitTest(clap) is NSButton
                let visible = notes.isVisible
                character.clickApplauseButton()
                checks["emojiApplaudsWithoutMovingOrTogglingNotes"] = !character.performance.awaitingApplause && character.mood == .takeBow && pet.frame.origin == position && notes.isVisible == visible && !character.showsApplause
                _ = capture("bow-preview.png")
                openNotes()
                checks["notesOpenWhileTakingBow"] = notes.isVisible && character.mood == .takeBow
                character.moodUntil = .distantPast
            },
            { [self] in
                checks["paperGestureFollowsBow"] = character.mood == .paperOpen
                character.moodUntil = .distantPast
            },
            { [self] in
                character.makeRestless(); character.chooseDance(.ballet)
                startFocus(minutes: 25)
                checks["focusInterruptsDanceWithoutSettlingNeed"] = character.performance.restless && !character.performance.awaitingApplause && character.mood == .stretch
                checks["focusHidesAndDisablesDanceChooser"] = !character.showsDanceChooser && character.makeDanceMenu().items.allSatisfy { !$0.isEnabled }
                let remaining = character.performance.timeUntilRestless
                character.advancePerformance(by: 1000)
                checks["focusPausesPerformanceClock"] = character.performance.timeUntilRestless == remaining
                endFocus()
                checks["restlessnessReturnsAfterFocus"] = character.mood == .restless
                character.showOff(); openNotes()
                checks["heldFinishKeepsNotesAvailable"] = notes.isVisible && character.canGiveNotes && character.performance.awaitingApplause
                character.moodUntil = .distantPast
            },
            { [self] in
                checks["heldFinishReturnsAfterPaper"] = character.mood == .showOff && character.performance.awaitingApplause
                // Force the body gesture explicitly, independently of the held pose's silhouette.
                let point = NSPoint(x: 95, y: 180), now = ProcessInfo.processInfo.systemUptime
                let visible = notes.isVisible
                character.beginPointer(at: point, screenPoint: point, time: now, forceMove: true)
                character.endPointer(at: point, time: now + 0.1)
                checks["bodyTapStillTogglesNotesWhileWaiting"] = character.performance.awaitingApplause && pet.frame.origin == position && notes.isVisible != visible
                openNotes()
                character.moodUntil = .distantPast
            },
            { [self] in
                character.showOff(); startFocus(minutes: 25)
                checks["focusCancelsHeldApplause"] = !character.performance.awaitingApplause && character.mood == .stretch
                endFocus(); character.showOff(); makeGrumpy()
                checks["coffeeOverridesHeldFinish"] = !character.performance.awaitingApplause && !character.canGiveNotes && !notes.isVisible && character.mood == .grumpy
                character.chooseDance(.vogue)
                checks["danceCannotBypassCoffeeNeed"] = character.mood == .grumpy && !character.canGiveNotes
                giveCoffee(); character.makeAnnoyed()
                checks["applauseCannotBypassAffectionNeed"] = !character.applaud() && character.needsAffection && !character.canGiveNotes
                character.rubCrown()
                character.mood = .idle; character.moodUntil = .distantPast
            },
            { [self] in
                openNotes()
                checks["notesRemainUsableAfterPerformanceChecks"] = notes.isVisible && character.canGiveNotes
                character.mood = .idle; character.moodUntil = .distantPast
                character.stop(); character.start()
                character.applauseChance = 0
                character.makeRestless(); character.chooseDance(.house)
                checks["houseRoutineLoadsAndStarts"] = character.hasClubAnimation && character.mood == .house && (60...63).contains(character.displayedSpriteIndex ?? -1)
                character.moodUntil = .distantPast
            },
            { [self] in
                checks["chosenDanceCanFinishWithoutApplause"] = !character.performance.restless && !character.performance.awaitingApplause && character.mood != .showOff
                character.chooseDance(.waacking)
                checks["waackingRoutineLoadsAndStarts"] = character.mood == .waacking && (64...67).contains(character.displayedSpriteIndex ?? -1)
                checks["houseAutomaticVogueAndWaackingChoiceOnly"] = Mood.automaticDances.contains(.house) && !Mood.automaticDances.contains(.vogue) && !Mood.automaticDances.contains(.waacking)
                character.react(.idle)
                character.previewTime = 1
                checks["terminalVisorExpressionLoaded"] = character.displayedSpriteIndex == 56
                character.previewTime = nil
            }
        ]
        func runStep(_ index: Int) {
            guard index < steps.count else { character.applauseChance = originalChance; completion(checks); return }
            steps[index]()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { runStep(index + 1) }
        }
        runStep(0)
    }
    func checkQuietAndNoteReturn(completion: @escaping ([String: Any]) -> Void) {
        var checks: [String: Any] = [:]
        let steps: [() -> Void] = [
            { [self] in
                closeNotes(); character.mood = .idle; character.moodUntil = .distantPast
                character.stop(); character.advanceResponses(by: 90); character.start()
                character.makeAnnoyed()
                let head = NSPoint(x: character.crownRect.midX, y: character.crownRect.midY)
                let now = ProcessInfo.processInfo.systemUptime
                character.beginPointer(at: head, screenPoint: head, time: now)
                character.endPointer(at: head, time: now + 0.1)
                checks["upsetHeadTapDoesNotRequestNotes"] = pendingNote == nil && !notes.isVisible
                character.beginPointer(at: head, screenPoint: head, time: now + 1)
                character.endPointer(at: head, time: now + 1.4)
            },
            { [self] in
                checks["affectionKeepsPreviouslyClosedNotesClosed"] = !notes.isVisible && pendingNote == nil && !character.needsAffection
                character.stumble()
                let head = NSPoint(x: character.crownRect.midX, y: character.crownRect.midY)
                let now = ProcessInfo.processInfo.systemUptime
                character.beginPointer(at: head, screenPoint: head, time: now)
                character.endPointer(at: head, time: now + 0.4)
            },
            { [self] in
                checks["comfortKeepsPreviouslyClosedNotesClosed"] = !notes.isVisible && pendingNote == nil && !character.needsAffection
                character.makeAnnoyed(); openNotes(); closeNotes(); character.rubCrown()
            },
            { [self] in
                checks["dismissedPendingRequestStaysDismissed"] = !notes.isVisible && pendingNote == nil
                openNotes(); character.makeAnnoyed(); character.rubCrown()
            },
            { [self] in
                checks["affectionStillRestoresConfiscatedNotes"] = notes.isVisible && pendingNote == nil && character.canGiveNotes
                closeNotes(); character.stimulation = StimulationState()
                for _ in 0..<6 { character.rubCrown() }
                checks["repeatedFussingTriggersOverstimulation"] = character.stimulation.overstimulated && character.mood == .overstimulated
                checks["overstimulationDoesNotOpenNotes"] = !notes.isVisible && pendingNote == nil
                character.chooseDance(.ballet)
                checks["overstimulationDeclinesDances"] = character.mood == .overstimulated
                character.advanceStimulation(by: 10)
                character.rubCrown()
                checks["moreFussingRestartsQuietRecovery"] = character.stimulation.quietRemaining == StimulationState.recoveryDuration
                character.paused = true
                character.advanceStimulation(by: 100)
                checks["pauseFreezesQuietRecovery"] = character.stimulation.overstimulated
                character.paused = false
                character.mood = .overstimulated; character.moodUntil = .distantFuture
                openNotes()
                checks["notesUsableDuringOverstimulation"] = notes.isVisible && character.canGiveNotes
                character.moodUntil = .distantPast
            },
            { [self] in
                checks["quietMoodReturnsAfterPaper"] = character.mood == .overstimulated
                character.react(.zoomies); character.advanceResponses(by: 1)
                checks["overstimulationSuppressesZoomies"] = character.mood == .overstimulated && !character.responses.latteWaiting && character.responses.zoomiesRemaining == 0
                startFocus(minutes: 25)
                checks["focusProvidesQuietWhileOverstimulated"] = character.mood == .stretch && character.stimulation.overstimulated
                character.advanceStimulation(by: 30)
                checks["quietFocusResolvesOverstimulation"] = !character.stimulation.overstimulated && character.mood == .stretch && store.focus.isActive
                endFocus()
                let shadow = character.groundShadowRect
                let point = NSPoint(x: shadow.midX, y: shadow.midY)
                if let bitmap = character.bitmapImageRepForCachingDisplay(in: character.bounds) {
                    character.cacheDisplay(in: character.bounds, to: bitmap)
                    let x = Int(point.x * Double(bitmap.pixelsWide) / character.bounds.width)
                    let y = Int(point.y * Double(bitmap.pixelsHigh) / character.bounds.height)
                    let alpha = bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0
                    checks["groundShadowHasSoftVisibleAlpha"] = alpha > 0 && alpha < 0.5
                }
                checks["groundShadowPassesThroughClicks"] = !character.interactiveArea(NSPoint(x: shadow.midX, y: shadow.maxY - 0.5))
                openNotes()
            }
        ]
        func runStep(_ index: Int) {
            guard index < steps.count else { completion(checks); return }
            steps[index]()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { runStep(index + 1) }
        }
        runStep(0)
    }
    func checkFocusScrubbing(completion: @escaping ([String: Any]) -> Void) {
        var checks: [String: Any] = [:]
        var timer: FocusTimerControl?
        let noteID = store.selectedID, noteBody = store.selected?.body
        func findTimer(_ view: NSView) -> FocusTimerControl? {
            if let control = view as? FocusTimerControl { return control }
            for child in view.subviews { if let found = findTimer(child) { return found } }
            return nil
        }
        endFocus(); store.focusDuration = 1500; openNotes()
        character.mood = .idle; character.moodUntil = .distantPast
        let steps: [() -> Void] = [
            { [self] in
                timer = notes.contentView.flatMap { findTimer($0) }
                checks["nativeScrubbableTimerFound"] = timer != nil
                guard let timer else { return }
                checks["timerHasActualHitRegion"] = timer.hitTest(NSPoint(x: timer.bounds.midX, y: timer.bounds.midY)) === timer
                timer.beginInteraction(y: 100); timer.updateInteraction(y: 130)
                checks["timerDragUpAdjustsBeforeStarting"] = store.focusDuration == 1800 && !store.focus.isActive
                timer.finishInteraction()
                checks["timerDragReleaseDoesNotStartOrToggle"] = !store.focus.isActive && !adjustingFocusTime
            },
            { [self] in
                guard let timer else { return }
                timer.beginInteraction(y: 100); timer.finishInteraction()
                checks["timerClickStartsChosenDuration"] = store.focus.phase == .running && store.focus.remaining == 1800
                advanceActivity(by: 4)
                checks["focusActuallyTriesSplits"] = character.hasStretchAnimation && character.mood == .stretch && character.displayedSpriteIndex == 70
                advanceActivity(by: 7)
                checks["focusActuallyTriesPancake"] = character.displayedSpriteIndex == 74
            },
            { [self] in
                guard let timer else { return }
                let remaining = store.focus.remaining, elapsed = store.focus.elapsed
                timer.beginInteraction(y: 100); timer.updateInteraction(y: 112)
                checks["timerDragAdjustsRunningTimeWithoutResettingStretch"] = store.focus.remaining == remaining + 120 && store.focus.elapsed == elapsed && character.displayedSpriteIndex == 74
                let whileDragging = store.focus.remaining
                advanceActivity(by: 100)
                checks["countdownDoesNotFightActiveDrag"] = store.focus.remaining == whileDragging && adjustingFocusTime
                timer.finishInteraction()
                checks["runningDragReleaseDoesNotPause"] = store.focus.phase == .running && !adjustingFocusTime
            },
            { [self] in
                guard let timer else { return }
                timer.beginInteraction(y: 100); timer.finishInteraction()
                checks["timerClickStillPauses"] = store.focus.phase == .paused && character.mood == .focusNap
            },
            { [self] in
                guard let timer else { return }
                let remaining = store.focus.remaining
                timer.beginInteraction(y: 100); timer.updateInteraction(y: 82); timer.finishInteraction()
                checks["timerDragDownAdjustsPausedTime"] = store.focus.remaining == remaining - 180 && store.focus.phase == .paused
                let pausedTime = store.focus.remaining
                advanceActivity(by: 100)
                checks["adjustedPausedTimerStaysPaused"] = store.focus.remaining == pausedTime
            },
            { [self] in
                guard let timer else { return }
                timer.beginInteraction(y: 100); timer.finishInteraction()
                checks["timerClickStillResumes"] = store.focus.phase == .running
                advanceActivity(by: 3)
                checks["newStretchRoutineStillEndsInNap"] = character.mood == .focusNap && store.focus.elapsed >= 14
                endFocus()
                checks["scrubbingAndStopPreserveNote"] = notes.isVisible && store.selectedID == noteID && store.selected?.body == noteBody && !adjustingFocusTime
            }
        ]
        func runStep(_ index: Int) {
            guard index < steps.count else {
                closeNotes(); startFocus(seconds: 60); advanceActivity(by: 60)
                checks["focusCompletionStartsWakeWithoutOpeningNotes"] = character.mood == .wakeUp && !notes.isVisible && store.focus.phase == .complete
                let samples = [0.2, 0.7, 1.3, 1.9, 2.7, 3.3, 3.8]
                let frames = samples.map { time -> Int? in
                    character.previewTime = time
                    return character.displayedSpriteIndex
                }
                checks["wakeSequenceUncurlsStretchesAndBlinks"] = frames == [46, 47, 75, 45, 44, 1, 56]
                character.previewTime = nil
                openNotes()
                checks["notesRemainAvailableDuringWake"] = notes.isVisible && store.selectedID == noteID && store.selected?.body == noteBody && character.mood == .wakeUp
                closeNotes()
                DispatchQueue.main.asyncAfter(deadline: .now() + FocusSession.wakeDuration + 0.3) { [self] in
                    checks["wakeFinishesAndKeepsClosedNotesClosed"] = character.mood != .wakeUp && !notes.isVisible && store.selectedID == noteID && store.selected?.body == noteBody
                    character.react(.wakeUp); startFocus(seconds: 60)
                    checks["newFocusInterruptsWakeWithStretch"] = character.mood == .stretch && store.focus.isActive
                    endFocus(); openNotes()
                    completion(checks)
                }
                return
            }
            steps[index]()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { runStep(index + 1) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { runStep(0) }
    }
    func runSmokeTest(to url: URL) {
        coffee = CoffeeState(); character.wantsCoffee = false
        character.care = CompanionCare(timeUntilTumble: 3000)
        character.stimulation = StimulationState(cooldown: 60)
        character.paused = false; character.previewTime = nil
        pendingNote = nil; endFocus(); openNotes()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            func findEditor(_ view: NSView) -> NSTextView? {
                if let editor = view as? EditorTextView { return editor }
                for child in view.subviews { if let found = findEditor(child) { return found } }
                return nil
            }
            var checks: [String: Any] = [:]
            let editor = findEditor(notes.contentView!)
            checks["petVisible"] = pet.isVisible
            checks["petCannotBecomeKey"] = !pet.canBecomeKey
            checks["editorFound"] = editor != nil
            checks["globalShortcutRegistered"] = hotKey != nil
            checks["transparentCorner"] = !character.interactiveArea(.zero)
            checks["spriteFramesLoaded"] = character.spriteFrameCount
            checks["wellbeingSpritesLoaded"] = character.hasWellbeingAnimation
            checks["paperOpens"] = character.mood == .paperOpen
            closeNotes()
            checks["paperCloses"] = character.mood == .paperClose && !notes.isVisible
            openNotes()
            let disposable = store.create()
            store.update(disposable, body: "Paper choreography verification")
            trashNote(store.selected!)
            checks["paperTosses"] = character.mood == .paperToss && store.archive.notes.first(where: { $0.id == disposable })?.deletedAt != nil
            store.restore(disposable)
            checks["tossedNoteRecoverable"] = store.selected?.body == "Paper choreography verification"
            makeGrumpy()
            checks["coffeeHidesNotes"] = !notes.isVisible && !character.canGiveNotes && character.mood == .grumpy
            let count = store.activeCount
            openNotes(); quickCapture()
            checks["coffeeBlocksAllCapture"] = !notes.isVisible && store.activeCount == count && pendingNote == .new
            let now = ProcessInfo.processInfo.systemUptime
            let cup = NSPoint(x: character.coffeeButtonRect.midX, y: character.coffeeButtonRect.midY)
            checks["cupClickable"] = character.interactiveArea(cup)
            let position = pet.frame.origin
            character.beginPointer(at: cup, screenPoint: cup, time: now)
            let miss = NSPoint(x: 179, y: 80)
            character.updatePointer(at: miss, screenPoint: miss, time: now + 0.1)
            character.endPointer(at: miss, time: now + 0.2)
            checks["missedLatteDoesNotFeed"] = coffee.needsCoffee && !character.isCarryingLatte && pet.frame.origin == position
            for i in 0..<4 { character.pokeCrown(at: now + Double(i) * 0.2) }
            checks["fourPokesCrossArms"] = character.care.upset == .annoyed && character.mood == .annoyed
            let head = NSPoint(x: character.crownRect.midX, y: character.crownRect.midY)
            checks["wholeHeadPettable"] = character.interactiveArea(head)
            character.beginPointer(at: head, screenPoint: head, time: now + 1)
            let stroke = NSPoint(x: head.x + 10, y: head.y)
            character.updatePointer(at: stroke, screenPoint: stroke, time: now + 1.1)
            character.endPointer(at: stroke, time: now + 1.15)
            checks["shortHeadStrokeSoothesWithoutMoving"] = !character.needsAffection && character.mood == .affection && pet.frame.origin == position
            checks["affectionDoesNotReplaceCoffee"] = coffee.needsCoffee && !notes.isVisible && !character.canGiveNotes
            character.makeAnnoyed()
            giveCoffee()
            checks["coffeeDoesNotReplaceAffection"] = !coffee.needsCoffee && character.needsAffection && !notes.isVisible
            character.rubCrown()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
                checks["notesReturnedAfterBothNeedsMet"] = notes.isVisible && character.canGiveNotes && store.activeCount == count + 1
                character.stumble()
                checks["tumbleHidesNotes"] = !notes.isVisible && character.care.upset == .crying && character.mood == .tumble
                openNotes(); quickCapture()
                let cryingCount = store.activeCount
                checks["cryingBlocksCapture"] = !notes.isVisible && !character.canGiveNotes
                character.react(.wave)
                checks["cryingCannotBeDismissedWithDanceOrWave"] = character.mood == .crying
                let fallenHead = NSPoint(x: character.crownRect.midX, y: character.crownRect.midY)
                checks["fallenHeadPettable"] = character.interactiveArea(fallenHead)
                character.beginPointer(at: fallenHead, screenPoint: fallenHead, time: now + 2)
                character.endPointer(at: fallenHead, time: now + 2.4)
                checks["headHoldComfortsAndKeepsStill"] = !character.needsAffection && character.mood == .recover && pet.frame.origin == position
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
                    checks["cryingNotesReturned"] = notes.isVisible && store.activeCount == cryingCount + 1
                    // Let care finish, then use real views with accelerated session time.
                    character.mood = .idle; character.moodUntil = .distantPast
                    startFocus(minutes: 25)
                    checks["focusStartsWithStretch"] = store.focus.label == "25:00" && character.focusRest == .stretch && character.mood == .stretch
                    let beforeCoffee = coffee.awakeSeconds
                    let beforeTumble = character.care.timeUntilTumble
                    advanceActivity(by: 14)
                    checks["focusNapsAfterStretch"] = character.focusRest == .focusNap && character.mood == .focusNap
                    character.react(.vogue)
                    checks["focusSuppressesDancing"] = character.mood == .focusNap
                    toggleFocus()
                    let remaining = store.focus.remaining
                    advanceActivity(by: 100)
                    checks["focusPauseFreezesClock"] = store.focus.remaining == remaining && store.focus.phase == .paused
                    toggleFocus(); advanceActivity(by: 166)
                    checks["focusPeriodicStretch"] = character.focusRest == .stretch
                    checks["focusPausesCareClocks"] = coffee.awakeSeconds == beforeCoffee && character.care.timeUntilTumble == beforeTumble
                    advanceActivity(by: 1320)
                    checks["focusCompletes"] = store.focus.phase == .complete && character.focusRest == nil && character.mood == .wakeUp
                    endFocus()
                    character.mood = .idle; character.moodUntil = .distantPast
                    character.care.timeUntilTumble = 1
                    character.mood = .sleep
                    advanceActivity(by: 1)
                    checks["sleepPausesTumbles"] = !character.needsAffection && character.care.timeUntilTumble == 1
                    character.mood = .idle
                    advanceActivity(by: 1)
                    checks["rareTumbleTriggersWhenEligible"] = character.care.upset == .crying && !notes.isVisible
                    character.rubCrown()
                    // Explicit movement is available from any head position with Option.
                    let movingHead = NSPoint(x: character.crownRect.midX, y: character.crownRect.midY)
                    character.beginPointer(at: movingHead, screenPoint: movingHead, time: now + 3, forceMove: true)
                    character.updatePointer(at: movingHead, screenPoint: NSPoint(x: movingHead.x + 12, y: movingHead.y), time: now + 3.1)
                    // Gesture movement is measured in view coordinates, as AppKit delivers it.
                    let movedHead = NSPoint(x: movingHead.x + 12, y: movingHead.y)
                    character.updatePointer(at: movedHead, screenPoint: movedHead, time: now + 3.2)
                    checks["optionDragMoves"] = pet.frame.origin != position
                    character.endPointer(at: movedHead, time: now + 3.3)
                    pet.setFrameOrigin(position); anchorNotes()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                        checks["notesVisible"] = notes.isVisible
                        checks["editorFocused"] = editor != nil && notes.firstResponder === editor
                        checks["notesKey"] = notes.isKeyWindow
                        checks["notesWithinScreen"] = notes.screen?.visibleFrame.contains(notes.frame) ?? false
                        checks["ruledLineHeight"] = editor?.defaultParagraphStyle?.minimumLineHeight ?? 0
                        checks["noteFont"] = editor?.font?.fontName ?? "missing"
                        checks["saveSucceeded"] = store.flush()
                        checkResponses { [self] responseChecks in
                        checks.merge(responseChecks) { _, new in new }
                        checkFocusControls(previewDirectory: url.deletingLastPathComponent()) { [self] focusChecks in
                        checks.merge(focusChecks) { _, new in new }
                        checkPerformance(previewDirectory: url.deletingLastPathComponent()) { [self] performanceChecks in
                        checks.merge(performanceChecks) { _, new in new }
                        checkQuietAndNoteReturn { [self] quietChecks in
                        checks.merge(quietChecks) { _, new in new }
                        checkFocusScrubbing { [self] timerChecks in
                        checks.merge(timerChecks) { _, new in new }
                        checks["editorFocused"] = editor != nil && notes.firstResponder === editor
                        checks["notesKey"] = notes.isKeyWindow
                        checks["notesVisible"] = notes.isVisible
                        checks["saveSucceeded"] = store.flush()
                        if let data = try? JSONSerialization.data(withJSONObject: checks, options: [.prettyPrinted, .sortedKeys]) { try? data.write(to: url) }
                        if let bitmap = notes.contentView?.bitmapImageRepForCachingDisplay(in: notes.contentView!.bounds) {
                            notes.contentView?.cacheDisplay(in: notes.contentView!.bounds, to: bitmap)
                            if let data = bitmap.representation(using: .png, properties: [:]) { try? data.write(to: url.deletingLastPathComponent().appendingPathComponent("notes-preview.png")) }
                        }
                        NSApp.terminate(nil)
                        }
                        }
                        }
                        }
                        }
                    }
                }
            }
        }
    }

}

@main
enum VelvetApp {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        withExtendedLifetime(delegate) { application.run() }
    }
}
