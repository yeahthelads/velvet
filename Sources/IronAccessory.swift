import AppKit

extension CharacterView {
    var ironAvailable: Bool {
        dailyRoutine.period == .awake && scheduledMood == nil && canInteract && window?.isVisible == true &&
        !paused && !tutorialActive && focusRest == nil && !isNightVisit && !lifestyle.occupied &&
        !coffeeOverload.occupied && !needsAffection && !wantsCoffee && !noteIsVisible &&
        mood != .sleep && !mood.isDance && !isBusy && !performance.awaitingApplause
    }
    var showsScrews: Bool { iron.freeOfferAvailable && ironAvailable }
    var currentScrewOffset: NSPoint {
        guard let began = screwReturnBegan else { return screwOffset }
        let u = min(1, max(0, (ProcessInfo.processInfo.systemUptime - began) / 0.24))
        let r = CGFloat(1 - u * u * (3 - 2 * u))
        return NSPoint(x: screwOffset.x * r, y: screwOffset.y * r)
    }
    var offeredScrewRect: NSRect { NSRect(x: 41, y: 164, width: 30, height: 20).offsetBy(dx: currentScrewOffset.x, dy: currentScrewOffset.y) }
    var screwHitbox: NSRect { offeredScrewRect.insetBy(dx: -5, dy: -5) }
    func acceptsScrewDrop(at point: NSPoint) -> Bool {
        // Pick-up position can be anywhere on the screws. The object touching her
        // counts too, even when the pointer remains beside her open hand.
        let overlap = screwDropRect.intersection(offeredScrewRect)
        return screwDropRect.contains(point) || (!overlap.isNull && overlap.width >= 5 && overlap.height >= 5)
    }
    func advanceIron(by seconds: Double) {
        let phase = iron.phase, eating = iron.eating, offerAvailable = iron.freeOfferAvailable, neglected = iron.feelsNeglected
        let eatingAvailable = !screenLocked && !paused && window?.isVisible == true && scheduledMood == nil && canInteract && focusRest == nil && !tutorialActive
        iron.advance(by: seconds, available: iron.eating ? eatingAvailable : (ironAvailable && !pointerIsActive))
        if offerAvailable && iron.lowIron && !iron.freeOfferAvailable && danceProgress.clapBalance == 0 { iron.feelNeglected() }
        if phase != iron.phase || eating != iron.eating || offerAvailable != iron.freeOfferAvailable || neglected != iron.feelsNeglected {
            if phase != .low && iron.lowIron { disappoint(.missedIron) }
            react(baseMood)
            onIronChanged?(iron); onPerformanceChanged?(); updateAccessibilityHelp(); needsDisplay = true
        }
        syncCompanionButtons()
    }
    var canBuyScrews: Bool {
        iron.lowIron && ironAvailable && !pointerIsActive && !iron.eating && danceProgress.clapBalance >= IronState.rescueClapCost
    }
    @discardableResult func buyScrews() -> Bool {
        guard canBuyScrews else { return false }
        var nextIron = iron, nextProgress = danceProgress
        guard nextIron.feed(), nextProgress.payForCare(cost: IronState.rescueClapCost) else { return false }
        iron = nextIron; danceProgress = nextProgress
        screwHandoffStart = NSPoint(x: barHandRect.midX, y: barHandRect.midY)
        finishScrewFeed()
        return true
    }
    @discardableResult func giveScrews() -> Bool {
        guard iron.freeOfferAvailable, ironAvailable, !pointerIsActive, iron.feed() else { return false }
        finishScrewFeed()
        return true
    }
    private func finishScrewFeed() {
        lifestyle.energy = min(100, lifestyle.energy + 8)
        onLifestyleChanged?(lifestyle); receiveCare(.iron)
        react(.ironSnack); onIronChanged?(iron); onPerformanceChanged?(); syncCompanionButtons(); needsDisplay = true
    }
    @objc func screwsPressed() { /* The visible object is handed over by dragging, like her protein bar. */ }

