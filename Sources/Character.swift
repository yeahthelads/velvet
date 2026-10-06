import AppKit

enum Mood: String, CaseIterable {
    case styling
    case drawing, offerDrawing, drawingThanks
    case windDown, nightSleep, bellySleep, yoga, reserved
    case ironNeed, ironLow, ironSnack
    case hungry, snack, attention, acknowledged, phone, phoneSulk, yawn, naturalNap, contemporary
    case plugIn, listening, unplug
    case idle, walk, wave, pickedUp, sleep, sideEye, celebrate, ballet, floorwork, vogue, grumpy, coffee
    case paperOpen, paperClose, paperToss, affection, annoyed
    case stretch, focusNap, wakeUp, tumble, crying, recover
    case zoomies, reconcile, shySmile, disco
    case restless, showOff, takeBow, disappointed, overstimulated, house, waacking, breakdance
    var isChoreography: Bool { self == .contemporary || self == .ballet || self == .floorwork || self == .vogue || self == .disco || self == .house || self == .waacking || self == .breakdance }
    static let danceChoices: [Mood] = [.ballet, .breakdance, .contemporary, .floorwork, .house, .disco, .vogue, .waacking]
    static let automaticDances: [Mood] = [.ballet, .floorwork, .disco, .house]
    var danceTitle: String {
        switch self {
        case .contemporary: return "Contemporary"
        case .ballet: return "Ballet"
        case .floorwork: return "Floorwork"
        case .vogue: return "Vogue Fem"
        case .disco: return "Robot disco"
        case .house: return "House"
        case .waacking: return "Waacking"
        case .breakdance: return "Breakdance"
        default: return label
        }
    }
    var isScheduled: Bool { [.windDown, .nightSleep, .bellySleep].contains(self) }
    var isLifestyle: Bool { [.ironNeed, .ironLow, .yoga, .reserved, .windDown, .nightSleep, .bellySleep, .hungry, .snack, .attention, .acknowledged, .phone, .phoneSulk, .yawn, .naturalNap].contains(self) }
    var isHeadphones: Bool { self == .plugIn || self == .listening || self == .unplug }
    var isDance: Bool { isChoreography || self == .zoomies }
    var isPaper: Bool { self == .paperOpen || self == .paperClose || self == .paperToss }
    var isInteraction: Bool { self == .styling || self == .drawingThanks || isPaper || self == .ironSnack || self == .coffee || self == .affection || self == .annoyed || self == .tumble || self == .crying || self == .recover || self == .takeBow || self == .disappointed || self == .wakeUp || self == .snack || self == .acknowledged }
    var label: String {
        switch self {
        case .styling: return "Checking her look"
        case .drawing: return "Making something for you"
        case .offerDrawing: return "A little drawing for you"
        case .drawingThanks: return "She’s glad you kept it"
        case .windDown: return "Series time"
        case .nightSleep: return "Good night"
        case .bellySleep: return "Clumsy beauty sleep"
        case .yoga: return "A little yoga"
        case .reserved: return "Keeping herself company"
        case .ironNeed: return "Screws, please"
        case .ironLow: return "Running low on iron"
        case .ironSnack: return "A metallic little snack"
        case .hungry: return "Protein. Obviously."
        case .snack: return "Unwrapping, approvingly"
        case .attention: return "Look at me"
        case .acknowledged: return "Yes. Very impressive."
        case .phone: return "Do not disturb my scroll"
        case .phoneSulk: return "You can wait"
        case .yawn: return "Being fabulous is exhausting"
        case .naturalNap: return "Beauty nap"
        case .contemporary: return "Contemporary"
        case .plugIn: return "Putting on headphones"
        case .listening: return "Listening to your music"
        case .unplug: return "Putting headphones away"
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
        case .breakdance: return "A little breakdance"
        case .restless: return "Needs a dance break"
        case .showOff: return "Waiting for applause"
        case .takeBow: return "Thank you, darling"
        case .disappointed: return "You missed my finish"
        case .overstimulated: return "A little quiet, please"
        }
    }
}

