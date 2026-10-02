import AppKit

enum Mood: String, CaseIterable {
    case idle, walk, wave, pickedUp, sleep, sideEye, celebrate, ballet, floorwork, vogue, grumpy, coffee
    case paperOpen, paperClose, paperToss, affection, annoyed
    case stretch, focusNap, wakeUp, tumble, crying, recover
    case zoomies, reconcile, shySmile, disco
    case restless, showOff, takeBow, overstimulated, house, waacking
    var isChoreography: Bool { self == .ballet || self == .floorwork || self == .vogue || self == .disco || self == .house || self == .waacking }
    static let danceChoices: [Mood] = [.ballet, .floorwork, .vogue, .disco, .house, .waacking]
    static let automaticDances: [Mood] = [.ballet, .floorwork, .disco, .house]
    var danceTitle: String {
        switch self {
        case .ballet: return "Ballet"
        case .floorwork: return "Floorwork"
        case .vogue: return "Vogue Fem"
        case .disco: return "Robot disco"
        case .house: return "House"
        case .waacking: return "Waacking"
        default: return label
        }
    }
    var isDance: Bool { isChoreography || self == .zoomies }
    var isPaper: Bool { self == .paperOpen || self == .paperClose || self == .paperToss }
    var isInteraction: Bool { isPaper || self == .coffee || self == .affection || self == .annoyed || self == .tumble || self == .crying || self == .recover || self == .takeBow || self == .wakeUp }
    var label: String {
        switch self {
        case .idle: return "Just vibing"
        case .walk: return "A little strut"
        case .wave: return "Oh, hello"
        case .pickedUp: return "Handle with flair"
        case .sleep: return "Beauty sleep"
        case .sideEye: return "Judging, affectionately"
        case .celebrate: return "Thought secured"
        case .ballet: return "A little ballet"
        case .floorwork: return "Floorwork, darling"
        case .vogue: return "Vogue Fem"
        case .grumpy: return "Iced latte. Now."
        case .coffee: return "Sipping, approvingly"
        case .paperOpen: return "A thought, unfolded"
        case .paperClose: return "Tucked away"
        case .paperToss: return "Paper, dismissed"
        case .affection: return "Okay, you can stay"
        case .annoyed: return "Excuse you"
        case .stretch: return "A quiet stretch"
        case .focusNap: return "Napping while you focus"
        case .wakeUp: return "A sleepy little stretch"
        case .tumble: return "A little stumble"
        case .crying: return "A little comfort, please"
        case .recover: return "Better with you"
        case .zoomies: return "Latte zoomies"
        case .reconcile: return "Staying close"
        case .shySmile: return "A shy little smile"
        case .disco: return "Robot disco"
        case .house: return "House"
        case .waacking: return "Waacking"
        case .restless: return "Needs a dance break"
        case .showOff: return "Waiting for applause"
        case .takeBow: return "Thank you, darling"
        case .overstimulated: return "A little quiet, please"
        }
    }
}