    private func drawScrew(at point: NSPoint, angle: CGFloat, scale: CGFloat = 1) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState(); defer { context.restoreGState() }
        context.translateBy(x: point.x, y: point.y); context.rotate(by: angle); context.scaleBy(x: scale, y: scale)
        let shaft = NSBezierPath(roundedRect: NSRect(x: -2.8, y: -2, width: 5.6, height: 16), xRadius: 1, yRadius: 1)
        NSGradient(colors: [NSColor(calibratedRed: 0.34, green: 0.40, blue: 0.50, alpha: 1), .white, NSColor(calibratedRed: 0.55, green: 0.64, blue: 0.72, alpha: 1)])?.draw(in: shaft, angle: 0)
        NSColor(calibratedWhite: 0.25, alpha: 0.65).setStroke()
        let threads = NSBezierPath(); threads.lineWidth = 0.8
        for y in stride(from: CGFloat(1), through: 12, by: 3) { threads.move(to: NSPoint(x: -2.6, y: y + 1.8)); threads.line(to: NSPoint(x: 2.6, y: y)) }
        threads.stroke()
        let head = NSBezierPath(roundedRect: NSRect(x: -5, y: -6, width: 10, height: 6), xRadius: 2, yRadius: 2)
        NSGradient(starting: .white, ending: NSColor(calibratedRed: 0.52, green: 0.60, blue: 0.68, alpha: 1))?.draw(in: head, angle: 90)
        NSColor(calibratedRed: 0.27, green: 0.32, blue: 0.41, alpha: 1).setStroke()
        let slot = NSBezierPath(); slot.lineWidth = 1.3; slot.move(to: NSPoint(x: -3, y: -3)); slot.line(to: NSPoint(x: 3, y: -3)); slot.stroke()
    }
    func drawScrewOffer() {
        let r = offeredScrewRect
        if !isCarryingScrews {
            NSColor(calibratedWhite: 0, alpha: 0.15).setFill()
            NSBezierPath(ovalIn: NSRect(x: r.minX + 2, y: r.maxY - 1, width: 25, height: 3)).fill()
        }
        drawScrew(at: NSPoint(x: r.minX + 8, y: r.minY + 6), angle: -0.42)
        drawScrew(at: NSPoint(x: r.minX + 22, y: r.minY + 8), angle: 0.48)
    }
    func drawScrewBites() {
        let elapsed = IronState.biteDuration - iron.eatingRemaining
        let palm = NSPoint(x: barHandRect.midX, y: barHandRect.midY)
        let start = screwHandoffStart ?? palm
        let mouth = NSPoint(x: crownRect.midX, y: crownRect.minY + crownRect.height * 0.70)
        func smooth(_ value: Double) -> CGFloat {
            let u = CGFloat(min(1, max(0, value))); return u * u * (3 - 2 * u)
        }
        let catchProgress = smooth(elapsed / 0.35)
        let liftProgress = smooth((elapsed - 0.45) / 0.55)
        let caught = NSPoint(x: start.x + (palm.x - start.x) * catchProgress,
                             y: start.y + (palm.y - start.y) * catchProgress)
        let position = NSPoint(x: caught.x + (mouth.x - caught.x) * liftProgress,
                               y: caught.y + (mouth.y - caught.y) * liftProgress)
        for index in 0..<2 {
            let bite = elapsed - (index == 0 ? 1.0 : 2.0)
            let size = CGFloat(bite <= 0 ? 1 : max(0, 1 - bite / 0.65))
            guard size > 0 else { continue }
            drawScrew(at: NSPoint(x: position.x + CGFloat(index == 0 ? -3 : 3), y: position.y),
                      angle: index == 0 ? -0.35 : 0.4, scale: 0.65 * size)
        }
        // Close matching blue fingers over the shafts after she catches them.
        // This is drawn with the screws, so the grip stays attached to the prop.
        if elapsed >= 0.12 && elapsed < 0.72 {
            let close = smooth((elapsed - 0.12) / 0.22)
            for finger in 0..<3 {
                let rect = NSRect(x: position.x - 5 - (1 - close) * 3,
                                  y: position.y + 2 + CGFloat(finger) * 2.4,
                                  width: 8 * close + 2, height: 2.6)
                let path = NSBezierPath(roundedRect: rect, xRadius: 1.2, yRadius: 1.2)
                NSGradient(starting: NSColor(calibratedRed: 0.40, green: 0.61, blue: 1, alpha: 1),
                           ending: NSColor(calibratedRed: 0.18, green: 0.35, blue: 0.81, alpha: 1))?.draw(in: path, angle: 90)
            }
        }
    }
    func drawIronDeadline() {
        guard showsScrews && !isCarryingScrews else { return }
        let r = offeredScrewRect, width = CGFloat(iron.deadlineFraction) * 23
        NSColor(calibratedWhite: 0.6, alpha: 0.3).setFill()
        NSBezierPath(roundedRect: NSRect(x: r.minX + 3, y: r.maxY + 5, width: 23, height: 2), xRadius: 1, yRadius: 1).fill()
        (iron.lowIron ? NSColor.systemOrange : Self.pink).setFill()
        NSBezierPath(roundedRect: NSRect(x: r.minX + 3, y: r.maxY + 5, width: width, height: 2), xRadius: 1, yRadius: 1).fill()
    }
}