final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class CharacterView: NSView {
    var mood: Mood = .wave {
        didSet {
            updateAnimationClock()
            if oldValue == .coffee && mood != .coffee { audio.stopCoffee() }
            // Idle sleep is entered directly by the clock, once per sleep.
            if (mood == .sleep || mood == .naturalNap || mood == .nightSleep || mood == .bellySleep || mood == .overstimulated) && oldValue != mood && previewTime == nil && !screenLocked { audio.playQuiet() }
            if mood == .focusNap && oldValue != .focusNap && previewTime == nil && (focusRest != .focusNap || !focusNapSoundPlayed) {
                focusNapSoundPlayed = true
                audio.playQuiet()
            }
        }
    }
    let audio = CompanionAudio()
    var externalAudioPlaying = false
    var listensToAudio = true { didSet { if !listensToAudio { listeningState.reset(); if mood.isHeadphones { mood = baseMood } }; needsDisplay = true } }
    private(set) var listeningState = ListeningState()
    var styling = StylingState() { didSet { if styling.imageKey != oldValue.imageKey { cachedPixelImage = nil; cachedVisual = nil; needsDisplay = true } } }
    var onStylingChanged: ((StylingState) -> Void)?
    var stylingSideEye = false
    private var stylingSoundPlayed = false
    var canStyle: Bool {
        canInteract && canGiveNotes && dailyRoutine.period == .awake && scheduledMood == nil &&
        !tutorialActive && !paused && !noteIsVisible && focusRest == nil && !hasLifestyleActivity &&
        !coffeeOverload.occupied && !drawingGift.working && !mood.isDance && !mood.isHeadphones && mood != .sleep && !isBusy && !performance.awaitingApplause
    }
    @discardableResult func selectStyle(_ item: Cosmetic, sideEye: Bool? = nil) -> Bool {
        guard canStyle else { return false }
        var next = styling, progress = danceProgress
        if next.purchased.contains(item) { guard next.toggle(item) else { return false } }
        else { guard next.buy(item, progress: &progress) else { return false } }
        styling = next; danceProgress = progress
        onStylingChanged?(styling)
        stylingSoundPlayed = false
        stylingSideEye = sideEye ?? (Int.random(in: 0..<4) == 0)
        react(.styling, duration: 4.2); return true
    }
    var drawingGift = DrawingGiftState()
    var onDrawingGiftChanged: ((DrawingGiftState) -> Void)?
    var onDrawingGiftAccepted: ((DrawingKeepsake) -> Void)?
    private lazy var drawingImage = Bundle.main.url(forResource: "drawing-robots-kiss-v1", withExtension: "png").flatMap { NSImage(contentsOf: $0) }
    var lifestyle = LifestyleState()
    var onLifestyleChanged: ((LifestyleState) -> Void)?
    var onAffection: (() -> Void)?
    var tutorialActive = false
    var activity = ActivityState()
    var iron = IronState()
    var onIronChanged: ((IronState) -> Void)?
    var screwOffset = NSPoint.zero
    var screwPickupOffset = NSPoint.zero
    var screwReturnBegan: Double?
    var screwHandoffStart: NSPoint?
    var isCarryingScrews: Bool { gesture?.phase == .carryingScrews }
    let screwButton = NSButton(title: "", target: nil, action: nil)
    var coffeeOverload = CoffeeOverload()
    var onCoffeeOverloadChanged: ((CoffeeOverload) -> Void)?
    var onDanceLost: ((Mood) -> Void)?
    var happiness = HappinessState()
    var onHappinessChanged: ((HappinessState) -> Void)?
    private(set) var screenLocked = false
    private(set) var nightVisit = NightVisit()
    var onNightVisitChanged: (() -> Void)?
    var isNightVisit: Bool { dailyRoutine.period == .asleep && nightVisit.active }
    var animationClockRunning: Bool { clockActive }
    var solitaryYoga = SolitaryYoga()
    var onActivityChanged: ((ActivityState) -> Void)?
    var dailyRoutine = DailyRoutine()
    var scheduledMood: Mood? {
        if screenLocked { return .nightSleep }
        guard !tutorialActive else { return nil }
        switch dailyRoutine.period {
        case .awake: return nil
        case .windingDown: return .windDown
        case .asleep: return nightVisit.active ? nil : (dailyRoutine.bellySleep ? .bellySleep : .nightSleep)
        }
    }
    func recordActivity(_ interaction: ActivityState.Interaction, at time: Double = ProcessInfo.processInfo.systemUptime) {
        solitaryYoga.interact()
        guard dailyRoutine.period == .awake, scheduledMood == nil, !tutorialActive, !awaitingSong else { return }
        if activity.interact(interaction, at: time) { onActivityChanged?(activity) }
    }
    func applyDailyRoutine(_ value: DailyRoutine, waking: Bool = false) {
        let previousPeriod = dailyRoutine.period
        if previousPeriod != value.period { nightVisit.end(); onNightVisitChanged?() }
        dailyRoutine = value
        wakingFromNight = waking
        closingLaptop = previousPeriod == .windingDown && value.period == .asleep
        if let scheduledMood {
            cancelDance(); responses.cancelZoomies(); performance.cancelApplause(); listeningState.reset()
            gesture = nil; mouseOrigin = nil; dragOrigin = nil
            barOffset = .zero; barReturnBegan = nil; screwOffset = .zero; screwReturnBegan = nil; latteOffset = .zero; latteReturnBegan = nil
            mood = scheduledMood; moodBegan = Date(); moodUntil = .distantFuture
        } else if waking && !tutorialActive {
            lifestyle.restAfterNight(); onLifestyleChanged?(lifestyle)
            react(.wakeUp, duration: 4.2)
            wakingFromNight = true
        }
        syncCompanionButtons(); needsDisplay = true; onPerformanceChanged?()
    }
    func setScreenLocked(_ locked: Bool, restedSeconds: Double = 0) {
        guard screenLocked != locked else { return }
        screenLocked = locked; nightVisit.end(); onNightVisitChanged?()
        if locked {
            applyDailyRoutine(dailyRoutine)
            audio.stopAll(); stop(); syncCompanionButtons(); audio.playQuiet()
        } else {
            lifestyle.restWhileLocked(by: restedSeconds); onLifestyleChanged?(lifestyle)
            mood = baseMood; moodBegan = Date(); moodUntil = .distantFuture
            syncCompanionButtons(); needsDisplay = true
        }
    }
    @discardableResult func wakeForNightVisit() -> Bool {
        guard !screenLocked, dailyRoutine.period == .asleep, !tutorialActive, !paused,
              window?.isVisible == true, nightVisit.wake() else { return false }
        mood = .wakeUp; moodBegan = Date(); moodUntil = Date().addingTimeInterval(4.2)
        wakingFromNight = true; needsDisplay = true; onNightVisitChanged?(); onPerformanceChanged?()
        return true
    }
    func returnToBed() {
        guard nightVisit.active else { return }
        nightVisit.end(); applyDailyRoutine(dailyRoutine); onNightVisitChanged?()
    }
    func advanceNightVisit(by seconds: Double) {
        if nightVisit.advance(by: seconds, available: !screenLocked && !paused && window?.isVisible == true) {
            applyDailyRoutine(dailyRoutine); onNightVisitChanged?()
        }
    }
    func disappoint(_ reason: HappinessState.Disappointment) {
        guard !tutorialActive else { return }
        happiness.disappoint(reason); onHappinessChanged?(happiness)
    }
    func receiveCare(_ care: HappinessState.Care) {
        guard !screenLocked, dailyRoutine.period == .awake, !tutorialActive, !awaitingSong else { return }
        if happiness.receive(care) {
            onHappinessChanged?(happiness)
            let oldStyling = styling
            styling.recordCare(care)
            if styling != oldStyling { onStylingChanged?(styling) }
            let oldGift = drawingGift
            drawingGift.recordCare(care)
            if oldGift != drawingGift { onDrawingGiftChanged?(drawingGift) }
        }
    }
    var drawingGiftAvailable: Bool {
        dailyRoutine.period == .awake && scheduledMood == nil && window?.isVisible == true && !paused &&
        canGiveNotes && canInteract && !tutorialActive && !noteIsVisible && focusRest == nil &&
        !hasLifestyleActivity && !wantsCoffee && !needsAffection && !coffeeOverload.occupied &&
        !responses.isActive && !performance.awaitingApplause && !mood.isDance && !mood.isInteraction &&
        mood != .yoga && mood != .sleep && gesture == nil
    }
    var showsDrawing: Bool {
        drawingGift.hasUnclaimed && canInteract && scheduledMood == nil && !tutorialActive &&
        !hasLifestyleActivity && !wantsCoffee && !needsAffection && focusRest == nil && !noteIsVisible &&
        (drawingGift.phase == .waiting || mood == .offerDrawing)
    }
    var drawingHitbox: NSRect {
        if mood == .offerDrawing, let atlas {
            let rect = spritePose(time: animationTime, mood: .offerDrawing, atlas: atlas).rect
            return NSRect(x: rect.minX + rect.width * 0.27, y: rect.minY + rect.height * 0.56,
                width: rect.width * 0.46, height: rect.height * 0.26).insetBy(dx: -3, dy: -3)
        }
        return NSRect(x: 135, y: 168, width: 30, height: 22)
    }
    func advanceDrawingGift(by seconds: Double) {
        let oldPhase = drawingGift.phase
        drawingGift.advance(by: seconds, available: drawingGiftAvailable, happiness: happiness.level)
        if oldPhase != drawingGift.phase {
            listeningState.reset()
            if drawingGiftAvailable || oldPhase == .offering {
                mood = baseMood; moodBegan = Date(); moodUntil = drawingGift.working ? .distantFuture : .distantPast
            }
            updateAccessibilityHelp(); onDrawingGiftChanged?(drawingGift); onPerformanceChanged?()
            needsDisplay = true
        } else if drawingGift.working && drawingGiftAvailable && mood != baseMood {
            mood = baseMood; moodBegan = Date(); moodUntil = .distantFuture; needsDisplay = true
        }
    }
    @discardableResult func acceptDrawingGift() -> Bool {
        guard showsDrawing, let picture = drawingGift.accept() else { return false }
        styling.updateHistory(from: drawingGift); onStylingChanged?(styling)
        onDrawingGiftChanged?(drawingGift); onDrawingGiftAccepted?(picture)
        react(.drawingThanks, duration: 3.0); updateAccessibilityHelp(); needsDisplay = true; return true
    }
    private var wakingFromNight = false
    private var closingLaptop = false
    private var hoverBegan: Double?
    private var hoverRewarded = false
    private var barOffset = NSPoint.zero
    private var barReturnBegan: Double?
    private var barPickupOffset = NSPoint.zero
    var isCarryingBar: Bool { gesture?.phase == .carryingBar }
    var pointerIsActive: Bool { gesture != nil }
    private var currentBarOffset: NSPoint {
        guard let began = barReturnBegan else { return barOffset }
        let u = min(1, max(0, (ProcessInfo.processInfo.systemUptime - began) / 0.24))
        let remainder = CGFloat(1 - u * u * (3 - 2 * u))
        return NSPoint(x: barOffset.x * remainder, y: barOffset.y * remainder)
    }
    var offeredBarRect: NSRect {
        NSRect(x: 135, y: 166, width: 29, height: 15).offsetBy(dx: currentBarOffset.x, dy: currentBarOffset.y)
    }
    var barHandRect: NSRect {
        guard let atlas, hasDailyAnimation else { return NSRect(x: 107, y: 137, width: 28, height: 25) }
        let pose = spritePose(time: animationTime, mood: .hungry, atlas: atlas, forcedIndex: 101)
        return NSRect(x: pose.rect.midX + pose.rect.width * 0.18, y: pose.rect.minY + pose.rect.height * 0.58,
                      width: pose.rect.width * 0.31, height: pose.rect.height * 0.24)
    }
    /// The whole receiving area, rather than a tiny cursor-only palm hitbox.
    var screwDropRect: NSRect {
        guard let atlas, hasDailyAnimation else { return NSRect(x: 72, y: 124, width: 69, height: 58) }
        let rect = spritePose(time: animationTime, mood: .ironNeed, atlas: atlas, receiving: false, forcedIndex: 101).rect
        return NSRect(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.30,
                      width: rect.width * 0.80 + 7, height: rect.height * 0.66)
    }
    var awaitingSong = false {
        didSet {
            guard awaitingSong != oldValue else { return }
            if awaitingSong {
                audio.stopAll(); listeningState.reset(); responses.cancelZoomies()
                performance.cancelApplause(); cancelDance()
                gesture = nil; mouseOrigin = nil; dragOrigin = nil; pendingPaper = nil
                barOffset = .zero; barReturnBegan = nil; screwOffset = .zero; screwReturnBegan = nil; latteOffset = .zero; latteReturnBegan = nil
                mood = baseMood; moodBegan = Date(); moodUntil = .distantFuture
            } else { mood = baseMood; moodUntil = .distantPast }
            syncCompanionButtons(); updateAccessibilityHelp(); needsDisplay = true
            onNeedsChanged?(); onPerformanceChanged?()
        }
    }
    private var paidDanceInProgress = false
    var hasLifestyleActivity: Bool { lifestyle.occupied || lifestyle.hungry || lifestyle.needsAttention || iron.needsScrews || iron.eating }
    var danceRequirementsMet: Bool { !drawingGift.working && dailyRoutine.period == .awake && scheduledMood == nil && canGiveNotes && lifestyle.readyToDance && !tutorialActive && !coffeeOverload.occupied && !iron.needsScrews && !iron.eating && !noteIsVisible && focusRest == nil && !reduceMotion }
    var hasHeadphones: Bool { mood.isHeadphones }

    private var pausedAt: Date?
    var paused = false {
        didSet {
            guard paused != oldValue else { return }
            if paused { pausedAt = Date() }
            else {
                if let began = pausedAt, mood == .coffee || mood.isChoreography {
                    let elapsed = Date().timeIntervalSince(max(began, moodBegan))
                    moodBegan = moodBegan.addingTimeInterval(elapsed)
                    moodUntil = moodUntil.addingTimeInterval(elapsed)
                }
                pausedAt = nil
            }
            updateCompanionAudio(); updateAnimationClock()
            needsDisplay = true
        }
    }
    var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    var onClick: (() -> Void)?
    var onMove: (() -> Void)?
    var onDrop: (() -> Void)?
    var onCoffee: (() -> Void)?
    var onNeedsChanged: (() -> Void)?
    var onPerformanceChanged: (() -> Void)?
    var onDanceProgressChanged: ((DanceProgress) -> Void)?
    var danceProgress = DanceProgress() {
        didSet {
            guard danceProgress != oldValue else { return }
            let previousStyle = styling
            styling.updateProgress(from: danceProgress)
            onDanceProgressChanged?(danceProgress)
            if styling != previousStyle { onStylingChanged?(styling) }
            updateAccessibilityHelp(); onPerformanceChanged?()
        }
    }
    var availableDances: [Mood] { Mood.danceChoices.filter { danceProgress.allows($0.rawValue) } }
    var applauseOpacity: CGFloat { applauseButton.alphaValue }
    var care = CompanionCare() {
        didSet {
            if care.upset != oldValue.upset {
                if care.needsAffection { responses.upset(); performance.cancelApplause(); cancelDance() }
                pendingPaper = nil
                mood = baseMood
                moodBegan = Date()
                moodUntil = needsAffection ? .distantFuture : Date()
                if care.upset == .annoyed && canInteract { audio.playCrossedArms() }
                updateAccessibilityHelp()
                needsDisplay = true
                onNeedsChanged?()
            }
        }
    }
    private var focusNapSoundPlayed = false
    var focusStretchElapsed: Double?
    var focusRest: Mood? {
        didSet {
            guard focusRest != oldValue else { return }
            if focusRest != .focusNap { focusNapSoundPlayed = false }
            if focusRest != nil { if canInteract { audio.stopAll() }; responses.cancelZoomies(); performance.cancelApplause(); cancelDance() }
            if focusRest != nil && mood == .wakeUp { mood = baseMood; moodUntil = .distantPast }
            if canGiveNotes && !isBusy { mood = baseMood; needsDisplay = true }
        }
    }
    var needsAffection: Bool { care.needsAffection }
    var canInteract: Bool { !screenLocked && !awaitingSong && !stimulation.overstimulated && !coffeeOverload.crashed && !lifestyle.ignoring }
    var canGiveNotes: Bool { !screenLocked && !awaitingSong && !stimulation.overstimulated && !coffeeOverload.crashed && care.canGiveNotes(needsCoffee: wantsCoffee) }
    var baseMood: Mood {
        if let scheduledMood { return scheduledMood }
        if awaitingSong { return .sideEye }
        if stimulation.overstimulated || coffeeOverload.crashed { return .overstimulated }
        if coffeeOverload.phase == .sipping { return .coffee }
        if coffeeOverload.phase == .hyped { return noteIsVisible || focusRest != nil || reduceMotion ? .celebrate : .zoomies }
        if lifestyle.ignoring { return .phoneSulk }
        if care.upset == .crying { return .crying }
        if care.upset == .annoyed { return .annoyed }
        if wantsCoffee { return .grumpy }
        if isNightVisit { return .yawn }
        if let focusRest { return focusRest }
        if iron.eating { return .ironSnack }
        switch lifestyle.phase {
        case .snack: return .snack
        case .attention: return activity.withdrawn ? .reserved : .attention
        case .phone: return .phone
        case .ignoring: return .phoneSulk
        case .yawning: return .yawn
        case .nap: return .naturalNap
        case .waking: return .wakeUp
        case .idle: break
        }
        if lifestyle.hungry { return .hungry }
        if lifestyle.needsAttention { return activity.withdrawn ? .reserved : .attention }
        if iron.needsScrews { return iron.lowIron ? .ironLow : .ironNeed }
        if drawingGift.working && drawingGiftAvailable { return drawingGift.phase == .drawing ? .drawing : .offerDrawing }
        if performance.awaitingApplause { return .showOff }
        switch responses.phase {
        case .zoomies: return .zoomies
        case .reconciliation: return .reconcile
        case .shySmile: return .shySmile
        case .idle:
            if performance.restless && danceProgress.allows("ballet") { return .restless }
            switch listeningState.phase {
            case .puttingOn: return .plugIn
            case .listening: return .listening
            case .takingOff: return .unplug
            case .inactive: return .idle
            }
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
    var stimulation = StimulationState() {
        didSet {
            guard stimulation.overstimulated != oldValue.overstimulated else { return }
            if stimulation.overstimulated { disappoint(.overwhelmed); enterQuietMood() }
            else {
                mood = baseMood; moodUntil = Date(); idleSince = Date()
                updateAccessibilityHelp(); needsDisplay = true
                onNeedsChanged?(); onPerformanceChanged?()
            }
        }
    }
    private let applauseButton = NSButton(title: "👏", target: nil, action: nil)
    private let snackButton = NSButton(title: "", target: nil, action: nil)
    private let danceButton = NSButton(title: "🩰", target: nil, action: nil)
    private var danceInProgress = false
    private var danceChosen = false
    private var showOffPose = 17
    private var heldFinish: (index: Int, rect: NSRect, angle: Double)?
    var hasGentleResponse: Bool { responses.isReconciling }
    var noteIsVisible = false {
        didSet {
            if noteIsVisible && !oldValue {
                solitaryYoga.interact()
                if danceInProgress && paidDanceInProgress { _ = danceProgress.refundReplay() }
                if danceInProgress { lifestyle.cancelDanceForNotes(); onLifestyleChanged?(lifestyle) }
                cancelDance(); responses.cancelZoomies(); performance.cancelApplause()
                if mood.isDance || mood == .showOff { mood = baseMood; moodUntil = Date() }
            }
            updateAccessibilityHelp(); onPerformanceChanged?()
        }
    }
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
    var hasBreakdanceAnimation: Bool { spriteFrameCount >= 84 }
    var hasLifestyleAnimation: Bool { spriteFrameCount >= 100 }
    var hasDailyAnimation: Bool { spriteFrameCount >= 116 }
    var snackButtonRect: NSRect {
        if hasDailyAnimation { return offeredBarRect.insetBy(dx: -3, dy: -3) }
        guard let atlas else { return NSRect(x: 123, y: 161, width: 28, height: 24) }
        let rect = spritePose(time: animationTime, mood: .hungry, atlas: atlas).rect
        return NSRect(x: rect.maxX - rect.width * 0.39, y: rect.maxY - rect.height * 0.3, width: rect.width * 0.41, height: rect.height * 0.32).insetBy(dx: -3, dy: -3)
    }
    override func hitTest(_ point: NSPoint) -> NSView? {
        // AppKit supplies hit-test points in the superview's coordinates. This
        // character is flipped; its borderless window's theme frame is not.
        // Checking the raw point lets the transparent prop button consume drags.
        let local = convert(point, from: superview)
        if showsDrawing && drawingHitbox.contains(local) { return self }
        if showsScrews && screwHitbox.contains(local) { return self }
        if !snackButton.isHidden && snackButtonRect.contains(local) { return self }
        return super.hitTest(point)
    }
    var isBusy: Bool { (drawingGift.working && drawingGiftAvailable) || (mood.isInteraction || mood == .yoga) && Date() < moodUntil }
    private var moodBegan = Date()
    private let sipDuration = 6.0
    private var born = Date()
    private var clock: Timer?
    private var clockActive = false
    private var globalPointerMonitor: Any?
    private var localPointerMonitor: Any?
    private var lastVisual: VisualState?
    private struct VisualState: Equatable {
        let mood: Mood
        let index: Int
        let rect: NSRect
        let angle: Double
        let bounds: NSRect
        let paused: Bool
        let reduced: Bool
    }
    private var visualState: VisualState? {
        guard let atlas else { return nil }
        let pose = spritePose(time: animationTime, mood: mood, atlas: atlas)
        return VisualState(mood: mood, index: pose.index, rect: pose.rect, angle: pose.angle, bounds: bounds, paused: paused, reduced: reduceMotion)
    }
    var animationInterval: TimeInterval {
        if gesture != nil || latteReturnBegan != nil || barReturnBegan != nil || screwReturnBegan != nil { return 1.0 / 24 }
        if paused || reduceMotion { return 0.25 }
        if mood == .styling || mood == .drawing || mood == .offerDrawing { return 1.0 / 8 }
        if showsApplause { return 1.0 / 24 }
        if mood == .phoneSulk && Date().timeIntervalSince(moodBegan) < 1.2 { return 1.0 / 24 }
        if [.nightSleep, .bellySleep, .windDown, .naturalNap, .focusNap, .yoga, .reserved, .phone, .phoneSulk, .showOff, .sleep].contains(mood) { return 0.25 }
        if [.ironNeed, .ironLow, .idle, .sideEye, .grumpy, .hungry, .annoyed, .attention, .overstimulated].contains(mood) { return 1.0 / 12 }
        return 1.0 / 24
    }
    private func updateAnimationClock() {
        guard clockActive else { return }
        let interval = animationInterval
        guard clock?.timeInterval != interval else { return }
        clock?.invalidate()
        clock = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.tick() }
        clock?.tolerance = interval * 0.1
        RunLoop.main.add(clock!, forMode: .common)
    }
    private var idleSince = Date()
    private var dragOrigin: NSPoint?
    private var mouseOrigin: NSPoint?
    private var hovering = false
    private var nextIdle = Date().addingTimeInterval(12)
    private var idleSequence = 0
    private var pixelCanvas: NSBitmapImageRep?
    private var pixelContext: NSGraphicsContext?
    private var pixelDrawingContext: NSGraphicsContext?
    private var cachedPixelImage: NSImage?
    private var cachedVisual: VisualState?
    private var canReusePixels: Bool {
        previewTime == nil && gesture == nil && latteReturnBegan == nil && barReturnBegan == nil && screwReturnBegan == nil && !showsScrews && !iron.eating && !wantsCoffee &&
        (paused || reduceMotion || [.nightSleep, .bellySleep, .windDown, .naturalNap, .focusNap, .yoga, .reserved, .phone, .phoneSulk, .showOff, .wakeUp].contains(mood))
    }
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
        applauseButton.wantsLayer = true
        applauseButton.toolTip = "Applaud before the countdown fades · she'll take a little bow"
        applauseButton.setAccessibilityLabel("Applaud Velvet")
        applauseButton.isHidden = true
        addSubview(applauseButton)
        danceButton.target = self; danceButton.action = #selector(danceChooserPressed)
        danceButton.isBordered = false; danceButton.bezelStyle = .regularSquare
        danceButton.font = .systemFont(ofSize: 19)
        danceButton.toolTip = "Choose a dance · three timely claps earn a new routine"
        danceButton.setAccessibilityLabel("Choose a dance for Velvet")
        danceButton.isHidden = true
        addSubview(danceButton)
        snackButton.target = self; snackButton.action = #selector(snackPressed)
        snackButton.isBordered = false; snackButton.setAccessibilityLabel("Give Velvet her robot protein bar")
        snackButton.toolTip = "Drag her chocolate protein bar into her open hand."
        snackButton.isHidden = true; addSubview(snackButton)
        screwButton.target = self; screwButton.action = #selector(screwsPressed)
        screwButton.isBordered = false; screwButton.isHidden = true
        screwButton.setAccessibilityLabel("Feed Velvet screws for iron")
        screwButton.toolTip = "Drag the silver screws into her open hand."
        addSubview(screwButton)
        updateAccessibilityHelp()
        if let url = Bundle.main.url(forResource: "velvet-sprites-v5", withExtension: "png") {
            atlas = SpriteAtlas(url: url, additionalURL: Bundle.main.url(forResource: "vogue-sprites-v2", withExtension: "png"), latteURL: Bundle.main.url(forResource: "iced-latte-sprites-v2", withExtension: "png"), interactionURL: Bundle.main.url(forResource: "interaction-sprites-v2", withExtension: "png"), wellbeingURL: Bundle.main.url(forResource: "wellbeing-sprites-v1", withExtension: "png"), discoURL: Bundle.main.url(forResource: "disco-sprites-v1", withExtension: "png"), clubURL: Bundle.main.url(forResource: "club-sprites-v1", withExtension: "png"), stretchURL: Bundle.main.url(forResource: "stretch-sprites-v1", withExtension: "png"), breakdanceURL: Bundle.main.url(forResource: "breakdance-sprites-v1", withExtension: "png"), lifestyleURL: Bundle.main.url(forResource: "care-sprites-v2", withExtension: "png"), dailyURL: Bundle.main.url(forResource: "daily-sprites-v1", withExtension: "png"), yogaURL: Bundle.main.url(forResource: "yoga-sprites-v2", withExtension: "png"), drawingURL: Bundle.main.url(forResource: "drawing-sprites-v1", withExtension: "png"), stylingURL: Bundle.main.url(forResource: "styling-sprites-v1", withExtension: "png"))
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func accessibilityPerformPress() -> Bool { guard acceptCharacterInteraction() else { return false }; if acknowledgeAttention() { return true }; onClick?(); return true }
    func updateAccessibilityHelp() {
        var help = "Click her face or body for notes. Stroke or hold her head briefly for affection. Drag her body or Option-drag to move."
        if lifestyle.hungry { help += " She wants a robot protein bar before dancing. Drag the chocolate bar into her open hand." }
        if iron.needsScrews {
            help += iron.freeOfferAvailable ? " She needs iron. Drag the silver screws into her hand within two minutes." : " Her iron is low, making her sleepier. Give her screws from the menu for one clap, or wait for the free offer after her cooldown."
        }
        if lifestyle.phase == .attention { help += " She wants you to notice her. Click her to acknowledge." }
        if lifestyle.ignoring { help += " Her phone time was interrupted. Give her forty-five seconds to cool off. Notes remain available from the menu or shortcut." }
        if lifestyle.phase == .nap { help += " She is resting. Notes remain available." }
        if needsAffection { help += " She needs affection before she will return your notes." }
        if showsDrawing { help += " Click the little picture to keep her drawing." }
        if awaitingSong { help += " She wants her requested song in Spotify before resuming." }
        if wantsCoffee { help += " She needs an iced latte before she will return your notes. Drag the cup into her hand or click it." }
        if performance.restless { help += " Click the ballet-shoes button beside her to choose an unlocked dance. Three timely claps earn a new routine." }
        if performance.awaitingApplause { help += " Click the clapping-hands button beside her to applaud; she will take a little bow." }
        if stimulation.overstimulated { help += " Too much fuss. Give her thirty seconds of quiet. She cannot be interacted with until she settles." }
        setAccessibilityHelp(help)
        syncCompanionButtons()
    }

    func start() {
        guard !screenLocked else { return }
        lastResponseTick = ProcessInfo.processInfo.systemUptime
        clockActive = true; updateAnimationClock()
        if globalPointerMonitor == nil {
            globalPointerMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in self?.updatePointerPresence() }
            localPointerMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in self?.updatePointerPresence(); return event }
        }
        updatePointerPresence()
    }
    func stop() {
        audio.stopAll(); listeningState.reset()
        if mood.isHeadphones { mood = baseMood }
        clockActive = false; clock?.invalidate(); clock = nil
        if let globalPointerMonitor { NSEvent.removeMonitor(globalPointerMonitor) }
        if let localPointerMonitor { NSEvent.removeMonitor(localPointerMonitor) }
        globalPointerMonitor = nil; localPointerMonitor = nil
        if gesture != nil { NSCursor.arrow.set() }
        gesture = nil; mouseOrigin = nil; dragOrigin = nil
        latteOffset = .zero; latteReturnBegan = nil
        latteHandoffOrigin = nil
        barOffset = .zero; barReturnBegan = nil
        screwOffset = .zero; screwReturnBegan = nil
        pendingPaper = nil
        if danceInProgress { cancelDance(); mood = baseMood }
        if mood.isInteraction { mood = baseMood }
    }
    func react(_ newMood: Mood, duration: TimeInterval = 2.3) {
        if newMood == .wakeUp { wakingFromNight = false }
        if let scheduledMood { mood = scheduledMood; needsDisplay = true; return }
        guard canInteract else { mood = baseMood; pendingPaper = nil; needsDisplay = true; return }
        if lifestyle.phase == .phone && !newMood.isLifestyle && !newMood.isPaper { _ = acceptCharacterInteraction(); return }
        if lifestyle.phase == .snack && newMood != .snack && !newMood.isPaper { return }
        if newMood.isDance && !(newMood == .zoomies && coffeeOverload.phase == .hyped) && !danceRequirementsMet { return }
        if newMood.isChoreography && danceInProgress { return }
        if newMood == .yoga && !(solitaryYoga.ready && canStartSolitaryYoga) { return }
        if newMood.isChoreography && !danceProgress.allows(newMood.rawValue) { return }
        if isNightVisit && !newMood.isInteraction && !newMood.isPaper { mood = baseMood; needsDisplay = true; return }
        if newMood.isPaper && lifestyle.occupied { pendingPaper = nil; return }
        if hasLifestyleActivity && !newMood.isLifestyle && !newMood.isPaper && [.idle, .wave, .walk, .sleep, .celebrate, .sideEye, .reconcile, .shySmile, .restless].contains(newMood) { mood = baseMood; needsDisplay = true; return }
        if newMood == .zoomies && reduceMotion { responses.cancelZoomies(); mood = baseMood; needsDisplay = true; return }
        if newMood == .coffee && !coffeeOverload.occupied { responses.acceptLatte(allowed: danceRequirementsMet) }
        if newMood == .zoomies && canGiveNotes && focusRest == nil && !reduceMotion && responses.phase != .zoomies { responses.startZoomies() }
        if [.reconcile, .shySmile].contains(newMood) && canGiveNotes && focusRest == nil { responses.comfort() }
        if newMood == .paperOpen && !canGiveNotes { mood = baseMood; needsDisplay = true; return }
        if [.coffee, .recover, .affection, .takeBow, .wakeUp].contains(mood) && Date() < moodUntil && newMood.isPaper { pendingPaper = newMood; return }
        if mood == .coffee && Date() < moodUntil && ![.pickedUp, .grumpy, .coffee, .affection, .recover, .annoyed, .tumble, .crying].contains(newMood) { return }
        if isBusy && (newMood == .sideEye || newMood == .wave || newMood == .celebrate) { return }
        if newMood.isPaper { pendingPaper = nil }
        let passive = newMood.isLifestyle || newMood.isDance || newMood.isHeadphones || [.idle, .wave, .walk, .sleep, .sideEye, .celebrate, .stretch, .focusNap, .wakeUp, .reconcile, .shySmile, .restless, .showOff, .overstimulated].contains(newMood)
        if !newMood.isHeadphones { listeningState.reset() }
        let previousMood = mood
        if passive && (focusRest != nil || stimulation.overstimulated) && canGiveNotes { mood = baseMood }
        else { mood = !canGiveNotes && passive ? baseMood : newMood }
        if previousMood.isChoreography && mood != previousMood { cancelDance() }
        if mood == newMood && mood.isChoreography {
            _ = lifestyle.startDance(); solitaryYoga.interact()
            happiness.performedDance(); onHappinessChanged?(happiness)
            performance.beginDance(); danceInProgress = true; danceChosen = false
            onLifestyleChanged?(lifestyle)
            updateAccessibilityHelp()
            onPerformanceChanged?()
        }
        moodBegan = Date()
        if mood == .yoga { solitaryYoga.performed() }
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
        case .ironSnack: length = IronState.biteDuration
        case .snack: length = 6
        case .acknowledged: length = 2
        default: length = duration
        }
        moodUntil = [.grumpy, .annoyed, .crying, .focusNap, .zoomies, .reconcile, .restless, .showOff, .overstimulated].contains(mood) ? .distantFuture : Date().addingTimeInterval(length)
        if mood == .tumble { audio.playTumble() }
        if mood == .coffee { audio.playCoffee(paused: paused) }
        if mood == newMood && previousMood != mood {
            switch mood {
            case .drawingThanks: playJerseyReaction(.shy)
            default: break
            }
        }
        idleSince = Date()
        syncCompanionButtons()
        needsDisplay = true
    }
    private func playJerseyReaction(_ reaction: JerseyReaction, chance: Double = 1) {
        guard previewTime == nil, canInteract, !paused, !tutorialActive, !noteIsVisible,
            focusRest == nil, !externalAudioPlaying, !listeningState.isActive, !hasLifestyleActivity else { return }
        _ = audio.playJersey(reaction, chance: chance)
    }
    private func updatePointerPresence() {
        guard let window, window.isVisible else { return }
        let screenPoint = NSEvent.mouseLocation
        let over = window.frame.contains(screenPoint) && interactiveArea(convert(window.convertPoint(fromScreen: screenPoint), from: nil))
        // NSView hit testing alone cannot forward a click to another application.
        // Switch the entire panel to pass-through whenever the pointer is off the character.
        let ignores = !over && gesture == nil
        if window.ignoresMouseEvents != ignores { window.ignoresMouseEvents = ignores }
        if over != hovering {
            hoverBegan = over ? ProcessInfo.processInfo.systemUptime : nil; hoverRewarded = false
            hovering = over
            if over && gesture == nil && !mood.isDance && !isBusy && focusRest == nil && !responses.isActive && !performance.isEngaged && !stimulation.overstimulated && !hasLifestyleActivity { react(.sideEye, duration: 1.8) }
        }
    }
    private(set) var tickCount = 0
    private(set) var drawCount = 0
    private(set) var rasterizationCount = 0
    private func tick() {
        tickCount += 1
        guard window?.isVisible == true else { return }
        defer { updateAnimationClock() }
        updatePointerPresence()
        if let began = hoverBegan, !hoverRewarded, ProcessInfo.processInfo.systemUptime - began >= 0.65, gesture == nil {
            recordActivity(.hover); hoverRewarded = true
        }
        let now = Date()
        let holdsRoutine = paused && (mood == .coffee || mood.isChoreography)
        if !holdsRoutine && mouseOrigin == nil && now > moodUntil && mood != .idle && mood != .sleep {
            finishDanceIfNeeded()
            mood = baseMood
            if [.restless, .showOff, .overstimulated].contains(mood) { moodUntil = .distantFuture }
            if let paper = pendingPaper { pendingPaper = nil; if canGiveNotes { react(paper) } }
        }
        if mood == .styling && !paused && !stylingSoundPlayed && now.timeIntervalSince(moodBegan) >= 2.5 {
            stylingSoundPlayed = true
            playJerseyReaction(stylingSideEye ? .attitude : (Bool.random() ? .pleased : .laugh))
        }
        let responseNow = ProcessInfo.processInfo.systemUptime
        advanceNightVisit(by: min(1, max(0, responseNow - lastResponseTick)))
        advanceResponses(by: min(1, max(0, responseNow - lastResponseTick)))
        advanceLifestyle(by: min(1, max(0, responseNow - lastResponseTick)))
        advancePerformance(by: min(1, max(0, responseNow - lastResponseTick)))
        advanceStimulation(by: min(1, max(0, responseNow - lastResponseTick)))
        advanceDrawingGift(by: min(1, max(0, responseNow - lastResponseTick)))
        updateCompanionAudio()
        advanceListening(by: min(1, max(0, responseNow - lastResponseTick)))
        lastResponseTick = responseNow
        if let held = gesture, held.target == .crown, held.phase == .pressed, ProcessInfo.processInfo.systemUptime - held.began >= 0.35 {
            updatePointer(at: held.last, screenPoint: mouseOrigin ?? .zero, time: ProcessInfo.processInfo.systemUptime)
        }
        if let began = screwReturnBegan, ProcessInfo.processInfo.systemUptime - began > 0.24 { screwReturnBegan = nil; screwOffset = .zero }
        if let began = barReturnBegan, ProcessInfo.processInfo.systemUptime - began > 0.24 { barReturnBegan = nil; barOffset = .zero }
        if let began = latteReturnBegan, ProcessInfo.processInfo.systemUptime - began > 0.24 { latteReturnBegan = nil; latteOffset = .zero }
        if mood != .coffee || now.timeIntervalSince(moodBegan) > 0.3 { latteHandoffOrigin = nil }
        if !paused && !reduceMotion && canGiveNotes && !tutorialActive && scheduledMood == nil && focusRest == nil && !responses.isActive && !performance.isEngaged && !stimulation.overstimulated && !isBusy && !mood.isDance && mouseOrigin == nil && !hovering && !listeningState.isActive && !hasLifestyleActivity && now > nextIdle {
            idleSequence += 1
            let playlist: [Mood] = activity.withdrawn ? [.stretch, .reserved, .sleep] : [.wave, .walk, .sideEye, .stretch]
            let next = playlist[idleSequence % playlist.count]
            react(next, duration: next == .stretch ? FocusSession.stretchDuration : (next == .reserved || next == .sleep ? 12 : 3))
            nextIdle = now.addingTimeInterval(activity.idleInterval + Double(idleSequence % 7))
        }

        let visual = visualState
        let effects = gesture != nil || latteReturnBegan != nil || barReturnBegan != nil || screwReturnBegan != nil || showsScrews || iron.eating ||
            (!paused && !reduceMotion && (showsApplause || mood.isHeadphones || mood.isPaper || [.coffee, .zoomies, .disco, .celebrate, .affection, .recover, .takeBow].contains(mood)))
        if visual == nil || visual != lastVisual || effects {
            needsDisplay = true; lastVisual = visual
        }
    }
    func interactiveArea(_ point: NSPoint) -> Bool {
        guard canInteract else { return false }
        if showsDrawing && drawingHitbox.contains(point) { return true }
        if showsScrews && screwHitbox.contains(point) { return true }
        if crownRect.contains(point) { return true }
        if !snackButton.isHidden && snackButtonRect.contains(point) { return true }
        if showsApplause && applauseButtonRect.contains(point) { return true }
        if showsDanceChooser && applauseButtonRect.contains(point) { return true }
        if wantsCoffee && latteContains(point) { return true }
        if let atlas {
            let pose = spritePose(time: animationTime, mood: mood, atlas: atlas)
            // Keep animation math in Double; AppKit coordinates are CGFloat.
            // Explicit boundaries also work with older Swift type checkers.
            let dx = Double(point.x) - 95
            let dy = Double(point.y) - spritePivotY
            let cosine = cos(pose.angle), sine = sin(pose.angle)
            let x = 95 + dx * cosine + dy * sine
            let y = spritePivotY - dx * sine + dy * cosine
            let frame = atlas.frames[pose.index]
            let scale = atlas.scale * Self.appearanceScale * frame.unitScale
            return frame.contains(x: (x - Double(pose.rect.minX)) / scale, y: (y - Double(pose.rect.minY)) / scale)
        }
        let pose = geometry(time: animationTime, mood: mood)
        let dx = Double(point.x) - 95, dy = Double(point.y) - 110
        let cosine = cos(pose.wobble), sine = sin(pose.wobble)
        let bodyX = 95 + dx * cosine + dy * sine
        let bodyY = 110 - dx * sine + dy * cosine - pose.bounce + pose.lift
        let p = NSPoint(x: CGFloat(bodyX), y: CGFloat(bodyY))
        let headX = bodyX - 95, headY = bodyY - 67
        let headCosine = cos(pose.headTilt), headSine = sin(pose.headTilt)
        let rotatedHeadX = 95 + headX * headCosine + headY * headSine
        let rotatedHeadY = 67 - headX * headSine + headY * headCosine
        let h = NSPoint(x: CGFloat(rotatedHeadX), y: CGFloat(rotatedHeadY))
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
    // A tiny scalloped head needs forgiving padding: holds at its edge should
    // still count as affection rather than pass through to the desktop.
    private func onCrown(_ point: NSPoint) -> Bool { crownRect.contains(point) }
    var latteHandRect: NSRect {
        guard let atlas else { return NSRect(x: 110, y: 136, width: 30, height: 42) }
        let rect = spritePose(time: animationTime, mood: .grumpy, atlas: atlas, receiving: false).rect
        return NSRect(x: rect.midX + rect.width * 0.29, y: rect.minY + rect.height * 0.53, width: rect.width * 0.25, height: rect.height * 0.20)
    }
    func beginPointer(at point: NSPoint, screenPoint: NSPoint, time: Double, forceMove: Bool = false) {
        solitaryYoga.interact()
        if wakeForNightVisit() { return }
        guard acceptCharacterInteraction() else { return }
        if !forceMove && showsDrawing && drawingHitbox.contains(point) { acceptDrawingGift(); return }
        if !forceMove && showsScrews && screwHitbox.contains(point) {
            screwPickupOffset = currentScrewOffset; screwOffset = screwPickupOffset; screwReturnBegan = nil
            gesture = CompanionGesture(target: .screws, point: point, time: time)
            mouseOrigin = screenPoint; dragOrigin = window?.frame.origin
            updateAnimationClock(); NSCursor.closedHand.set(); return
        }
        if !forceMove && !snackButton.isHidden && snackButtonRect.contains(point) {
            barPickupOffset = currentBarOffset; barOffset = barPickupOffset; barReturnBegan = nil
            gesture = CompanionGesture(target: .bar, point: point, time: time)
            mouseOrigin = screenPoint; dragOrigin = window?.frame.origin
            updateAnimationClock(); NSCursor.closedHand.set(); return
        }
        if lifestyle.phase == .snack || iron.eating { return }
        if acknowledgeAttention() { return }
        if lifestyle.phase == .nap || lifestyle.phase == .yawning {
            _ = lifestyle.wake(); lifestyleChanged(); mood = .wakeUp; moodBegan = Date(); moodUntil = Date().addingTimeInterval(4.2)
            if !iron.needsScrews { onClick?() }; return
        }
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
        updateAnimationClock()
    }
    func updatePointer(at point: NSPoint, screenPoint: NSPoint, time: Double) {
        guard canInteract else { return }
        guard var current = gesture else { return }
        let previous = current.phase
        let phase = current.update(point: point, time: time, onCrown: onCrown(point))
        gesture = current
        switch phase {
        case .carryingScrews:
            screwOffset = NSPoint(x: screwPickupOffset.x + point.x - current.origin.x, y: screwPickupOffset.y + point.y - current.origin.y)
        case .carryingBar:
            barOffset = NSPoint(x: barPickupOffset.x + point.x - current.origin.x, y: barPickupOffset.y + point.y - current.origin.y)
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
        guard canInteract else { return }
        if let held = gesture, held.target == .crown, held.phase == .pressed {
            updatePointer(at: point, screenPoint: mouseOrigin ?? point, time: time)
        }
        // Mouse-up can contain movement that AppKit coalesced out of drag events.
        // Apply it before testing where the carried screws actually ended up.
        if let held = gesture, held.target == .screws {
            updatePointer(at: point, screenPoint: mouseOrigin ?? point, time: time)
        }
        guard let current = gesture else { return }
        let handedScrews = NSPoint(x: offeredScrewRect.midX, y: offeredScrewRect.midY)
        let completion = current.finish(overCup: latteContains(point), overHand: latteHandRect.insetBy(dx: -5, dy: -4).contains(point), overBarHand: barHandRect.insetBy(dx: -4, dy: -4).contains(point), overScrewHand: acceptsScrewDrop(at: point))
        let handedCup = NSPoint(x: offeredLatteRect.midX, y: offeredLatteRect.midY)
        gesture = nil; mouseOrigin = nil; dragOrigin = nil
        NSCursor.arrow.set()
        switch completion {
        case .giveScrews:
            screwHandoffStart = handedScrews
            if giveScrews() { screwOffset = .zero; screwReturnBegan = nil }
            else { screwReturnBegan = ProcessInfo.processInfo.systemUptime }
        case .returnScrews:
            screwReturnBegan = ProcessInfo.processInfo.systemUptime
            if reduceMotion { screwOffset = .zero; screwReturnBegan = nil }
        case .giveBar:
            barOffset = .zero; barReturnBegan = nil; _ = giveProteinBar()
        case .returnBar:
            barReturnBegan = ProcessInfo.processInfo.systemUptime
            if reduceMotion { barOffset = .zero; barReturnBegan = nil }
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
        case .moved: recordActivity(.move, at: time); recordStimulation(at: time); react(.wave); onDrop?()
        case .openNotes: onClick?()
        }
        needsDisplay = true
    }
    func rubCrown() {
        if wakeForNightVisit() { return }
        guard acceptCharacterInteraction() else { return }
        guard lifestyle.phase != .snack else { return }
        if lifestyle.acknowledge() { receiveCare(.attention); lifestyleChanged() }
        let wasCrying = care.upset == .crying
        if care.needsAffection { responses.comfort() }
        recordActivity(.pet)
        receiveCare(.pet)
        attitude.pet(); care.soothe()
        react(wasCrying ? .recover : .affection)
        audio.playHeadPet()
        recordStimulation()
        onAffection?()
    }
    func makeAnnoyed() { guard canInteract else { return }; disappoint(.poked); care.annoy(); react(baseMood) }
    private func updateCompanionAudio() {
        let chosen = danceChosen && !reduceMotion
        audio.updateDance(vogue: chosen && mood == .vogue, breaking: chosen && mood == .breakdance, house: chosen && mood == .house, waacking: chosen && mood == .waacking, ballet: chosen && mood == .ballet, floorwork: chosen && mood == .floorwork, disco: chosen && mood == .disco, contemporary: chosen && mood == .contemporary, paused: paused)
        audio.updateCoffee(playing: mood == .coffee, paused: paused)
    }
    func cancelLatteResponse() { responses.cancelZoomies() }
    private func cancelDance() { audio.stopDance(); danceInProgress = false; danceChosen = false; paidDanceInProgress = false }
    func chooseDance(_ dance: Mood, invited: Bool = false, newlyUnlocked: Bool = false) {
        guard acceptCharacterInteraction() else { return }
        guard dance.isChoreography, danceProgress.allows(dance.rawValue), canChooseDance else { return }
        let freeInvitation = invited && performance.restless && dance == .ballet
        guard freeInvitation || newlyUnlocked || danceProgress.canReplay(dance.rawValue) else { return }
        recordStimulation()
        guard !stimulation.overstimulated else { return }
        responses.cancelZoomies()
        audio.stopAll()
        react(dance, duration: 12)
        if mood == dance {
            if !freeInvitation && !newlyUnlocked { _ = danceProgress.payForReplay(dance.rawValue) }
            danceChosen = true; paidDanceInProgress = !freeInvitation && !newlyUnlocked
            updateCompanionAudio()
            onPerformanceChanged?()
        }
    }
    private func finishDanceIfNeeded() {
        guard danceInProgress, mood.isChoreography else { return }
        if let atlas { heldFinish = spritePose(time: animationTime, mood: mood, atlas: atlas); showOffPose = heldFinish!.index }
        lifestyle.finishDance(); onLifestyleChanged?(lifestyle)
        performance.finishDance(chosen: danceChosen, earnsUnlock: !danceChosen)
        moodBegan = Date()
        cancelDance(); updateAccessibilityHelp()
        onPerformanceChanged?()
    }
    func prepareForTutorial() {
        cancelDance(); performance.cancelApplause(); performance.settleRestless()
        responses.cancelZoomies(); listeningState.reset()
        mood = baseMood; moodUntil = Date(); needsDisplay = true
    }
    func makeRestless() {
        guard acceptCharacterInteraction(), !tutorialActive, danceProgress.allows("ballet") else { return }
        performance.makeRestless(); updateAccessibilityHelp()
        if canGiveNotes && focusRest == nil && !isBusy && !mood.isDance { react(baseMood) }
        onPerformanceChanged?()
    }
    func showOff() {
        guard acceptCharacterInteraction(), danceRequirementsMet else { return }
        showOffPose = 17; heldFinish = nil; performance.finishDance(chosen: false, earnsUnlock: false)
        react(baseMood); updateAccessibilityHelp()
        onPerformanceChanged?()
    }
    @discardableResult func applaud() -> Bool {
        let earnsUnlock = performance.applauseEarnsUnlock
        guard canGiveNotes, focusRest == nil, !stimulation.overstimulated, !isBusy, performance.applaud() else { return false }
        if earnsUnlock { danceProgress.recordClap() }
        react(.takeBow); audio.playClap(); updateAccessibilityHelp()
        onPerformanceChanged?()
        return true
    }
    var showsApplause: Bool { performance.awaitingApplause && mood == .showOff && canGiveNotes && focusRest == nil && !stimulation.overstimulated }
    var canChooseDance: Bool { danceRequirementsMet && canInteract && !paused && !danceInProgress && !mood.isChoreography && focusRest == nil && !stimulation.overstimulated && mood != .coffee }
    var showsDanceChooser: Bool { canChooseDance && !isBusy && !mood.isDance && !performance.awaitingApplause && ((performance.restless && mood == .restless) || danceProgress.availableUnlocks > 0) }
    var applauseButtonRect: NSRect {
        let crown = crownRect
        return NSRect(x: min(bounds.maxX - 29, crown.maxX + 1), y: max(4, crown.minY + 8), width: 27, height: 27)
    }
    func syncCompanionButtons() {
        screwButton.isHidden = !showsScrews
        if showsScrews { screwButton.frame = screwHitbox }
        snackButton.isHidden = !(scheduledMood == nil && !isNightVisit && lifestyle.hungry && canInteract && !lifestyle.occupied && mood == .hungry && focusRest == nil)
        if !snackButton.isHidden {
            let rect = snackButtonRect
            if snackButton.frame != rect { snackButton.frame = rect }
        }
        applauseButton.isHidden = !showsApplause
        if showsApplause {
            let rect = applauseButtonRect
            if applauseButton.frame != rect { applauseButton.frame = rect }
            applauseButton.alphaValue = CGFloat(performance.applauseFraction)
            let help = "Clap within \(Int(ceil(performance.applauseRemaining))) seconds"
            if applauseButton.accessibilityHelp() != help { applauseButton.setAccessibilityHelp(help) }
        }
        danceButton.isHidden = !showsDanceChooser
        if showsDanceChooser { let rect = applauseButtonRect; if danceButton.frame != rect { danceButton.frame = rect } }
    }
    func makeDanceMenu(invited: Bool = false) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        if !danceProgress.allows("ballet") {
            let hint = NSMenuItem(title: "Meet Velvet to earn Ballet", action: nil, keyEquivalent: "")
            hint.isEnabled = false; menu.addItem(hint); return menu
        }
        for dance in availableDances {
            let item = NSMenuItem(title: dance.danceTitle + (invited && dance == .ballet ? " · free" : " · 1 clap"), action: #selector(danceChosen(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = dance.rawValue
            item.tag = invited ? 1 : 0
            item.isEnabled = canChooseDance && (invited && dance == .ballet || danceProgress.canReplay(dance.rawValue))
            menu.addItem(item)
        }
        let balance = NSMenuItem(title: "\(danceProgress.clapBalance) claps", action: nil, keyEquivalent: "")
        balance.isEnabled = false; menu.addItem(balance)
        let locked = Mood.danceChoices.filter { !danceProgress.allows($0.rawValue) }
        if !locked.isEmpty {
            menu.addItem(.separator())
            if danceProgress.availableUnlocks > 0 {
                let unlock = NSMenuItem(title: "Unlock a dance", action: nil, keyEquivalent: "")
                let choices = NSMenu(); choices.autoenablesItems = false
                for dance in locked {
                    let item = NSMenuItem(title: dance.danceTitle, action: #selector(unlockDanceChosen(_:)), keyEquivalent: "")
                    item.target = self; item.representedObject = dance.rawValue; item.isEnabled = canChooseDance
                    choices.addItem(item)
                }
                unlock.submenu = choices; unlock.isEnabled = canChooseDance; menu.addItem(unlock)
            } else {
                let progress = NSMenuItem(title: "\(3 - danceProgress.clapsToNextUnlock)/3 claps toward another dance", action: nil, keyEquivalent: "")
                progress.isEnabled = false; menu.addItem(progress)
            }
        }
        return menu
    }
    @discardableResult func unlockDance(_ dance: Mood) -> Bool {
        guard canChooseDance else { return false }
        return danceProgress.unlock(dance.rawValue)
    }
    @objc private func unlockDanceChosen(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String, let dance = Mood(rawValue: id) else { return }
        if unlockDance(dance) { chooseDance(dance, newlyUnlocked: true) }
    }
    @objc private func danceChooserPressed() {
        guard showsDanceChooser else { return }
        makeDanceMenu(invited: performance.restless).popUp(positioning: nil, at: NSPoint(x: danceButton.frame.minX, y: danceButton.frame.maxY + 3), in: self)
    }
    @objc private func danceChosen(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String, let dance = Mood(rawValue: value) else { return }
        chooseDance(dance, invited: sender.tag == 1 && performance.restless)
    }
    @objc private func applausePressed() { applaud() }
    func clickApplauseButton() { applauseButton.performClick(nil) }
    func makeOverstimulated() {
        guard acceptCharacterInteraction(), !tutorialActive else { return }
        stimulation.makeOverstimulated()
    }
    private func recordStimulation(at time: Double = ProcessInfo.processInfo.systemUptime) {
        guard dailyRoutine.period == .awake, scheduledMood == nil, canInteract, focusRest == nil, !tutorialActive else { return }
        stimulation.interact(at: time)
    }
    private func enterQuietMood() {
        responses.cancelZoomies(); performance.cancelApplause(); cancelDance()
        // Cancel the gesture that tipped her over, so recovery needs no mouse-up.
        gesture = nil; mouseOrigin = nil; dragOrigin = nil
        latteOffset = .zero; latteReturnBegan = nil; latteHandoffOrigin = nil
        barOffset = .zero; barReturnBegan = nil
        screwOffset = .zero; screwReturnBegan = nil
        pendingPaper = nil; NSCursor.arrow.set()
        mood = .overstimulated; moodBegan = Date(); moodUntil = .distantFuture
        updateAccessibilityHelp(); needsDisplay = true
        onNeedsChanged?(); onPerformanceChanged?()
    }
    func advanceStimulation(by seconds: Double) {
        let available = window?.isVisible == true && !paused && gesture == nil
        stimulation.advance(by: seconds, available: available)
    }
    func advanceListening(by seconds: Double) {
        let previous = listeningState.phase
        let available = scheduledMood == nil && !isNightVisit && happiness.careDanceDelay == nil && listensToAudio && window?.isVisible == true && canGiveNotes && !tutorialActive && !hasLifestyleActivity && focusRest == nil && !responses.isActive && !performance.isEngaged && !audio.isAnyDancePlaying && gesture == nil && ([Mood.idle, .sleep, .sideEye, .wave, .walk].contains(mood) || mood.isHeadphones)
        listeningState.advance(by: seconds, playing: externalAudioPlaying, available: available, paused: paused)
        if previous != listeningState.phase {
            if listeningState.isActive || mood.isHeadphones {
                mood = baseMood; moodBegan = Date(); moodUntil = .distantFuture
                if !listeningState.isActive { idleSince = Date(); nextIdle = Date().addingTimeInterval(18) }
                needsDisplay = true
            }
        }
    }
    func advancePerformance(by seconds: Double) {
        let applauseAvailable = window?.isVisible == true && showsApplause && !paused && gesture == nil
        if performance.advanceApplause(by: seconds, available: applauseAvailable) {
            disappoint(.missedApplause)
            react(.disappointed, duration: 3)
            updateAccessibilityHelp(); onPerformanceChanged?()
        }
        syncCompanionButtons()
        let available = danceProgress.allows("ballet") && window?.isVisible == true && danceRequirementsMet && !paused && gesture == nil && !isBusy && !mood.isDance && !responses.isActive && !performance.awaitingApplause && !listeningState.isActive
        if performance.advance(by: seconds * activity.automaticDanceRate, available: available) {
            mood = baseMood; moodUntil = .distantFuture; updateAccessibilityHelp(); needsDisplay = true
            onPerformanceChanged?()
        }
    }
    private func lifestyleChanged() {
        updateAccessibilityHelp(); needsDisplay = true
        onLifestyleChanged?(lifestyle); onPerformanceChanged?()
    }
    @discardableResult func acceptCharacterInteraction(lossRoll: Double = Double.random(in: 0..<1)) -> Bool {
        guard canInteract, !iron.eating else { return false }
        if lifestyle.disturbPhone() {
            disappoint(.phoneInterrupted)
            if !tutorialActive {
                activity.missedAttention(); onActivityChanged?(activity)
                if lossRoll < 0.25, let id = danceProgress.unlockedDanceIDs.filter({ $0 != "ballet" }).randomElement(), danceProgress.revokeDance(id), let lost = Mood(rawValue: id) {
                    onDanceProgressChanged?(danceProgress); onDanceLost?(lost)
                }
            }
            cancelDance(); performance.cancelApplause(); responses.upset(); audio.playCrossedArms()
            gesture = nil; mouseOrigin = nil; dragOrigin = nil; NSCursor.arrow.set()
            mood = .phoneSulk; moodBegan = Date(); moodUntil = .distantFuture
            lifestyleChanged(); return false
        }
        return true
    }
    @discardableResult func giveProteinBar() -> Bool {
        guard acceptCharacterInteraction(), scheduledMood == nil, !isNightVisit, focusRest == nil, lifestyle.feed() else { return false }
        receiveCare(.food)
        cancelDance(); responses.cancelZoomies(); performance.cancelApplause()
        react(.snack, duration: 6); lifestyleChanged(); return true
    }
    @objc private func snackPressed() { giveProteinBar() }
    @discardableResult func acknowledgeAttention() -> Bool {
        guard canInteract, lifestyle.acknowledge() else { return false }
        receiveCare(.attention)
        recordActivity(.attention)
        react(.acknowledged, duration: 2); lifestyleChanged(); return true
    }
    func advanceCoffeeOverload(by seconds: Double) {
        let before = coffeeOverload.phase
        coffeeOverload.advance(by: seconds, available: !screenLocked && !paused && window?.isVisible == true && scheduledMood == nil && (!tutorialActive || coffeeOverload.occupied))
        guard before != coffeeOverload.phase else { return }
        responses.cancelZoomies(); cancelDance(); performance.cancelApplause(); listeningState.reset()
        if coffeeOverload.crashed { disappoint(.caffeineCrash); enterQuietMood() }
        mood = baseMood; moodBegan = Date(); moodUntil = coffeeOverload.occupied ? .distantFuture : Date()
        if coffeeOverload.phase == .hyped { responses.startZoomies() }
        if before == .crashed { lifestyle.energy = min(lifestyle.energy, 45); onLifestyleChanged?(lifestyle) }
        onCoffeeOverloadChanged?(coffeeOverload); onNeedsChanged?(); onPerformanceChanged?(); needsDisplay = true
    }
    func advanceLifestyle(by seconds: Double) {
        advanceCoffeeOverload(by: seconds)
        advanceIron(by: seconds)
        let oldPhase = lifestyle.phase, oldHunger = lifestyle.hungry
        // The tutorial overrides bedtime poses, so its required meal must also
        // finish at night. Hidden, paused, locked and focus states still suspend it.
        let available = (tutorialActive || dailyRoutine.period == .awake) && scheduledMood == nil && window?.isVisible == true && !paused && !awaitingSong && gesture == nil && !stimulation.overstimulated && !coffeeOverload.occupied && !iron.eating && (focusRest == nil || lifestyle.phase == .idle)
        let free = canGiveNotes && focusRest == nil && !stimulation.overstimulated && !isBusy && !mood.isDance && !performance.awaitingApplause && !responses.isActive && !listeningState.isActive
        activity.advance(by: seconds, available: available && !tutorialActive && focusRest == nil)
        lifestyle.advance(by: seconds, available: available && (!tutorialActive || lifestyle.occupied), awake: focusRest == nil && !tutorialActive && !mood.isDance && mood != .coffee, free: free && !tutorialActive, focusNap: focusRest == .focusNap, lowIron: iron.lowIron)
        if oldPhase != lifestyle.phase || oldHunger != lifestyle.hungry {
            if lifestyle.occupied || lifestyle.hungry { listeningState.reset(); responses.cancelZoomies() }
            mood = baseMood; moodBegan = Date(); moodUntil = lifestyle.occupied || lifestyle.hungry ? .distantFuture : Date()
            if oldPhase == .attention && lifestyle.phase == .idle { activity.missedAttention(); happiness.missedAttention(); onHappinessChanged?(happiness); onActivityChanged?(activity); mood = activity.withdrawn ? .reserved : .sideEye; moodUntil = Date().addingTimeInterval(2) }
            lifestyleChanged()
        }
        let danceAvailable = available && danceRequirementsMet && !isBusy && !mood.isDance && !performance.awaitingApplause && (!responses.isActive || responses.isReconciling) && (!listeningState.isActive || happiness.level >= 0.65 || happiness.careDanceDelay != nil)
        happiness.advance(by: seconds, available: available && !tutorialActive && focusRest == nil, canDance: danceAvailable)
        let ordinaryDance = lifestyle.advanceDance(by: seconds * activity.automaticDanceRate * happiness.danceRate, available: danceAvailable, canStart: happiness.allowsDance)
        if danceAvailable && (happiness.careDanceReady || ordinaryDance), let dance = Mood.automaticDances.filter({ danceProgress.allows($0.rawValue) }).randomElement() { react(dance, duration: 7) }
        advanceSolitaryYoga(by: seconds)
    }
    var canStartSolitaryYoga: Bool {
        dailyRoutine.period == .awake && scheduledMood == nil && window?.isVisible == true && !paused && !reduceMotion &&
        canGiveNotes && !tutorialActive && !noteIsVisible && !hovering && gesture == nil &&
        focusRest == nil && !lifestyle.occupied && !lifestyle.hungry && !lifestyle.sleepy && !iron.needsScrews && !iron.eating &&
        !responses.isActive && !performance.awaitingApplause && !listeningState.isActive &&
        [.idle, .sideEye, .reserved, .restless].contains(mood)
    }
    func advanceSolitaryYoga(by seconds: Double) {
        let alone = !hovering && gesture == nil && !noteIsVisible && !tutorialActive && focusRest == nil && !awaitingSong
        let available = dailyRoutine.period == .awake && scheduledMood == nil && window?.isVisible == true && !paused && !reduceMotion
        solitaryYoga.advance(by: seconds, alone: alone, available: available)
        if solitaryYoga.ready && canStartSolitaryYoga { react(.yoga, duration: 18) }
    }
    func stumble() { guard acceptCharacterInteraction(), !hasLifestyleActivity, !tutorialActive else { return }; disappoint(.tumble); care.tumble(); react(.tumble) }
    func advanceTumble(by seconds: Double) {
        guard dailyRoutine.period == .awake, scheduledMood == nil, canGiveNotes, !hasLifestyleActivity, !tutorialActive, focusRest == nil, !stimulation.overstimulated, !paused, !reduceMotion, gesture == nil, !isBusy, !mood.isDance, mood != .sleep else { return }
        if care.advanceEligible(by: seconds) { disappoint(.tumble); react(.tumble) }
    }
    func advanceResponses(by seconds: Double) {
        let previous = responses.phase
        if noteIsVisible { responses.cancelZoomies() }
        let available = !coffeeOverload.occupied && window?.isVisible == true && !paused && gesture == nil && !isBusy && !performance.awaitingApplause && !mood.isPaper && (!mood.isDance || mood == .zoomies) && mood != .sleep
        responses.advance(by: seconds, healthy: canGiveNotes, quiet: scheduledMood != nil || isNightVisit || focusRest != nil || stimulation.overstimulated || reduceMotion || hasLifestyleActivity || tutorialActive, available: available)
        guard previous != responses.phase, canGiveNotes, focusRest == nil, !isBusy, gesture == nil, !stimulation.overstimulated else { return }
        if [.idle, .sideEye, .zoomies, .reconcile, .shySmile].contains(mood) {
            mood = baseMood; moodBegan = Date(); moodUntil = .distantFuture
            idleSince = Date(); nextIdle = Date().addingTimeInterval(12)
            needsDisplay = true
        }
    }
    func pokeCrown(at time: Double = ProcessInfo.processInfo.systemUptime) {
        guard canInteract else { return }
        if attitude.poke(at: time) { makeAnnoyed() }
        else { react(.sideEye, duration: 0.7) }
    }
    override func rightMouseDown(with event: NSEvent) {
        guard acceptCharacterInteraction() else { return }
        if let menu = contextMenu?() { NSMenu.popUpContextMenu(menu, with: event, for: self) }
    }

    override func draw(_ dirtyRect: NSRect) {
        drawCount += 1
        NSColor.clear.setFill(); dirtyRect.fill()
        drawGroundShadow()
        let visual = visualState
        if canReusePixels, let visual, visual == cachedVisual, let image = cachedPixelImage {
            drawPixelImage(image); drawApplauseCountdown(); drawIronDeadline(); return
        }
        rasterizationCount += 1
        let width = Int(ceil(Double(bounds.width) / pixelSize)), height = Int(ceil(Double(bounds.height) / pixelSize))
        if pixelCanvas?.pixelsWide != width || pixelCanvas?.pixelsHigh != height {
            pixelCanvas = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: width * 4, bitsPerPixel: 32)
            pixelContext = pixelCanvas.flatMap { NSGraphicsContext(bitmapImageRep: $0) }
            pixelDrawingContext = pixelContext.map { NSGraphicsContext(cgContext: $0.cgContext, flipped: true) }
        }
        guard let canvas = pixelCanvas, let offscreen = pixelContext else { drawCompanion(); return }
        NSGraphicsContext.saveGraphicsState()
        let context = offscreen.cgContext
        context.saveGState()
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.translateBy(x: 0, y: Double(height))
        context.scaleBy(x: CGFloat(Double(width) / Double(bounds.width)), y: CGFloat(-Double(height) / Double(bounds.height)))
        NSGraphicsContext.current = pixelDrawingContext
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
                            let value = premultiplied && alpha != 255 ? min(255, Int(bytes[offset + channel]) * 255 / alpha) : Int(bytes[offset + channel])
                            bytes[offset + channel] = Self.pixelChannelLevels[value]
                        }
                        bytes[offset + alphaIndex] = 255
                    }
                }
            }
        }
        guard let image = canvas.cgImage else { return }
        let rendered = NSImage(cgImage: image, size: bounds.size)
        if canReusePixels { cachedVisual = visual; cachedPixelImage = rendered }
        else { cachedVisual = nil; cachedPixelImage = nil }
        drawPixelImage(rendered)
        drawApplauseCountdown(); drawIronDeadline()
    }
    private static let pixelChannelLevels: [UInt8] = (0...255).map { UInt8(min(255, (($0 + 7) / 14) * 14)) }
    private func drawPixelImage(_ image: NSImage) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState(); context.interpolationQuality = .none
        image.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        context.restoreGState()
    }
    private func drawApplauseCountdown() {
        guard showsApplause else { return }
        let rect = applauseButtonRect.insetBy(dx: 1, dy: 1)
        let track = NSBezierPath(ovalIn: rect)
        NSColor.black.withAlphaComponent(0.2).setStroke(); track.lineWidth = 2; track.stroke()
        let remaining = NSBezierPath()
        remaining.appendArc(withCenter: NSPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: 90, endAngle: 90 + 360 * CGFloat(performance.applauseFraction), clockwise: false)
        Self.pink.withAlphaComponent(0.75 * performance.applauseFraction).setStroke()
        remaining.lineWidth = 2; remaining.stroke()
    }
    var groundShadowRect: NSRect {
        let center = atlas.map { spritePose(time: animationTime, mood: mood, atlas: $0).rect.midX } ?? 95
        let width = ([Mood.focusNap, .crying, .tumble, .floorwork, .stretch, .breakdance].contains(mood) ? 82.0 : 65.0) * Self.presentationRatio
        return NSRect(x: center - width / 2, y: 184.5, width: width, height: 8 * Self.presentationRatio)
    }
    private static let shadowGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [NSColor.black.withAlphaComponent(0.26).cgColor, NSColor.black.withAlphaComponent(0.12).cgColor, NSColor.black.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 0.45, 1])
    private func drawGroundShadow() {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let rect = groundShadowRect
        context.saveGState()
        context.translateBy(x: rect.midX, y: rect.midY)
        context.scaleBy(x: rect.width / 2, y: rect.height / 2)
        if let gradient = Self.shadowGradient {
            context.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 1, options: [])
        }
        context.restoreGState()
    }
    private func drawCompanion() {
        drawCharacter(time: animationTime, mood: mood)
        if scheduledMood == nil && canInteract && (wantsCoffee || mood == .grumpy) { drawLatteOffer() }
        if !snackButton.isHidden && hasDailyAnimation { drawBarOffer() }
        if showsScrews { drawScrewOffer() }
        if iron.eating { drawScrewBites() }
        if mood == .coffee { drawLatteHandoff() }
        if showsDrawing && drawingGift.phase == .waiting {
            drawingImage?.draw(in: drawingHitbox.insetBy(dx: 3, dy: 3), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        }
        if mood == .paperToss { drawPaperToss() }
        if mood == .affection || mood == .recover || mood == .takeBow { drawAffection() }
    }

    private var animationTime: Double { previewTime ?? (paused || reduceMotion ? 0 : Date().timeIntervalSince(born)) }

    private func spritePose(time t: Double, mood: Mood, atlas: SpriteAtlas, coffeeElapsed: Double? = nil, responseElapsed: Double? = nil, receiving: Bool = true, forcedIndex: Int? = nil) -> (index: Int, rect: NSRect, angle: Double) {
        if mood == .showOff, let heldFinish, forcedIndex == nil { return heldFinish }
        let active = previewTime != nil || (!paused && !reduceMotion)
        let elapsed = max(0, previewTime ?? (mood.isLifestyle && lifestyle.occupied ? lifestyle.elapsed : Date().timeIntervalSince(moodBegan)))
        let zoom = max(0, responseElapsed ?? previewTime ?? (coffeeOverload.phase == .hyped ? 8 - coffeeOverload.remaining : responses.zoomiesElapsed))
        var index: Int
        switch mood {
        case .styling: index = spriteFrameCount >= 128 ? (elapsed < 1 ? 124 : (elapsed < 2.5 ? 125 : (stylingSideEye ? 127 : 126))) : 2
        case .drawing:
            let progress = previewTime ?? drawingGift.elapsed
            index = spriteFrameCount >= 124 ? (progress >= 8 ? 119 : 116 + (active ? Int(progress * 2) % 3 : 0)) : 0
        case .offerDrawing: index = spriteFrameCount >= 124 ? ((previewTime ?? drawingGift.elapsed) < 1 ? 120 : 121) : 0
        case .drawingThanks: index = spriteFrameCount >= 124 ? (elapsed < 1.5 ? 122 : 123) : 3
        case .windDown: index = hasDailyAnimation ? 104 + (active ? Int(elapsed / 4) % 2 : 0) : 89
        case .nightSleep: index = hasDailyAnimation ? (closingLaptop && elapsed < 1 ? 106 : 110) : 97
        case .bellySleep: index = hasDailyAnimation ? (closingLaptop && elapsed < 1 ? 106 : 108 + (active ? Int(elapsed / 5) % 2 : 0)) : 97
        case .reserved: index = 13
        case .yoga: index = hasDailyAnimation ? [112, 113, 114, 115, 112][min(4, Int(elapsed / 3.6))] : 70
        case .ironNeed: index = hasDailyAnimation ? 100 : 85
        case .ironLow: index = iron.feelsNeglected && hasWellbeingAnimation ? 50 : (hasLifestyleAnimation ? 96 : 1)
        case .ironSnack:
            let eating = IronState.biteDuration - iron.eatingRemaining
            index = hasDailyAnimation && eating < 0.72 ? 101 : (hasLifestyleAnimation && eating < 3.0 ? 96 : 36)
        case .hungry: index = hasDailyAnimation ? 100 : (hasLifestyleAnimation ? 85 : 2)
        case .snack: index = hasDailyAnimation && elapsed < 0.7 ? 102 : (hasLifestyleAnimation ? (elapsed < 1.7 ? 86 : (elapsed < 4.2 ? 87 : 88)) : 3)
        case .attention: index = hasLifestyleAnimation ? 99 : 3
        case .acknowledged: index = 42
        case .phone: index = hasLifestyleAnimation ? 89 + (active ? Int(elapsed / 2.3) % 3 : 0) : 75
        case .phoneSulk: index = hasLifestyleAnimation ? (elapsed < 0.6 ? 92 : (elapsed < 1.1 ? 93 : (elapsed > LifestyleState.ignoreDuration - 0.7 ? 95 : 94))) : 39
        case .yawn: index = hasLifestyleAnimation ? 96 : 1
        case .naturalNap: index = hasLifestyleAnimation ? 97 : 46
        case .contemporary: index = active ? PerformanceState.contemporaryPose(at: elapsed).index : 8
        case .idle:
            if active && t.truncatingRemainder(dividingBy: 5.1) < 0.13 { index = 1 }
            else { index = hasClubAnimation && t.truncatingRemainder(dividingBy: 7) < 3.5 ? 56 : 0 }
        case .plugIn: index = 0
        case .listening: index = active && t.truncatingRemainder(dividingBy: 4.4) < 3.8 ? 1 : (hasClubAnimation ? 56 : 0)
        case .unplug: index = 0
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
        case .vogue: index = atlas.frames.count >= 20 ? (active ? (elapsed >= 9 ? 19 : 16 + Int(elapsed / (60.0 / 128)) % 4) : 16) : 2
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
            else if hasDailyAnimation && wakingFromNight {
                index = elapsed < 0.7 ? (dailyRoutine.bellySleep ? 108 : 110) : (elapsed < 1.5 ? 107 : (elapsed < 3.7 ? 111 : 100))
            }
            else if hasLifestyleAnimation && lifestyle.phase == .waking {
                index = elapsed < 0.7 ? 97 : (elapsed < 2.7 ? 98 : (elapsed < 3.7 ? 96 : 84))
            }
            else if hasStretchAnimation { index = [46, 47, 75, 45, 44, 1, hasClubAnimation ? 56 : 0][FocusSession.wakePoseStep(at: elapsed)] }
            else if hasWellbeingAnimation { index = [46, 47, 51, 45, 44, 1, 0][FocusSession.wakePoseStep(at: elapsed)] }
            else { index = elapsed < 1 ? 7 : (elapsed < 3.2 ? 3 : 0) }
        case .tumble: index = hasWellbeingAnimation ? (active && elapsed < 0.45 ? 48 : 49) : 4
        case .crying: index = hasWellbeingAnimation ? 50 : 20
        case .recover: index = hasWellbeingAnimation && active && elapsed < 0.6 ? 51 : 36
        case .reconcile: index = active && t.truncatingRemainder(dividingBy: 6.8) < 0.14 ? 1 : 0
        case .shySmile: index = hasInteractionAnimation ? 36 : 1
        case .disco: index = hasDiscoAnimation ? (active ? 52 + Int(elapsed / (60.0 / 115)) % 4 : 52) : 16
        case .restless: index = (hasClubAnimation ? 58 : 5) + (active ? Int(elapsed * 3) % 2 : 0)
        case .showOff: index = min(showOffPose, atlas.frames.count - 1)
        case .house: index = hasClubAnimation ? 60 + (active ? Int(elapsed / 0.28) % 4 : 0) : 5
        case .waacking: index = hasClubAnimation ? 64 + (active ? Int(elapsed / 0.24) % 4 : 0) : 3
        case .breakdance: index = hasBreakdanceAnimation ? 76 + (active ? PerformanceState.breakdancePose(at: elapsed) : 0) : 12
        case .takeBow: index = hasInteractionAnimation ? 42 : 1
        case .disappointed: index = hasInteractionAnimation ? 39 : 2
        case .overstimulated: index = hasInteractionAnimation && elapsed < 3 ? 39 : 7
        case .zoomies:
            if !active { index = 0 }
            else if zoom < 2 { index = 5 + Int(zoom * 5) % 2 }
            else if zoom < 4.8 {
                if danceProgress.allows("house") && hasClubAnimation { index = 60 + min(2, Int((zoom - 2) / 0.9)) }
                else if danceProgress.allows("ballet") { index = 8 + min(2, Int((zoom - 2) / 0.9)) }
                else { index = 5 + Int(zoom * 5) % 2 }
            }
            else if zoom < 6.4 { index = hasInteractionAnimation ? (zoom < 5.6 ? 42 : 43) : 3 }
            else { index = 0 }
        }
        if receiving && (isCarryingBar || isCarryingScrews) && hasDailyAnimation { index = 101 }
        if receiving && isCarryingLatte && hasInteractionAnimation { index = 40 + (latteHandRect.contains(gesture!.last) ? 1 : 0) }
        if let forcedIndex { index = forcedIndex }
        let frame = atlas.frames[index]
        var lift = active ? sin(t * 1.8) * 0.35 : 0
        if [.styling, .drawing, .offerDrawing, .drawingThanks, .windDown, .nightSleep, .bellySleep, .yoga, .reserved, .contemporary, .naturalNap, .phone, .phoneSulk, .focusNap, .wakeUp, .crying, .tumble, .showOff, .overstimulated, .breakdance].contains(mood) { lift = 0 }
        if mood == .takeBow && active { lift += sin(min(1, elapsed / 1.8) * .pi) * 4 }
        if mood == .celebrate && active { lift -= abs(sin(t * 6)) * 8 }
        if mood.isDance && mood != .zoomies && mood != .breakdance && mood != .contemporary && active { lift -= abs(sin(t * .pi * 2.5)) * (mood == .ballet ? 2 : 0.6) }
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
        if mood == .contemporary && active { offsetX = PerformanceState.contemporaryPose(at: elapsed).travel }
        if mood == .hungry && active { offsetX = sin(elapsed * 6) * 0.6 }
        if mood == .house && active { offsetX = sin(elapsed * .pi / 0.56) * 3; lift += abs(sin(elapsed * .pi / 0.56)) * 0.8 }
        if mood == .waacking && active { offsetX = sin(elapsed * .pi / 0.96) * 1.5 }
        if mood == .breakdance && active && elapsed < 2 { offsetX = sin(elapsed * .pi * 2) * 2 }
        if mood == .disco && active { offsetX = sin(elapsed * .pi / 1.3) * 4 }
        if mood == .restless && active { offsetX = sin(elapsed * 3) * 0.7 }
        offsetX *= Self.presentationRatio
        lift *= Self.presentationRatio
        let scale = atlas.scale * Self.appearanceScale * frame.unitScale
        let width = Double(frame.width) * scale, height = Double(frame.height) * scale
        let x = frame.anchorX.map { 95 + $0 * scale } ?? ((190 - width) / 2)
        let rect = NSRect(x: x + offsetX, y: 186 - height - frame.footGap * scale + lift, width: width, height: height)
        var angle = 0.0
        if mood == .contemporary && active { angle = PerformanceState.contemporaryPose(at: elapsed).tilt + sin(elapsed * 1.5) * 0.015 }
        if mood == .pickedUp && active { angle = sin(t * 8) * 0.07 }
        if mood == .wave && active { angle = sin(t * 6) * 0.025 }
        if mood.isDance && mood != .zoomies && mood != .breakdance && mood != .contemporary && active { angle = sin(t * .pi * 2.5) * 0.02 }
        if mood == .zoomies && active && zoom < 6.4 { angle = sin(zoom * 5) * (zoom < 2 ? 0.022 : 0.012) }
        if mood == .shySmile { angle = noteDirection * (active ? 0.025 + sin(elapsed * 1.4) * 0.005 : 0.025) }
        if mood == .takeBow && active { angle = sin(min(1, elapsed / 1.8) * .pi) * 0.055 }
        if mood == .affection && active { angle = sin(elapsed * 4) * 0.015 }
        if mood == .listening && active { angle = sin(t * 2.7) * 0.024 }
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
            let zoom = max(0, previewTime ?? (coffeeOverload.phase == .hyped ? 8 - coffeeOverload.remaining : responses.zoomiesElapsed))
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
            let phase = elapsed.truncatingRemainder(dividingBy: (60.0 / 115))
            if phase < 0.12 {
                let progress = phase / 0.12
                fraction = progress * progress * (3 - 2 * progress)
                let lastIndex = elapsed < (60.0 / 115) ? 0 : 52 + (Int(elapsed / (60.0 / 115)) + 3) % 4
                previous = spritePose(time: t, mood: .disco, atlas: atlas, forcedIndex: lastIndex)
            }
        }
        if let previous {
            // Add weighted frames inside an isolated layer for a true crossfade,
            // so the robot stays opaque while her hands and cup change poses.
            ctx.beginTransparencyLayer(auxiliaryInfo: nil)
            atlas.image(at: previous.index, style: styling.imageKey).draw(in: previous.rect, from: .zero, operation: .sourceOver, fraction: 1 - fraction, respectFlipped: true, hints: nil)
            atlas.image(at: pose.index, style: styling.imageKey).draw(in: pose.rect, from: .zero, operation: .plusLighter, fraction: fraction, respectFlipped: true, hints: nil)
            ctx.endTransparencyLayer()
        } else {
            atlas.image(at: pose.index, style: styling.imageKey).draw(in: pose.rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        }
        if mood.isHeadphones { drawHeadphones(in: pose.rect, time: t, mood: mood) }
        ctx.restoreGState()
        if mood == .celebrate {
            for (x, y, r) in [(26.0, 57.0, 5.0), (168, 39, 6), (168, 144, 4)] {
                star(center: accessoryPoint(x: x, y: y + sin(t * 6 + x) * 2), radius: r * Self.presentationRatio, color: Self.pink)
            }
        }
    }

    private func drawHeadphones(in rect: NSRect, time: Double, mood: Mood) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let elapsed = previewTime ?? listeningState.elapsed
        let progress = reduceMotion ? 1 : min(1, max(0, elapsed / (mood == .unplug ? ListeningState.takeOffDuration : ListeningState.putOnDuration)))
        let insertion = mood == .plugIn ? progress : (mood == .unplug ? 1 - progress : 1)
        context.saveGState()
        context.setAlpha(insertion)
        context.translateBy(x: rect.minX, y: rect.minY + (1 - insertion) * 7)
        context.scaleBy(x: rect.width / 100, y: rect.height / 100)
        let white = NSColor(calibratedRed: 0.91, green: 0.93, blue: 0.96, alpha: 1)
        let edge = NSColor(calibratedRed: 0.51, green: 0.59, blue: 0.73, alpha: 1)
        let shade = NSColor(calibratedRed: 0.65, green: 0.73, blue: 0.85, alpha: 1)
        let cordBase = NSColor(calibratedRed: 0.72, green: 0.77, blue: 0.85, alpha: 1)
        let cordLight = NSColor(calibratedRed: 0.83, green: 0.86, blue: 0.91, alpha: 1)
        let contact = NSColor(calibratedRed: 0.17, green: 0.24, blue: 0.44, alpha: 0.28)
        let grille = NSColor(calibratedRed: 0.32, green: 0.36, blue: 0.43, alpha: 1)
        let join = NSPoint(x: 53, y: 78)
        let left = NSBezierPath()
        left.move(to: NSPoint(x: 13, y: 45))
        left.curve(to: join, controlPoint1: NSPoint(x: 10, y: 64), controlPoint2: NSPoint(x: 26, y: 73))
        let right = NSBezierPath()
        right.move(to: NSPoint(x: 88, y: 45))
        right.curve(to: join, controlPoint1: NSPoint(x: 91, y: 67), controlPoint2: NSPoint(x: 74, y: 74))
        let lead = NSBezierPath()
        lead.move(to: join)
        lead.curve(to: NSPoint(x: 63, y: 83), controlPoint1: NSPoint(x: 54, y: 93), controlPoint2: NSPoint(x: 78, y: 94))
        for cord in [left, right, lead] {
            cord.lineCapStyle = .round; cord.lineJoinStyle = .round
            context.saveGState()
            context.translateBy(x: 0.6, y: 0.8)
            contact.setStroke(); cord.lineWidth = 2.2; cord.stroke()
            context.restoreGState()
            cordBase.setStroke(); cord.lineWidth = 1.8; cord.stroke()
            context.saveGState()
            context.translateBy(x: -0.25, y: -0.25)
            cordLight.setStroke(); cord.lineWidth = 0.7; cord.stroke()
            context.restoreGState()
        }
        for center in [13.0, 88.0] {
            let ear = NSBezierPath(ovalIn: NSRect(x: center - 3.8, y: 34, width: 7.6, height: 9))
            context.saveGState()
            context.translateBy(x: 0.8, y: 0.8)
            contact.setFill(); ear.fill()
            context.restoreGState()
            NSGradient(starting: white, ending: shade)?.draw(in: ear, angle: -40)
            edge.setStroke(); ear.lineWidth = 0.5; ear.stroke()
            let stem = NSBezierPath(roundedRect: NSRect(x: center - 1.6, y: 41, width: 3.2, height: 7), xRadius: 1.6, yRadius: 1.6)
            NSGradient(starting: cordLight, ending: shade)?.draw(in: stem, angle: 0)
            roundRect(NSRect(x: center - 1.5, y: 36.5, width: 3, height: 1.4), radius: 0.6, fill: grille)
            ellipse(NSRect(x: center - 1, y: 34.8, width: 1.2, height: 1.2), white)
        }
        roundRect(NSRect(x: 51.2, y: 76, width: 3.6, height: 5), radius: 1.5, fill: cordBase)
        roundRect(NSRect(x: 61, y: 81, width: 5, height: 3.5), radius: 1.4, fill: edge)
        roundRect(NSRect(x: 63, y: 81.6, width: 4, height: 2.3), radius: 1, fill: cordLight)
        context.restoreGState()
    }

    private var latteRect: NSRect {
        guard let atlas, hasLatteAnimation else { return NSRect(x: 142, y: 138, width: 29, height: 46) }
        let frame = atlas.frames[27]
        let scale = min(29 / Double(frame.width), 46 / Double(frame.height)) * Self.presentationRatio
        let width = Double(frame.width) * scale, height = Double(frame.height) * scale
        let anchor = accessoryPoint(x: 156, y: 185)
        return NSRect(x: CGFloat(Double(anchor.x) - width / 2), y: CGFloat(Double(anchor.y) - height), width: CGFloat(width), height: CGFloat(height))
    }
    private func latteContains(_ point: NSPoint) -> Bool {
        let rect = offeredLatteRect
        guard let atlas, hasLatteAnimation, rect.contains(point) else { return false }
        let frame = atlas.frames[27]
        return frame.contains(x: Double(point.x - rect.minX) * Double(frame.width) / Double(rect.width),
                              y: Double(point.y - rect.minY) * Double(frame.height) / Double(rect.height))
    }
    private var currentLatteOffset: NSPoint {
        guard let began = latteReturnBegan else { return latteOffset }
        let progress = min(1, max(0, (ProcessInfo.processInfo.systemUptime - began) / 0.24))
        let remaining = pow(1 - progress, 3)
        return NSPoint(x: latteOffset.x * CGFloat(remaining), y: latteOffset.y * CGFloat(remaining))
    }
    private var offeredLatteRect: NSRect { latteRect.offsetBy(dx: currentLatteOffset.x, dy: currentLatteOffset.y) }
    private func drawPaperToss() {
        guard let atlas, hasInteractionAnimation else { return }
        let elapsed = previewTime ?? Date().timeIntervalSince(moodBegan)
        guard !paused || previewTime != nil, !reduceMotion, elapsed >= 0.4, elapsed <= 1.4 else { return }
        let progress = min(1, (elapsed - 0.4) / 0.8)
        let point = accessoryPoint(x: 64 - progress * 47, y: 135 + progress * 48 - sin(progress * .pi) * 54)
        let x = Double(point.x), y = Double(point.y)
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
        for (i, crownX) in [crownRect.minX + 8, crownRect.maxX - 20].enumerated() {
            let x = Double(crownX)
            let y = Double(crownRect.minY) - 12 - min(1, elapsed / 1.6) * 9 + Double(i) * 3
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
    private func drawBarOffer() {
        guard let atlas, hasDailyAnimation else { return }
        atlas.frames[103].image.draw(in: offeredBarRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
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
        let eased = CGFloat(progress * progress * (3 - 2 * progress))
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
            let x = Double(center.x) + cos(angle) * r
            let y = Double(center.y) + sin(angle) * r
            let point = NSPoint(x: CGFloat(x), y: CGFloat(y))
            if i == 0 { p.move(to: point) } else { p.line(to: point) }
        }
        p.close(); paint(p, fill: color, stroke: nil)
    }
    private func text(_ value: String, point: NSPoint, size: Double, color: NSColor) {
        (value as NSString).draw(at: point, withAttributes: [.font: NSFont.systemFont(ofSize: size, weight: .bold), .foregroundColor: color])
    }
}

extension CharacterView {
    func renderStyleSheets(to directory: URL) {
        guard let atlas else { return }
        for start in stride(from: 0, to: atlas.frames.count, by: 32) {
            let size = NSSize(width: 720, height: 1280)
            let image = NSImage(size: size)
            image.lockFocusFlipped(true)
            NSColor(calibratedWhite: 0.84, alpha: 1).setFill(); NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
            for index in start..<min(start + 32, atlas.frames.count) {
                let frame = atlas.frames[index], slot = index - start
                let cell = NSRect(x: (slot % 4) * 180, y: (slot / 4) * 160, width: 180, height: 160)
                let scale = min(155 / Double(frame.width), 133 / Double(frame.height))
                let rect = NSRect(x: cell.midX - Double(frame.width) * scale / 2, y: cell.minY + 18,
                    width: Double(frame.width) * scale, height: Double(frame.height) * scale)
                atlas.image(at: index, style: 15).draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
                ("\(index)" as NSString).draw(at: NSPoint(x: cell.minX + 6, y: cell.minY + 3), withAttributes: [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.black])
            }
            image.unlockFocus()
            if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                try? NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])?.write(to: directory.appendingPathComponent("style-sheet-\(start).png"))
            }
        }
    }
}


extension CharacterView {
    func styledSilhouettesMatch() -> Bool {
        guard let atlas else { return false }
        for index in atlas.frames.indices {
            let frame = atlas.frames[index]
            guard let image = atlas.image(at: index, style: 15).cgImage(forProposedRect: nil, context: nil, hints: nil) else { return false }
            var bytes = [UInt8](repeating: 0, count: frame.width * frame.height * 4)
            let drawn = bytes.withUnsafeMutableBytes { data -> Bool in
                guard let context = CGContext(data: data.baseAddress, width: frame.width, height: frame.height,
                    bitsPerComponent: 8, bytesPerRow: frame.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
                context.draw(image, in: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
                return true
            }
            guard drawn, frame.alpha.indices.allSatisfy({ bytes[$0 * 4 + 3] == frame.alpha[$0] }) else { return false }
        }
        return true
    }
}