final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class CharacterView: NSView {
    var mood: Mood = .wave
    var paused = false
    var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    var onClick: (() -> Void)?
    var onMove: (() -> Void)?
    var onDrop: (() -> Void)?
    var onCoffee: (() -> Void)?
    var onNeedsChanged: (() -> Void)?
    var onPerformanceChanged: (() -> Void)?
    var care = CompanionCare() {
        didSet {
            if care.upset != oldValue.upset {
                if care.needsAffection { responses.upset(); performance.cancelApplause(); cancelDance() }
                pendingPaper = nil
                mood = baseMood
                moodBegan = Date()
                moodUntil = needsAffection ? .distantFuture : Date()
                updateAccessibilityHelp()
                needsDisplay = true
                onNeedsChanged?()
            }
        }
    }
    var focusStretchElapsed: Double?
    var focusRest: Mood? {
        didSet {
            guard focusRest != oldValue else { return }
            if focusRest != nil { responses.cancelZoomies(); performance.cancelApplause(); cancelDance() }
            if focusRest != nil && mood == .wakeUp { mood = baseMood; moodUntil = .distantPast }
            if canGiveNotes && !isBusy { mood = baseMood; needsDisplay = true }
        }
    }
    var needsAffection: Bool { care.needsAffection }
    var canGiveNotes: Bool { care.canGiveNotes(needsCoffee: wantsCoffee) }
    var baseMood: Mood {
        if care.upset == .crying { return .crying }
        if care.upset == .annoyed { return .annoyed }
        if wantsCoffee { return .grumpy }
        if let focusRest { return focusRest }
        if stimulation.overstimulated { return .overstimulated }
        if performance.awaitingApplause { return .showOff }
        switch responses.phase {
        case .zoomies: return .zoomies
        case .reconciliation: return .reconcile
        case .shySmile: return .shySmile
        case .idle: return performance.restless ? .restless : .idle
        }
    }
    var wantsCoffee = false {
        didSet {
            if wantsCoffee { responses.cancelZoomies(); performance.cancelApplause(); cancelDance(); pendingPaper = nil; react(baseMood) }
            needsDisplay = true
            updateAccessibilityHelp()
            if wantsCoffee != oldValue { onNeedsChanged?() }
        }
    }
    static let appearanceScale = 0.56 // A further 30% reduction from 0.8.
    static let presentationRatio = appearanceScale / 0.8
    private var spritePivotY: Double { 186 + (100 - 186) * Self.presentationRatio }
    private func accessoryPoint(x: Double, y: Double) -> NSPoint {
        NSPoint(x: 95 + (x - 95) * Self.presentationRatio, y: 186 + (y - 186) * Self.presentationRatio)
    }
    var coffeeButtonRect: NSRect { offeredLatteRect }
    private var gesture: CompanionGesture?
    private var attitude = AttitudeState()
    private var latteOffset = NSPoint.zero
    private var lattePickupOffset = NSPoint.zero
    private var latteReturnBegan: Double?
    private var latteHandoffOrigin: NSPoint?
    private var pendingPaper: Mood?
    private(set) var responses = CompanionResponse()
    private(set) var performance = PerformanceState()
    var stimulation = StimulationState()
    var applauseChance = PerformanceState.applauseChance
    private let applauseButton = NSButton(title: "👏", target: nil, action: nil)
    private let danceButton = NSButton(title: "🩰", target: nil, action: nil)
    private var danceInProgress = false
    private var danceChosen = false
    private var danceAsksForApplause = false
    private var showOffPose = 17
    private var heldFinish: (index: Int, rect: NSRect, angle: Double)?
    var hasGentleResponse: Bool { responses.isReconciling }
    var noteIsVisible = false
    var noteDirection = -1.0
    private var lastResponseTick = ProcessInfo.processInfo.systemUptime
    var isCarryingLatte: Bool { gesture?.phase == .carryingLatte }
    var contextMenu: (() -> NSMenu)?
    var moodUntil = Date().addingTimeInterval(2.5)
    var previewTime: Double?
    private var atlas: SpriteAtlas?
    var spriteFrameCount: Int { atlas?.frames.count ?? 0 }
    var displayedSpriteIndex: Int? {
        guard let atlas else { return nil }
        return spritePose(time: animationTime, mood: mood, atlas: atlas).index
    }
    var hasLatteAnimation: Bool { spriteFrameCount >= 28 }
    var hasInteractionAnimation: Bool { spriteFrameCount >= 44 }
    var hasWellbeingAnimation: Bool { spriteFrameCount >= 52 }
    var hasDiscoAnimation: Bool { spriteFrameCount >= 56 }
    var hasClubAnimation: Bool { spriteFrameCount >= 68 }
    var hasStretchAnimation: Bool { spriteFrameCount >= 76 }
    var isBusy: Bool { mood.isInteraction && Date() < moodUntil }
    private var moodBegan = Date()
    private let sipDuration = 6.0
    private var born = Date()
    private var clock: Timer?
    private var idleSince = Date()
    private var lastFrame = Date.distantPast
    private var dragOrigin: NSPoint?
    private var mouseOrigin: NSPoint?
    private var hovering = false
    private var nextIdle = Date().addingTimeInterval(12)
    private var idleSequence = 0
    private var pixelCanvas: NSBitmapImageRep?
    private let pixelSize = 1.6
    static let cream = NSColor(calibratedRed: 0.98, green: 0.95, blue: 0.84, alpha: 1)
    static let ink = NSColor(calibratedRed: 0.16, green: 0.15, blue: 0.18, alpha: 1)
    static let pink = NSColor(calibratedRed: 1, green: 0.24, blue: 0.57, alpha: 1)
    static let acid = NSColor(calibratedRed: 0.77, green: 0.96, blue: 0.29, alpha: 1)

    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Velvet, your desktop notes companion")
        applauseButton.target = self; applauseButton.action = #selector(applausePressed)
        applauseButton.isBordered = false; applauseButton.bezelStyle = .regularSquare
        applauseButton.font = .systemFont(ofSize: 19)
        applauseButton.toolTip = "Applaud her · she'll take a little bow"
        applauseButton.setAccessibilityLabel("Applaud Velvet")
        applauseButton.isHidden = true
        addSubview(applauseButton)
        danceButton.target = self; danceButton.action = #selector(danceChooserPressed)
        danceButton.isBordered = false; danceButton.bezelStyle = .regularSquare
        danceButton.font = .systemFont(ofSize: 19)
        danceButton.toolTip = "Choose a dance · Ballet, Floorwork, Vogue Fem, Robot disco, House, or Waacking"
        danceButton.setAccessibilityLabel("Choose a dance for Velvet")
        danceButton.isHidden = true
        addSubview(danceButton)
        updateAccessibilityHelp()
        if let url = Bundle.main.url(forResource: "velvet-sprites-v5", withExtension: "png") {
            atlas = SpriteAtlas(url: url, additionalURL: Bundle.main.url(forResource: "vogue-sprites-v2", withExtension: "png"), latteURL: Bundle.main.url(forResource: "iced-latte-sprites-v2", withExtension: "png"), interactionURL: Bundle.main.url(forResource: "interaction-sprites-v2", withExtension: "png"), wellbeingURL: Bundle.main.url(forResource: "wellbeing-sprites-v1", withExtension: "png"), discoURL: Bundle.main.url(forResource: "disco-sprites-v1", withExtension: "png"), clubURL: Bundle.main.url(forResource: "club-sprites-v1", withExtension: "png"), stretchURL: Bundle.main.url(forResource: "stretch-sprites-v1", withExtension: "png"))
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func accessibilityPerformPress() -> Bool { onClick?(); return true }
    private func updateAccessibilityHelp() {
        var help = "Click her face or body for notes. Stroke or hold her head briefly for affection. Drag her body or Option-drag to move."
        if needsAffection { help += " She needs affection before she will return your notes." }
        if wantsCoffee { help += " She needs an iced latte before she will return your notes. Drag the cup into her hand or click it." }
        if performance.restless { help += " Click the ballet-shoes button beside her to choose Ballet, Floorwork, Vogue Fem, Robot disco, House, or Waacking." }
        if performance.awaitingApplause { help += " Click the clapping-hands button beside her to applaud; she will take a little bow." }
        if stimulation.overstimulated { help += " Too much fuss. Give her thirty seconds of quiet or start focus; notes are still available." }
        setAccessibilityHelp(help)
        syncCompanionButtons()
    }

    func start() {
        clock?.invalidate()
        lastResponseTick = ProcessInfo.processInfo.systemUptime
        clock = Timer(timeInterval: 1.0 / 24.0, repeats: true) { [weak self] _ in self?.tick() }
        clock?.tolerance = 0.008
        RunLoop.main.add(clock!, forMode: .common)
    }
    func stop() {
        clock?.invalidate(); clock = nil
        if gesture != nil { NSCursor.arrow.set() }
        gesture = nil; mouseOrigin = nil; dragOrigin = nil
        latteOffset = .zero; latteReturnBegan = nil
        latteHandoffOrigin = nil
        pendingPaper = nil
        if danceInProgress { cancelDance(); mood = baseMood }
        if mood.isInteraction { mood = baseMood }
    }
    func react(_ newMood: Mood, duration: TimeInterval = 2.3) {
        if newMood == .zoomies && reduceMotion { responses.cancelZoomies(); mood = baseMood; needsDisplay = true; return }
        if newMood == .coffee { responses.acceptLatte(allowed: canGiveNotes && focusRest == nil && !reduceMotion) }
        if newMood == .zoomies && canGiveNotes && focusRest == nil && !reduceMotion && responses.phase != .zoomies { responses.startZoomies() }
        if [.reconcile, .shySmile].contains(newMood) && canGiveNotes && focusRest == nil { responses.comfort() }
        if newMood == .paperOpen && !canGiveNotes { mood = baseMood; needsDisplay = true; return }
        if [.coffee, .recover, .affection, .takeBow, .wakeUp].contains(mood) && Date() < moodUntil && newMood.isPaper { pendingPaper = newMood; return }
        if mood == .coffee && Date() < moodUntil && ![.pickedUp, .grumpy, .coffee, .affection, .recover, .annoyed, .tumble, .crying].contains(newMood) { return }
        if isBusy && (newMood == .sideEye || newMood == .wave || newMood == .celebrate) { return }
        if newMood.isPaper { pendingPaper = nil }
        let passive = newMood.isDance || [.idle, .wave, .walk, .sleep, .sideEye, .celebrate, .stretch, .focusNap, .wakeUp, .reconcile, .shySmile, .restless, .showOff, .overstimulated].contains(newMood)
        let previousMood = mood
        if passive && (focusRest != nil || stimulation.overstimulated) && canGiveNotes { mood = baseMood }
        else { mood = !canGiveNotes && passive ? baseMood : newMood }
        if previousMood.isChoreography && mood != previousMood { cancelDance() }
        if mood == newMood && mood.isChoreography {
            performance.beginDance(); danceInProgress = true; danceChosen = false
            danceAsksForApplause = PerformanceState.asksForApplause(chance: applauseChance)
            updateAccessibilityHelp()
            onPerformanceChanged?()
        }
        moodBegan = Date()
        let length: Double
        switch mood {
        case .coffee: length = sipDuration
        case .paperOpen: length = 1.65
        case .paperClose: length = 1.4
        case .paperToss: length = 1.5
        case .affection: length = 2.3
        case .tumble: length = 1.2
        case .recover: length = 1.4
        case .takeBow: length = 1.8
        case .wakeUp: length = FocusSession.wakeDuration
        default: length = duration
        }
        moodUntil = [.grumpy, .annoyed, .crying, .focusNap, .zoomies, .reconcile, .restless, .showOff, .overstimulated].contains(mood) ? .distantFuture : Date().addingTimeInterval(length)
        idleSince = Date()
        syncCompanionButtons()
        needsDisplay = true
    }
    private func tick() {
        guard let window, window.isVisible else { return }
        let mouse = convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        let over = interactiveArea(mouse)
        // NSView hit testing alone cannot forward a click to another application.
        // Switch the entire panel to pass-through whenever the pointer is off the character.
        window.ignoresMouseEvents = !over && gesture == nil
        if over != hovering {
            hovering = over
            if over && gesture == nil && !mood.isDance && !isBusy && focusRest == nil && !responses.isActive && !performance.isEngaged && !stimulation.overstimulated { react(.sideEye, duration: 1.8) }
        }
        let now = Date()
        if mouseOrigin == nil && now > moodUntil && mood != .idle && mood != .sleep {
            finishDanceIfNeeded()
            mood = baseMood
            if [.restless, .showOff, .overstimulated].contains(mood) { moodUntil = .distantFuture }
            if let paper = pendingPaper { pendingPaper = nil; if canGiveNotes { react(paper) } }
        }
        let responseNow = ProcessInfo.processInfo.systemUptime
        advanceResponses(by: min(0.25, max(0, responseNow - lastResponseTick)))
        advancePerformance(by: min(0.25, max(0, responseNow - lastResponseTick)))
        advanceStimulation(by: min(0.25, max(0, responseNow - lastResponseTick)))
        syncCompanionButtons()
        lastResponseTick = responseNow
        if let held = gesture, held.target == .crown, held.phase == .pressed, ProcessInfo.processInfo.systemUptime - held.began >= 0.35 {
            updatePointer(at: held.last, screenPoint: mouseOrigin ?? .zero, time: ProcessInfo.processInfo.systemUptime)
        }
        if let began = latteReturnBegan, ProcessInfo.processInfo.systemUptime - began > 0.24 { latteReturnBegan = nil; latteOffset = .zero }
        if mood != .coffee || now.timeIntervalSince(moodBegan) > 0.3 { latteHandoffOrigin = nil }
        if !paused && !reduceMotion && canGiveNotes && focusRest == nil && !responses.isActive && !performance.isEngaged && !stimulation.overstimulated && !isBusy && !mood.isDance && mouseOrigin == nil && !hovering && now > nextIdle {
            idleSequence += 1
            let playlist: [Mood] = [.wave, .walk, .sideEye, .stretch] + Mood.automaticDances
            let next = playlist[idleSequence % playlist.count]
            react(next, duration: next == .stretch ? FocusSession.stretchDuration : (next.isDance ? 7 : 3))
            nextIdle = now.addingTimeInterval(18 + Double(idleSequence % 7))
        }
        if now.timeIntervalSince(idleSince) > 75 && canGiveNotes && focusRest == nil && !responses.isActive && !performance.isEngaged && !stimulation.overstimulated && !hovering && mouseOrigin == nil && !mood.isDance { mood = .sleep }
        let interval = ((paused || reduceMotion || mood == .sleep) && latteReturnBegan == nil) ? 0.8 : 1.0 / 24.0
        if now.timeIntervalSince(lastFrame) >= interval { needsDisplay = true; lastFrame = now }
    }
    func interactiveArea(_ point: NSPoint) -> Bool {
        if showsApplause && applauseButtonRect.contains(point) { return true }
        if showsDanceChooser && applauseButtonRect.contains(point) { return true }
        if wantsCoffee && latteContains(point) { return true }
        if let atlas {
            let pose = spritePose(time: animationTime, mood: mood, atlas: atlas)
            let dx = point.x - 95, dy = point.y - spritePivotY
            let x = 95 + dx * cos(pose.angle) + dy * sin(pose.angle)
            let y = spritePivotY - dx * sin(pose.angle) + dy * cos(pose.angle)
            let frame = atlas.frames[pose.index]
            let scale = atlas.scale * Self.appearanceScale * frame.unitScale
            return frame.contains(x: (x - pose.rect.minX) / scale, y: (y - pose.rect.minY) / scale)
        }
        let pose = geometry(time: animationTime, mood: mood)
        let dx = point.x - 95, dy = point.y - 110
        let p = NSPoint(x: 95 + dx * cos(pose.wobble) + dy * sin(pose.wobble), y: 110 - dx * sin(pose.wobble) + dy * cos(pose.wobble) - pose.bounce + pose.lift)
        let headX = p.x - 95, headY = p.y - 67
        let h = NSPoint(x: 95 + headX * cos(pose.headTilt) + headY * sin(pose.headTilt), y: 67 - headX * sin(pose.headTilt) + headY * cos(pose.headTilt))
        if headPath().contains(h) || NSRect(x: 141, y: 48, width: 13, height: 41).contains(h) { return true }
        if torsoPath().contains(p) { return true }
        if NSBezierPath(roundedRect: NSRect(x: 25, y: 110, width: 37, height: 37), xRadius: 3, yRadius: 3).contains(p) { return true }
        for (x, left) in [(68 - pose.stride, true), (106 + pose.stride, false)] {
            if NSRect(x: x, y: 146, width: 20, height: 29).contains(p) { return true }
            if NSBezierPath(roundedRect: NSRect(x: left ? x - 7 : x, y: 173, width: 32, height: 14), xRadius: 3, yRadius: 3).contains(p) { return true }
        }
        for (a, b) in [(NSPoint(x: 70, y: 111), NSPoint(x: 50, y: 126)), (NSPoint(x: 123, y: 111), pose.elbow), (pose.elbow, pose.hand)] {
            let vx = b.x - a.x, vy = b.y - a.y
            let u = min(1, max(0, ((p.x - a.x) * vx + (p.y - a.y) * vy) / (vx * vx + vy * vy)))
            if hypot(p.x - a.x - vx * u, p.y - a.y - vy * u) <= 7 { return true }
        }
        return hypot(p.x - pose.hand.x, p.y - pose.hand.y) < 10
    }
    override func mouseDown(with event: NSEvent) {
        beginPointer(at: convert(event.locationInWindow, from: nil), screenPoint: NSEvent.mouseLocation, time: ProcessInfo.processInfo.systemUptime, forceMove: event.modifierFlags.contains(.option))
    }
    override func mouseDragged(with event: NSEvent) {
        updatePointer(at: convert(event.locationInWindow, from: nil), screenPoint: NSEvent.mouseLocation, time: ProcessInfo.processInfo.systemUptime)
    }
    override func mouseUp(with event: NSEvent) {
        endPointer(at: convert(event.locationInWindow, from: nil), time: ProcessInfo.processInfo.systemUptime)
    }
    var crownRect: NSRect {
        guard let atlas else { return NSRect(x: 45, y: 26, width: 100, height: 28) }
        let rect = spritePose(time: animationTime, mood: mood, atlas: atlas).rect
        return NSRect(x: rect.minX - 6, y: rect.minY - 5, width: rect.width + 12, height: rect.height * 0.72 + 5)
    }
    private func onCrown(_ point: NSPoint) -> Bool { crownRect.contains(point) && interactiveArea(point) }
    var latteHandRect: NSRect {
        guard let atlas else { return NSRect(x: 110, y: 136, width: 30, height: 42) }
        let rect = spritePose(time: animationTime, mood: .grumpy, atlas: atlas, receiving: false).rect
        return NSRect(x: rect.midX + rect.width * 0.29, y: rect.minY + rect.height * 0.53, width: rect.width * 0.25, height: rect.height * 0.20)
    }
    func beginPointer(at point: NSPoint, screenPoint: NSPoint, time: Double, forceMove: Bool = false) {
        let target: CompanionGesture.Target = forceMove ? .body : (wantsCoffee && latteContains(point) ? .latte : (onCrown(point) ? .crown : .body))
        if target == .latte {
            lattePickupOffset = currentLatteOffset
            latteReturnBegan = nil
            NSCursor.closedHand.set()
        }
        if target == .crown { NSCursor.openHand.set() }
        gesture = CompanionGesture(target: target, point: point, time: time)
        mouseOrigin = screenPoint
        dragOrigin = window?.frame.origin
    }
    func updatePointer(at point: NSPoint, screenPoint: NSPoint, time: Double) {
        guard var current = gesture else { return }
        let previous = current.phase
        let phase = current.update(point: point, time: time, onCrown: onCrown(point))
        gesture = current
        switch phase {
        case .carryingLatte:
            latteOffset = NSPoint(x: lattePickupOffset.x + point.x - current.origin.x, y: lattePickupOffset.y + point.y - current.origin.y)
        case .petting:
            if previous != .petting { rubCrown() }
        case .moving:
            guard let mouseOrigin, let dragOrigin, let window else { break }
            cancelDance()
            mood = .pickedUp; window.ignoresMouseEvents = false
            window.setFrameOrigin(NSPoint(x: dragOrigin.x + screenPoint.x - mouseOrigin.x, y: dragOrigin.y + screenPoint.y - mouseOrigin.y))
            onMove?()
        case .pressed: break
        }
        needsDisplay = true
    }
    func endPointer(at point: NSPoint, time: Double) {
        if let held = gesture, held.target == .crown, held.phase == .pressed {
            updatePointer(at: point, screenPoint: mouseOrigin ?? point, time: time)
        }
        guard let current = gesture else { return }
        let completion = current.finish(overCup: latteContains(point), overHand: latteHandRect.insetBy(dx: -5, dy: -4).contains(point))
        let handedCup = NSPoint(x: offeredLatteRect.midX, y: offeredLatteRect.midY)
        gesture = nil; mouseOrigin = nil; dragOrigin = nil
        NSCursor.arrow.set()
        switch completion {
        case .giveLatte:
            latteHandoffOrigin = current.phase == .carryingLatte ? handedCup : nil
            latteOffset = .zero; latteReturnBegan = nil
            onCoffee?()
        case .returnLatte:
            latteReturnBegan = ProcessInfo.processInfo.systemUptime
            if reduceMotion { latteOffset = .zero; latteReturnBegan = nil }
        case .pet: break // Affection was delivered when the gesture became petting.
        case .poke:
            // A head tap while upset is not a request for a note. Let the
            // following stroke/hold soothe her without queuing an open.
            if !needsAffection {
                pokeCrown(at: time)
                if !needsAffection { onClick?() }
            }
        case .moved: recordStimulation(at: time); react(.wave); onDrop?()
        case .openNotes: onClick?()
        }
        needsDisplay = true
    }
    func rubCrown() {
        let wasCrying = care.upset == .crying
        if care.needsAffection { responses.comfort() }
        attitude.pet(); care.soothe()
        react(wasCrying ? .recover : .affection)
        recordStimulation()
    }
    func makeAnnoyed() { care.annoy(); react(baseMood) }
    private func cancelDance() { danceInProgress = false; danceChosen = false; danceAsksForApplause = false }
    func chooseDance(_ dance: Mood) {
        guard dance.isChoreography, canGiveNotes, focusRest == nil, !stimulation.overstimulated, mood != .coffee else { return }
        recordStimulation()
        guard !stimulation.overstimulated else { return }
        responses.cancelZoomies()
        react(dance, duration: 12)
        if mood == dance { danceChosen = true }
    }
    private func finishDanceIfNeeded() {
        guard danceInProgress, mood.isChoreography else { return }
        if let atlas { heldFinish = spritePose(time: animationTime, mood: mood, atlas: atlas); showOffPose = heldFinish!.index }
        performance.finishDance(chosen: danceChosen, asksForApplause: danceAsksForApplause)
        moodBegan = Date()
        cancelDance(); updateAccessibilityHelp()
        onPerformanceChanged?()
    }
    func makeRestless() {
        performance.makeRestless(); updateAccessibilityHelp()
        if canGiveNotes && focusRest == nil && !isBusy && !mood.isDance { react(baseMood) }
        onPerformanceChanged?()
    }
    func showOff() {
        guard canGiveNotes, focusRest == nil, !stimulation.overstimulated else { return }
        showOffPose = 17; heldFinish = nil; performance.finishDance(chosen: false, asksForApplause: true)
        react(baseMood); updateAccessibilityHelp()
        onPerformanceChanged?()
    }
    @discardableResult func applaud() -> Bool {
        guard canGiveNotes, focusRest == nil, !stimulation.overstimulated, !isBusy, performance.applaud() else { return false }
        react(.takeBow); updateAccessibilityHelp()
        onPerformanceChanged?()
        return true
    }
    var showsApplause: Bool { performance.awaitingApplause && mood == .showOff && canGiveNotes && focusRest == nil && !stimulation.overstimulated }
    var canChooseDance: Bool { canGiveNotes && focusRest == nil && !stimulation.overstimulated && mood != .coffee }
    var showsDanceChooser: Bool { performance.restless && mood == .restless && canChooseDance }
    var applauseButtonRect: NSRect {
        let crown = crownRect
        return NSRect(x: min(bounds.maxX - 29, crown.maxX + 1), y: max(4, crown.minY + 8), width: 27, height: 27)
    }
    func syncCompanionButtons() {
        applauseButton.isHidden = !showsApplause
        if showsApplause { applauseButton.frame = applauseButtonRect }
        danceButton.isHidden = !showsDanceChooser
        if showsDanceChooser { danceButton.frame = applauseButtonRect }
    }
    func makeDanceMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        for dance in Mood.danceChoices {
            let item = NSMenuItem(title: dance.danceTitle, action: #selector(danceChosen(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = dance.rawValue
            item.isEnabled = canChooseDance
            menu.addItem(item)
        }
        return menu
    }
    @objc private func danceChooserPressed() {
        guard showsDanceChooser else { return }
        makeDanceMenu().popUp(positioning: nil, at: NSPoint(x: danceButton.frame.minX, y: danceButton.frame.maxY + 3), in: self)
    }
    @objc private func danceChosen(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String, let dance = Mood(rawValue: value) else { return }
        chooseDance(dance)
    }
    @objc private func applausePressed() { applaud() }
    func clickApplauseButton() { applauseButton.performClick(nil) }
    func makeOverstimulated() {
        stimulation.makeOverstimulated()
        enterQuietMood()
    }
    private func recordStimulation(at time: Double = ProcessInfo.processInfo.systemUptime) {
        guard focusRest == nil else { return }
        if stimulation.interact(at: time) { enterQuietMood() }
        else if stimulation.overstimulated && canGiveNotes && !isBusy { mood = baseMood }
    }
    private func enterQuietMood() {
        responses.cancelZoomies(); performance.cancelApplause(); cancelDance()
        if canGiveNotes && focusRest == nil {
            mood = .overstimulated; moodBegan = Date(); moodUntil = .distantFuture
        }
        updateAccessibilityHelp(); needsDisplay = true; onPerformanceChanged?()
    }
    func advanceStimulation(by seconds: Double) {
        let available = window?.isVisible == true && !paused && gesture == nil
        if stimulation.advance(by: seconds, available: available) {
            if canGiveNotes && !isBusy && !mood.isDance { react(baseMood) }
            updateAccessibilityHelp(); onPerformanceChanged?()
        }
    }
    func advancePerformance(by seconds: Double) {
        let available = window?.isVisible == true && canGiveNotes && focusRest == nil && !paused && !reduceMotion && gesture == nil && !isBusy && !mood.isDance && mood != .sleep && !responses.isActive && !stimulation.overstimulated
        if performance.advance(by: seconds, available: available) {
            mood = baseMood; moodUntil = .distantFuture; updateAccessibilityHelp(); needsDisplay = true
            onPerformanceChanged?()
        }
    }
    func stumble() { care.tumble(); react(.tumble) }
    func advanceTumble(by seconds: Double) {
        guard canGiveNotes, focusRest == nil, !stimulation.overstimulated, !paused, !reduceMotion, gesture == nil, !isBusy, !mood.isDance, mood != .sleep else { return }
        if care.advanceEligible(by: seconds) { react(.tumble) }
    }
    func advanceResponses(by seconds: Double) {
        let previous = responses.phase
        let available = window?.isVisible == true && !paused && gesture == nil && !isBusy && !performance.awaitingApplause && !mood.isPaper && (!mood.isDance || mood == .zoomies) && mood != .sleep
        responses.advance(by: seconds, healthy: canGiveNotes, quiet: focusRest != nil || stimulation.overstimulated || reduceMotion, available: available)
        guard previous != responses.phase, canGiveNotes, focusRest == nil, !isBusy, gesture == nil, !stimulation.overstimulated else { return }
        if [.idle, .sideEye, .zoomies, .reconcile, .shySmile].contains(mood) {
            mood = baseMood; moodBegan = Date(); moodUntil = .distantFuture
            idleSince = Date(); nextIdle = Date().addingTimeInterval(12)
            needsDisplay = true
        }
    }
    func pokeCrown(at time: Double = ProcessInfo.processInfo.systemUptime) {
        if attitude.poke(at: time) { makeAnnoyed() }
        else { react(.sideEye, duration: 0.7) }
    }
    override func rightMouseDown(with event: NSEvent) {
        if let menu = contextMenu?() { NSMenu.popUpContextMenu(menu, with: event, for: self) }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill(); dirtyRect.fill()
        drawGroundShadow()
        let width = Int(ceil(bounds.width / pixelSize)), height = Int(ceil(bounds.height / pixelSize))
        if pixelCanvas?.pixelsWide != width || pixelCanvas?.pixelsHigh != height {
            pixelCanvas = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32)
        }
        guard let canvas = pixelCanvas, let offscreen = NSGraphicsContext(bitmapImageRep: canvas), let screen = NSGraphicsContext.current else { drawCompanion(); return }
        NSGraphicsContext.saveGraphicsState()
        let context = offscreen.cgContext
        context.saveGState()
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.translateBy(x: 0, y: Double(height))
        context.scaleBy(x: Double(width) / bounds.width, y: -Double(height) / bounds.height)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        drawCompanion()
        context.restoreGState()
        NSGraphicsContext.restoreGraphicsState()
        // Solid pixel edges and a small set of channel levels give every pose
        // the same retro treatment without changing the source artwork.
        if let bytes = canvas.bitmapData {
            let alphaFirst = canvas.bitmapFormat.contains(.alphaFirst)
            let alphaIndex = alphaFirst ? 0 : 3
            let colors = alphaFirst ? [1, 2, 3] : [0, 1, 2]
            let premultiplied = !canvas.bitmapFormat.contains(.alphaNonpremultiplied)
            for y in 0..<height {
                for x in 0..<width {
                    let offset = y * canvas.bytesPerRow + x * 4
                    let alpha = Int(bytes[offset + alphaIndex])
                    if alpha < 128 {
                        for channel in 0..<4 { bytes[offset + channel] = 0 }
                    } else {
                        for channel in colors {
                            let value = premultiplied ? min(255, Int(bytes[offset + channel]) * 255 / alpha) : Int(bytes[offset + channel])
                            bytes[offset + channel] = UInt8(min(255, ((value + 7) / 14) * 14))
                        }
                        bytes[offset + alphaIndex] = 255
                    }
                }
            }
        }
        guard let image = canvas.cgImage else { return }
        screen.cgContext.saveGState()
        screen.cgContext.interpolationQuality = .none
        NSImage(cgImage: image, size: bounds.size).draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        screen.cgContext.restoreGState()
    }
    var groundShadowRect: NSRect {
        let center = atlas.map { spritePose(time: animationTime, mood: mood, atlas: $0).rect.midX } ?? 95
        let width = ([Mood.focusNap, .crying, .tumble, .floorwork, .stretch].contains(mood) ? 82.0 : 65.0) * Self.presentationRatio
        return NSRect(x: center - width / 2, y: 184.5, width: width, height: 8 * Self.presentationRatio)
    }
    private func drawGroundShadow() {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let rect = groundShadowRect
        context.saveGState()
        context.translateBy(x: rect.midX, y: rect.midY)
        context.scaleBy(x: rect.width / 2, y: rect.height / 2)
        let colors = [NSColor.black.withAlphaComponent(0.26).cgColor, NSColor.black.withAlphaComponent(0.12).cgColor, NSColor.black.withAlphaComponent(0).cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.45, 1]) {
            context.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 1, options: [])
        }
        context.restoreGState()
    }
    private func drawCompanion() {
        drawCharacter(time: animationTime, mood: mood)
        if wantsCoffee || mood == .grumpy { drawLatteOffer() }
        if mood == .coffee { drawLatteHandoff() }
        if mood == .paperToss { drawPaperToss() }
        if mood == .affection || mood == .recover || mood == .takeBow { drawAffection() }
    }

    private var animationTime: Double { previewTime ?? (paused || reduceMotion ? 0 : Date().timeIntervalSince(born)) }

    private func spritePose(time t: Double, mood: Mood, atlas: SpriteAtlas, coffeeElapsed: Double? = nil, responseElapsed: Double? = nil, receiving: Bool = true, forcedIndex: Int? = nil) -> (index: Int, rect: NSRect, angle: Double) {
        if mood == .showOff, let heldFinish, forcedIndex == nil { return heldFinish }
        let active = previewTime != nil || (!paused && !reduceMotion)
        let elapsed = max(0, previewTime ?? Date().timeIntervalSince(moodBegan))
        let zoom = max(0, responseElapsed ?? previewTime ?? responses.zoomiesElapsed)
        var index: Int
        switch mood {
        case .idle:
            if active && t.truncatingRemainder(dividingBy: 5.1) < 0.13 { index = 1 }
            else { index = hasClubAnimation && t.truncatingRemainder(dividingBy: 7) < 3.5 ? 56 : 0 }
        case .sideEye: index = 2
        case .grumpy: index = hasLatteAnimation ? 20 : 2
        case .coffee:
            if hasLatteAnimation {
                let elapsed = coffeeElapsed ?? previewTime ?? Date().timeIntervalSince(moodBegan)
                if hasInteractionAnimation && active && elapsed >= 4.8 { index = elapsed < 5.5 ? 42 : 43 }
                else { index = active ? 21 + min(5, max(0, Int(elapsed / 0.8))) : 26 }
            } else { index = 0 }
        case .wave: index = hasClubAnimation ? 57 : 3
        case .celebrate: index = 3
        case .pickedUp: index = 4
        case .walk: index = active ? 5 + Int(t * 5) % 2 : 5
        case .sleep: index = 7
        case .ballet: index = active ? 8 + Int(t * 2.5) % 4 : 8
        case .floorwork: index = active ? 12 + Int(t * 2.5) % 4 : 12
        case .vogue: index = atlas.frames.count >= 20 ? (active ? 16 + Int(t * 2.5) % 4 : 16) : 2
        case .paperOpen: index = hasInteractionAnimation ? 28 + (active ? min(2, Int(elapsed / 0.38)) : 2) : 3
        case .paperClose: index = hasInteractionAnimation ? 31 + (active && elapsed < 0.45 ? 0 : 1) : 0
        case .paperToss: index = hasInteractionAnimation ? (active && elapsed < 0.40 ? 33 : 34) : 3
        case .affection: index = hasInteractionAnimation ? 36 : 1
        case .annoyed: index = hasInteractionAnimation ? 38 + (active && elapsed > 1.4 ? 1 : 0) : 2
        case .stretch:
            if hasStretchAnimation {
                let stretch = active ? (previewTime ?? focusStretchElapsed ?? elapsed) : 0
                index = 68 + FocusSession.stretchPoseStep(at: stretch)
            } else { index = hasWellbeingAnimation ? 44 + (active ? Int(t / 3) % 2 : 0) : 9 }
        case .focusNap: index = hasWellbeingAnimation ? 46 + (active && t.truncatingRemainder(dividingBy: 6) < 0.3 ? 1 : 0) : 7
        case .wakeUp:
            if !active { index = 0 }
            else if hasStretchAnimation { index = [46, 47, 75, 45, 44, 1, hasClubAnimation ? 56 : 0][FocusSession.wakePoseStep(at: elapsed)] }
            else if hasWellbeingAnimation { index = [46, 47, 51, 45, 44, 1, 0][FocusSession.wakePoseStep(at: elapsed)] }
            else { index = elapsed < 1 ? 7 : (elapsed < 3.2 ? 3 : 0) }
        case .tumble: index = hasWellbeingAnimation ? (active && elapsed < 0.45 ? 48 : 49) : 4
        case .crying: index = hasWellbeingAnimation ? 50 : 20
        case .recover: index = hasWellbeingAnimation && active && elapsed < 0.6 ? 51 : 36
        case .reconcile: index = active && t.truncatingRemainder(dividingBy: 6.8) < 0.14 ? 1 : 0
        case .shySmile: index = hasInteractionAnimation ? 36 : 1
        case .disco: index = hasDiscoAnimation ? (active ? 52 + Int(elapsed / 0.65) % 4 : 52) : 16
        case .restless: index = (hasClubAnimation ? 58 : 5) + (active ? Int(elapsed * 3) % 2 : 0)
        case .showOff: index = min(showOffPose, atlas.frames.count - 1)
        case .house: index = hasClubAnimation ? 60 + (active ? Int(elapsed / 0.28) % 4 : 0) : 5
        case .waacking: index = hasClubAnimation ? 64 + (active ? Int(elapsed / 0.24) % 4 : 0) : 3
        case .takeBow: index = hasInteractionAnimation ? 42 : 1
        case .overstimulated: index = hasInteractionAnimation && elapsed < 3 ? 39 : 7
        case .zoomies:
            if !active { index = 0 }
            else if zoom < 2 { index = 5 + Int(zoom * 5) % 2 }
            else if zoom < 4.8 { index = (hasClubAnimation ? 60 : (hasDiscoAnimation ? 52 : 5)) + min(hasDiscoAnimation ? 2 : 1, Int((zoom - 2) / 0.9)) }
            else if zoom < 6.4 { index = hasInteractionAnimation ? (zoom < 5.6 ? 42 : 43) : 3 }
            else { index = 0 }
        }
        if receiving && isCarryingLatte && hasInteractionAnimation { index = 40 + (latteHandRect.contains(gesture!.last) ? 1 : 0) }
        if let forcedIndex { index = forcedIndex }
        let frame = atlas.frames[index]
        var lift = active ? sin(t * 1.8) * 0.35 : 0
        if [.focusNap, .wakeUp, .crying, .tumble, .showOff, .overstimulated].contains(mood) { lift = 0 }
        if mood == .takeBow && active { lift += sin(min(1, elapsed / 1.8) * .pi) * 4 }
        if mood == .celebrate && active { lift -= abs(sin(t * 6)) * 8 }
        if mood.isDance && mood != .zoomies && active { lift -= abs(sin(t * .pi * 2.5)) * (mood == .ballet ? 2 : 0.6) }
        var offsetX = mood == .walk && active ? sin(t * 2) * 7 : 0
        if mood == .zoomies && active {
            if zoom < 2 { offsetX = sin(zoom * .pi * 2) * 8; lift -= abs(sin(zoom * .pi * 5)) * 1.2 }
            else if zoom < 6.4 { offsetX = sin(zoom * 2) * 2; lift -= abs(sin(zoom * 4)) * 0.6 }
            else { offsetX = sin(6.4 * 2) * 2 * max(0, (8 - zoom) / 1.6) }
        }
        if [.reconcile, .shySmile].contains(mood), noteIsVisible {
            let closeness = previewTime != nil ? 1 : min(1, responses.reconciliationElapsed / 4, responses.reconciliationRemaining / 5)
            offsetX = noteDirection * 4.5 * max(0, closeness)
        }
        if mood == .house && active { offsetX = sin(elapsed * .pi / 0.56) * 3; lift += abs(sin(elapsed * .pi / 0.56)) * 0.8 }
        if mood == .waacking && active { offsetX = sin(elapsed * .pi / 0.96) * 1.5 }
        if mood == .disco && active { offsetX = sin(elapsed * .pi / 1.3) * 4 }
        if mood == .restless && active { offsetX = sin(elapsed * 3) * 0.7 }
        offsetX *= Self.presentationRatio
        lift *= Self.presentationRatio
        let scale = atlas.scale * Self.appearanceScale * frame.unitScale
        let width = Double(frame.width) * scale, height = Double(frame.height) * scale
        let x = frame.anchorX.map { 95 + $0 * scale } ?? ((190 - width) / 2)
        let rect = NSRect(x: x + offsetX, y: 186 - height - frame.footGap * scale + lift, width: width, height: height)
        var angle = 0.0
        if mood == .pickedUp && active { angle = sin(t * 8) * 0.07 }
        if mood == .wave && active { angle = sin(t * 6) * 0.025 }
        if mood.isDance && mood != .zoomies && active { angle = sin(t * .pi * 2.5) * 0.02 }
        if mood == .zoomies && active && zoom < 6.4 { angle = sin(zoom * 5) * (zoom < 2 ? 0.022 : 0.012) }
        if mood == .shySmile { angle = noteDirection * (active ? 0.025 + sin(elapsed * 1.4) * 0.005 : 0.025) }
        if mood == .takeBow && active { angle = sin(min(1, elapsed / 1.8) * .pi) * 0.055 }
        if mood == .affection && active { angle = sin(elapsed * 4) * 0.015 }
        if mood == .stretch && active { angle = sin(t * 1.2) * 0.008 }
        if mood == .tumble && active && elapsed < 0.45 { angle = sin(elapsed / 0.45 * .pi) * 0.06 }
        if mood == .coffee && hasInteractionAnimation && elapsed > 4.8 && active { angle = sin((elapsed - 4.8) * .pi / 0.7) * 0.015 }
        return (index, rect, angle)
    }
    private func drawSprite(time t: Double, mood: Mood, atlas: SpriteAtlas) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let pose = spritePose(time: t, mood: mood, atlas: atlas)
        ctx.saveGState()
        ctx.translateBy(x: 95, y: spritePivotY); ctx.rotate(by: pose.angle); ctx.translateBy(x: -95, y: -spritePivotY)
        ctx.interpolationQuality = .high
        var fraction = 1.0
        var previous: (index: Int, rect: NSRect, angle: Double)?
        if mood == .coffee && (previewTime != nil || (!paused && !reduceMotion)) {
            let elapsed = previewTime ?? Date().timeIntervalSince(moodBegan)
            if latteHandoffOrigin != nil && hasInteractionAnimation && elapsed < 0.3 {
                let progress = elapsed / 0.3
                fraction = progress * progress * (3 - 2 * progress)
                previous = spritePose(time: t, mood: .grumpy, atlas: atlas, forcedIndex: 41)
            } else if elapsed > sipDuration - 0.18 {
                fraction = max(0, (sipDuration - elapsed) / 0.18)
                previous = spritePose(time: t, mood: .idle, atlas: atlas)
            } else if hasLatteAnimation && (elapsed < 4.16 || (hasInteractionAnimation && elapsed >= 4.8)) {
                let phase = elapsed >= 5.5 ? elapsed - 5.5 : (elapsed >= 4.8 ? elapsed - 4.8 : max(0, elapsed).truncatingRemainder(dividingBy: 0.8))
                if phase < 0.16 {
                    let progress = phase / 0.16
                    fraction = progress * progress * (3 - 2 * progress)
                    previous = elapsed < 0.8 ? spritePose(time: t, mood: .grumpy, atlas: atlas) : spritePose(time: t, mood: .coffee, atlas: atlas, coffeeElapsed: max(0, elapsed - 0.16))
                }
            }
        }
        if mood == .zoomies && (previewTime != nil || (!paused && !reduceMotion)) {
            let zoom = max(0, previewTime ?? responses.zoomiesElapsed)
            if let boundary = [0.0, 2.0, 2.9, 3.8, 4.8, 5.6, 6.4].last(where: { $0 <= zoom }), zoom - boundary < 0.12 {
                let progress = (zoom - boundary) / 0.12
                fraction = progress * progress * (3 - 2 * progress)
                previous = boundary == 0 ? spritePose(time: t, mood: .idle, atlas: atlas) : spritePose(time: t, mood: .zoomies, atlas: atlas, responseElapsed: boundary - 0.001)
            }
        }
        if mood == .stretch && !hasStretchAnimation && hasWellbeingAnimation && (previewTime != nil || (!paused && !reduceMotion)) {
            let phase = t.truncatingRemainder(dividingBy: 3)
            if t >= 3 && phase < 0.25 {
                let progress = phase / 0.25
                fraction = progress * progress * (3 - 2 * progress)
                previous = spritePose(time: t, mood: .stretch, atlas: atlas, forcedIndex: pose.index == 44 ? 45 : 44)
            }
        }
        if mood == .disco && hasDiscoAnimation && (previewTime != nil || (!paused && !reduceMotion)) {
            let elapsed = max(0, previewTime ?? Date().timeIntervalSince(moodBegan))
            let phase = elapsed.truncatingRemainder(dividingBy: 0.65)
            if phase < 0.12 {
                let progress = phase / 0.12
                fraction = progress * progress * (3 - 2 * progress)
                let lastIndex = elapsed < 0.65 ? 0 : 52 + (Int(elapsed / 0.65) + 3) % 4
                previous = spritePose(time: t, mood: .disco, atlas: atlas, forcedIndex: lastIndex)
            }
        }
        if let previous {
            // Add weighted frames inside an isolated layer for a true crossfade,
            // so the robot stays opaque while her hands and cup change poses.
            ctx.beginTransparencyLayer(auxiliaryInfo: nil)
            atlas.frames[previous.index].image.draw(in: previous.rect, from: .zero, operation: .sourceOver, fraction: 1 - fraction, respectFlipped: true, hints: nil)
            atlas.frames[pose.index].image.draw(in: pose.rect, from: .zero, operation: .plusLighter, fraction: fraction, respectFlipped: true, hints: nil)
            ctx.endTransparencyLayer()
        } else {
            atlas.frames[pose.index].image.draw(in: pose.rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        }
        ctx.restoreGState()
        if mood == .celebrate {
            for (x, y, r) in [(26.0, 57.0, 5.0), (168, 39, 6), (168, 144, 4)] {
                star(center: accessoryPoint(x: x, y: y + sin(t * 6 + x) * 2), radius: r * Self.presentationRatio, color: Self.pink)
            }
        }
    }

    private var latteRect: NSRect {
        guard let atlas, hasLatteAnimation else { return NSRect(x: 142, y: 138, width: 29, height: 46) }
        let frame = atlas.frames[27]
        let scale = min(29 / Double(frame.width), 46 / Double(frame.height)) * Self.presentationRatio
        let width = Double(frame.width) * scale, height = Double(frame.height) * scale
        let anchor = accessoryPoint(x: 156, y: 185)
        return NSRect(x: anchor.x - width / 2, y: anchor.y - height, width: width, height: height)
    }
    private func latteContains(_ point: NSPoint) -> Bool {
        let rect = offeredLatteRect
        guard let atlas, hasLatteAnimation, rect.contains(point) else { return false }
        let frame = atlas.frames[27]
        return frame.contains(x: (point.x - rect.minX) * Double(frame.width) / rect.width,
                              y: (point.y - rect.minY) * Double(frame.height) / rect.height)
    }
    private var currentLatteOffset: NSPoint {
        guard let began = latteReturnBegan else { return latteOffset }
        let progress = min(1, max(0, (ProcessInfo.processInfo.systemUptime - began) / 0.24))
        let remaining = pow(1 - progress, 3)
        return NSPoint(x: latteOffset.x * remaining, y: latteOffset.y * remaining)
    }
    private var offeredLatteRect: NSRect { latteRect.offsetBy(dx: currentLatteOffset.x, dy: currentLatteOffset.y) }
    private func drawPaperToss() {
        guard let atlas, hasInteractionAnimation else { return }
        let elapsed = previewTime ?? Date().timeIntervalSince(moodBegan)
        guard !paused || previewTime != nil, !reduceMotion, elapsed >= 0.4, elapsed <= 1.4 else { return }
        let progress = min(1, (elapsed - 0.4) / 0.8)
        let point = accessoryPoint(x: 64 - progress * 47, y: 135 + progress * 48 - sin(progress * .pi) * 54)
        let x = point.x, y = point.y
        let frame = atlas.frames[35]
        let scale = min(13 / Double(frame.width), 13 / Double(frame.height)) * Self.presentationRatio
        let rect = NSRect(x: x - Double(frame.width) * scale / 2, y: y - Double(frame.height) * scale / 2, width: Double(frame.width) * scale, height: Double(frame.height) * scale)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState(); ctx.translateBy(x: x, y: y); ctx.rotate(by: progress * 6); ctx.translateBy(x: -x, y: -y)
        frame.image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: max(0, min(1, (1.4 - elapsed) / 0.2)), respectFlipped: true, hints: nil)
        ctx.restoreGState()
    }
    private func drawAffection() {
        guard !paused || previewTime != nil, !reduceMotion else { return }
        let elapsed = previewTime ?? Date().timeIntervalSince(moodBegan)
        let opacity = min(1, max(0, 2.3 - elapsed))
        for (i, x) in [crownRect.minX + 8, crownRect.maxX - 20].enumerated() {
            let y = crownRect.minY - 12 - min(1, elapsed / 1.6) * 9 + Double(i) * 3
            let rows = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
            for (row, bits) in rows.enumerated() {
                for (column, bit) in bits.enumerated() where bit == "1" {
                    Self.pink.withAlphaComponent(opacity * 0.75).setFill()
                    let px = (x / pixelSize).rounded() * pixelSize + Double(column) * pixelSize
                    let py = (y / pixelSize).rounded() * pixelSize + Double(row) * pixelSize
                    NSRect(x: px, y: py, width: pixelSize, height: pixelSize).fill()
                }
            }
        }
    }
    private func drawLatteOffer() {
        guard let atlas, hasLatteAnimation else { return }
        let rect = offeredLatteRect
        ellipse(NSRect(x: rect.minX, y: accessoryPoint(x: 156, y: 185).y, width: rect.width, height: 4 * Self.presentationRatio), .black.withAlphaComponent(isCarryingLatte ? 0.04 : 0.1))
        atlas.frames[27].image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }
    private func drawLatteHandoff() {
        guard let origin = latteHandoffOrigin, let atlas, hasLatteAnimation, !reduceMotion, !paused else { return }
        let elapsed = previewTime ?? Date().timeIntervalSince(moodBegan)
        guard elapsed < 0.3 else { return }
        let progress = min(1, max(0, elapsed / 0.3))
        let eased = progress * progress * (3 - 2 * progress)
        let pose = spritePose(time: animationTime, mood: .coffee, atlas: atlas, forcedIndex: 21)
        let destination = NSPoint(x: pose.rect.midX + pose.rect.width * 0.20, y: pose.rect.minY + pose.rect.height * 0.77)
        let point = NSPoint(x: origin.x + (destination.x - origin.x) * eased, y: origin.y + (destination.y - origin.y) * eased)
        let rect = NSRect(x: point.x - latteRect.width / 2, y: point.y - latteRect.height / 2, width: latteRect.width, height: latteRect.height)
        atlas.frames[27].image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1 - eased, respectFlipped: true, hints: nil)
    }

    private struct Pose {
        var bounce: Double
        var lift: Double
        var wobble: Double
        var headTilt: Double
        var stride: Double
        var elbow: NSPoint
        var hand: NSPoint
    }
    private func geometry(time t: Double, mood: Mood) -> Pose {
        let active = !paused && !reduceMotion
        let waving = mood == .wave || mood == .celebrate
        let handY = waving ? 64 + (active ? sin(t * 8) * 6 : 0) : 138
        return Pose(
            bounce: active ? sin(t * 1.8) * 0.35 : 0,
            lift: mood == .celebrate && active ? abs(sin(t * 6)) * 6 : 0,
            wobble: mood == .pickedUp && active ? sin(t * 9) * 0.08 : 0,
            headTilt: mood == .sideEye ? -0.10 : (mood == .pickedUp ? 0.06 : -0.035),
            stride: mood == .walk && active ? sin(t * 8) * 6 : 0,
            elbow: waving ? NSPoint(x: 145, y: 91) : NSPoint(x: 145, y: 126),
            hand: waving ? NSPoint(x: 159, y: handY) : NSPoint(x: 128, y: 139)
        )
    }
    static let metal = NSColor(calibratedRed: 0.81, green: 0.83, blue: 0.84, alpha: 1)
    static let deep = NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.11, alpha: 1)

    func drawCharacter(time t: Double, mood: Mood) {
        if let atlas { drawSprite(time: previewTime ?? t, mood: mood, atlas: atlas); return }
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let pose = geometry(time: t, mood: mood)
        let active = !paused && !reduceMotion
        ellipse(NSRect(x: 49, y: 185, width: 98, height: 7), .black.withAlphaComponent(0.13))
        ctx.saveGState()
        ctx.translateBy(x: 95, y: 110)
        ctx.rotate(by: pose.wobble)
        ctx.translateBy(x: -95, y: -110 + pose.bounce - pose.lift)

        // Mechanical legs and unapologetic platform boots.
        line([NSPoint(x: 83, y: 140), NSPoint(x: 78 - pose.stride, y: 163)], Self.deep, width: 11)
        line([NSPoint(x: 108, y: 140), NSPoint(x: 116 + pose.stride, y: 163)], Self.deep, width: 11)
        boot(x: 68 - pose.stride, left: true)
        boot(x: 106 + pose.stride, left: false)
        ellipse(NSRect(x: 75 - pose.stride, y: 146, width: 7, height: 7), Self.metal, stroke: Self.deep, width: 1.3)
        ellipse(NSRect(x: 109 + pose.stride, y: 146, width: 7, height: 7), Self.metal, stroke: Self.deep, width: 1.3)

        // Chrome arms, exposed black joints, and a hand-on-hip pose.
        arm(from: NSPoint(x: 70, y: 111), via: NSPoint(x: 58, y: 120), to: NSPoint(x: 44, y: 132))
        arm(from: NSPoint(x: 123, y: 111), via: pose.elbow, to: pose.hand)
        metalFill(torsoPath())
        roundRect(NSRect(x: 78, y: 116, width: 36, height: 18), radius: 4, fill: Self.deep)
        line([NSPoint(x: 85, y: 121), NSPoint(x: 105, y: 121)], Self.metal.withAlphaComponent(0.5), width: 1)
        ellipse(NSRect(x: 91, y: 123, width: 8, height: 8), Self.acid)
        line([NSPoint(x: 95, y: 121), NSPoint(x: 95, y: 127)], Self.deep, width: 1.8)
        line([NSPoint(x: 75, y: 140), NSPoint(x: 114, y: 140)], Self.deep, width: 5)
        roundRect(NSRect(x: 88, y: 138, width: 13, height: 6), radius: 1, fill: Self.pink, stroke: Self.deep, width: 1)

        ctx.saveGState()
        ctx.translateBy(x: 95, y: 67); ctx.rotate(by: pose.headTilt); ctx.translateBy(x: -95, y: -67)
        drawHead(time: t, mood: mood)
        ctx.restoreGState()

        // A little paper square, rather than a bulky notebook.
        ctx.saveGState(); ctx.translateBy(x: 43, y: 128); ctx.rotate(by: -0.12)
        roundRect(NSRect(x: -18, y: -18, width: 36, height: 36), radius: 2, fill: Self.cream, stroke: Self.deep, width: 1.8)
        line([NSPoint(x: -10, y: -8), NSPoint(x: 10, y: -8)], Self.deep.withAlphaComponent(0.25), width: 1.5)
        line([NSPoint(x: -10, y: -2), NSPoint(x: 5, y: -2)], Self.deep.withAlphaComponent(0.25), width: 1.5)
        star(center: NSPoint(x: 7, y: 8), radius: 5, color: Self.pink)
        ctx.restoreGState()
        roundRect(NSRect(x: 28, y: 130, width: 13, height: 9), radius: 3, fill: Self.metal, stroke: Self.deep, width: 2)
        drawHand(at: pose.hand, raised: mood == .wave || mood == .celebrate)
        ctx.restoreGState()

        if mood == .celebrate {
            for (x, y, r) in [(28.0, 43.0, 6.0), (168, 32, 7), (165, 153, 4)] {
                star(center: NSPoint(x: x, y: y + (active ? sin(t * 6 + x) * 3 : 0)), radius: r, color: Self.acid)
            }
        }
        if mood == .sleep {
            text("z", point: NSPoint(x: 159, y: 38), size: 14, color: Self.acid)
            text("z", point: NSPoint(x: 170, y: 24), size: 10, color: Self.pink)
        }
    }

    private func headPath() -> NSBezierPath {
        polygon([NSPoint(x: 52, y: 33), NSPoint(x: 135, y: 33), NSPoint(x: 146, y: 44), NSPoint(x: 146, y: 92), NSPoint(x: 136, y: 102), NSPoint(x: 52, y: 102), NSPoint(x: 43, y: 93), NSPoint(x: 43, y: 43)])
    }
    private func torsoPath() -> NSBezierPath {
        polygon([NSPoint(x: 77, y: 104), NSPoint(x: 114, y: 104), NSPoint(x: 124, y: 114), NSPoint(x: 116, y: 139), NSPoint(x: 108, y: 148), NSPoint(x: 82, y: 148), NSPoint(x: 72, y: 139), NSPoint(x: 67, y: 115)])
    }
    private func drawHead(time t: Double, mood: Mood) {
        let active = !paused && !reduceMotion
        // Pink diamond antenna, brushed casing, screws, and a glossy black visor.
        line([NSPoint(x: 96, y: 34), NSPoint(x: 96, y: 21)], Self.deep, width: 4)
        let antenna = polygon([NSPoint(x: 96, y: 13), NSPoint(x: 103, y: 21), NSPoint(x: 96, y: 28), NSPoint(x: 89, y: 21)])
        paint(antenna, fill: Self.pink, stroke: Self.deep, width: 1.8)
        roundRect(NSRect(x: 138, y: 47, width: 15, height: 41), radius: 4, fill: Self.metal, stroke: Self.deep, width: 2)
        line([NSPoint(x: 149, y: 54), NSPoint(x: 149, y: 79)], Self.deep, width: 2)
        metalFill(headPath())
        line([NSPoint(x: 55, y: 36), NSPoint(x: 132, y: 36)], .white.withAlphaComponent(0.85), width: 1.8)
        for (x, y) in [(49.0, 41.0), (139, 41), (49, 94), (139, 94)] {
            ellipse(NSRect(x: x - 1.6, y: y - 1.6, width: 3.2, height: 3.2), Self.deep.withAlphaComponent(0.6))
        }
        let screen = NSBezierPath(roundedRect: NSRect(x: 52, y: 44, width: 84, height: 46), xRadius: 8, yRadius: 8)
        paint(screen, fill: Self.deep, stroke: Self.ink, width: 2)
        let gloss = polygon([NSPoint(x: 57, y: 48), NSPoint(x: 109, y: 48), NSPoint(x: 87, y: 86), NSPoint(x: 57, y: 86)])
        paint(gloss, fill: .white.withAlphaComponent(0.04), stroke: nil)
        let blink = active && t.truncatingRemainder(dividingBy: 5.1) < 0.12
        let sleeping = mood == .sleep
        for (x, right) in [(61.0, false), (101.0, true)] {
            if blink || sleeping {
                line([NSPoint(x: x, y: 65), NSPoint(x: x + 24, y: 62)], Self.acid, width: 2)
            } else if mood == .pickedUp {
                roundRect(NSRect(x: x + 5, y: 54, width: 13, height: 18), radius: 4, fill: Self.acid)
            } else {
                let y = mood == .sideEye && right ? 56.0 : 59.0
                let eye = polygon([NSPoint(x: x - 3, y: y - 4), NSPoint(x: x + 24, y: y + 1), NSPoint(x: x + 23, y: y + 9), NSPoint(x: x + 8, y: y + 12), NSPoint(x: x + 2, y: y + 6)])
                paint(eye, fill: Self.acid, stroke: nil)
                let gaze = mood == .sideEye ? 17.0 : 12.0
                roundRect(NSRect(x: x + gaze, y: y + 2, width: 3, height: 8), radius: 1, fill: Self.deep)
                // Winged eyeliner and an insolent eyebrow lift are built into the display.
                line([NSPoint(x: x - 4, y: y - 5), NSPoint(x: x + 24, y: y)], Self.pink, width: 1.8)
            }
        }
        if mood == .pickedUp {
            roundRect(NSRect(x: 90, y: 77, width: 8, height: 7), radius: 2, fill: Self.pink)
        } else {
            let smirk = NSBezierPath()
            smirk.move(to: NSPoint(x: 86, y: 79))
            smirk.curve(to: NSPoint(x: 105, y: 76), controlPoint1: NSPoint(x: 93, y: 84), controlPoint2: NSPoint(x: 102, y: 82))
            paint(smirk, fill: nil, stroke: Self.pink, width: 2.2)
        }
        line([NSPoint(x: 63, y: 96), NSPoint(x: 76, y: 96)], Self.deep.withAlphaComponent(0.5), width: 1.5)
        line([NSPoint(x: 81, y: 96), NSPoint(x: 88, y: 96)], Self.deep.withAlphaComponent(0.5), width: 1.5)
        ellipse(NSRect(x: 127, y: 94, width: 4, height: 3), Self.pink)
        // A single hot-pink hoop on the side of the chassis.
        paint(NSBezierPath(ovalIn: NSRect(x: 145, y: 79, width: 10, height: 15)), fill: nil, stroke: Self.pink, width: 2.8)
    }
    private func arm(from start: NSPoint, via elbow: NSPoint, to end: NSPoint) {
        line([start, elbow, end], Self.deep, width: 9)
        line([start, elbow, end], Self.metal, width: 5)
        line([NSPoint(x: start.x - 1, y: start.y - 1), NSPoint(x: elbow.x - 1, y: elbow.y - 1)], .white.withAlphaComponent(0.8), width: 1.2)
        for p in [start, elbow] { ellipse(NSRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8), Self.deep, stroke: Self.metal, width: 1) }
    }
    private func drawHand(at p: NSPoint, raised: Bool) {
        roundRect(NSRect(x: p.x - 6, y: p.y - 6, width: 12, height: 11), radius: 3, fill: Self.metal, stroke: Self.deep, width: 1.6)
        if raised {
            line([NSPoint(x: p.x - 3, y: p.y - 3), NSPoint(x: p.x - 5, y: p.y - 16)], Self.deep, width: 4)
            line([NSPoint(x: p.x + 3, y: p.y - 3), NSPoint(x: p.x + 6, y: p.y - 16)], Self.deep, width: 4)
            line([NSPoint(x: p.x - 5, y: p.y - 15), NSPoint(x: p.x - 5, y: p.y - 19)], Self.pink, width: 2.5)
            line([NSPoint(x: p.x + 6, y: p.y - 15), NSPoint(x: p.x + 6, y: p.y - 19)], Self.pink, width: 2.5)
        } else {
            line([NSPoint(x: p.x - 3, y: p.y), NSPoint(x: p.x + 6, y: p.y + 3)], Self.pink, width: 2)
        }
    }
    private func boot(x: Double, left: Bool) {
        let shaft = polygon([NSPoint(x: x + 3, y: 151), NSPoint(x: x + 19, y: 151), NSPoint(x: x + 22, y: 174), NSPoint(x: x - 1, y: 174)])
        paint(shaft, fill: Self.pink, stroke: Self.deep, width: 2)
        line([NSPoint(x: x + 6, y: 154), NSPoint(x: x + 5, y: 168)], .white.withAlphaComponent(0.7), width: 2)
        let footX = left ? x - 7 : x
        roundRect(NSRect(x: footX, y: 172, width: 32, height: 13), radius: 3, fill: Self.deep, stroke: Self.deep, width: 2)
        roundRect(NSRect(x: footX, y: 180, width: 32, height: 5), radius: 1, fill: Self.acid)
        line([NSPoint(x: footX + 5, y: 176), NSPoint(x: footX + 18, y: 176)], Self.pink, width: 2)
    }
    private func polygon(_ points: [NSPoint]) -> NSBezierPath {
        let p = NSBezierPath(); p.move(to: points[0]); for point in points.dropFirst() { p.line(to: point) }; p.close(); return p
    }
    private func metalFill(_ path: NSBezierPath) {
        let colors = [NSColor.white, NSColor(calibratedWhite: 0.9, alpha: 1), Self.metal, NSColor(calibratedWhite: 0.94, alpha: 1)]
        NSGradient(colors: colors)?.draw(in: path, angle: 35)
        paint(path, fill: nil, stroke: Self.deep, width: 2.3)
    }

    private func paint(_ path: NSBezierPath, fill: NSColor?, stroke: NSColor?, width: Double = 2) {
        if let fill { fill.setFill(); path.fill() }
        if let stroke { stroke.setStroke(); path.lineWidth = width; path.lineCapStyle = .round; path.lineJoinStyle = .round; path.stroke() }
    }
    private func ellipse(_ rect: NSRect, _ fill: NSColor, stroke: NSColor? = nil, width: Double = 2) {
        paint(NSBezierPath(ovalIn: rect), fill: fill, stroke: stroke, width: width)
    }
    private func roundRect(_ rect: NSRect, radius: Double, fill: NSColor, stroke: NSColor? = nil, width: Double = 2) {
        paint(NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius), fill: fill, stroke: stroke, width: width)
    }
    private func line(_ points: [NSPoint], _ color: NSColor, width: Double) {
        let path = NSBezierPath(); path.move(to: points[0]); for point in points.dropFirst() { path.line(to: point) }
        paint(path, fill: nil, stroke: color, width: width)
    }
    private func star(center: NSPoint, radius: Double, color: NSColor) {
        let p = NSBezierPath()
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4 - .pi / 2
            let r = i % 2 == 0 ? radius : radius * 0.32
            let point = NSPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { p.move(to: point) } else { p.line(to: point) }
        }
        p.close(); paint(p, fill: color, stroke: nil)
    }
    private func text(_ value: String, point: NSPoint, size: Double, color: NSColor) {
        (value as NSString).draw(at: point, withAttributes: [.font: NSFont.systemFont(ofSize: size, weight: .bold), .foregroundColor: color])
    }
}