extension AppDelegate {
    @objc func buyIronScrews() { _ = character.buyScrews() }
    func syncIronRequest(announce: Bool = false) {
        guard character.iron.needsScrews else {
            ironMessagePending = false; ironPanel?.orderOut(nil); return
        }
        if store.preferences.hasSeenIronIntro == true && !character.iron.freeOfferAvailable {
            ironMessagePending = false; ironPanel?.orderOut(nil); return
        }
        if announce && store.preferences.hasSeenIronIntro != true { ironMessagePending = true }
        guard ironMessagePending && character.ironAvailable else { ironPanel?.orderOut(nil); return }
        if store.preferences.hasSeenIronIntro != true {
            store.setPreferences { $0.hasSeenIronIntro = true }
            store.flush()
        }
        if ironPanel == nil {
            let bubble = TutorialView(frame: NSRect(x: 0, y: 0, width: 216, height: 96))
            bubble.begin = { [weak self] in self?.ironMessagePending = false; self?.ironPanel?.orderOut(nil) }
            let panel = NotesPanel(contentRect: bubble.bounds, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.title = "Velvet needs iron"; panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
            panel.hidesOnDeactivate = false; panel.isReleasedWhenClosed = false; panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]; panel.contentView = bubble
            ironPanel = panel; ironBubble = bubble
        }
        let text: String
        if character.iron.feelsNeglected {
            text = "Velvet thinks you don’t like her and has a little cry. Free screws return after five awake minutes."
        } else if character.iron.lowIron && character.iron.freeOfferAvailable {
            text = "Velvet still needs iron. Drag the screws onto her while they’re here."
        } else if character.iron.lowIron && character.danceProgress.clapBalance == 0 {
            text = "Velvet’s iron is low. She’ll offer free screws again after five awake minutes."
        } else {
            text = character.iron.lowIron ? "Velvet’s iron is low. Give her screws from the menu for one clap." : "Velvet needs a few screws. Drag them onto her within two minutes to keep her iron up."
        }
        if ironBubble?.dialogue != text { ironBubble?.update(text: text, primaryTitle: "Continue", complete: true); ironBubble?.dismissButton.isHidden = true }
        if ironPanel?.isVisible != true { ironPanel?.orderFrontRegardless() }; anchorIronRequest()
    }
    func anchorIronRequest() {
        guard let panel = ironPanel, panel.isVisible, let bubble = ironBubble, let screen = pet.screen ?? NSScreen.main else { return }
        anchorSpeech(panel: panel, bubble: bubble, screen: screen)
    }
}
