import AppKit

extension CharacterView {
    var ironAvailable: Bool {
        dailyRoutine.period == .awake && scheduledMood == nil && canInteract && window?.isVisible == true &&
        !paused && !tutorialActive && focusRest == nil && !isNightVisit && !lifestyle.occupied &&
        !coffeeOverload.occupied && !needsAffection && !wantsCoffee && !noteIsVisible &&
        mood != .sleep && !mood.isDance && !isBusy && !performance.awaitingApplause
    }
    var showsScrews: Bool { iron.needsScrews && ironAvailable }
    var currentScrewOffset: NSPoint {
        guard let began = screwReturnBegan else { return screwOffset }
        let u = min(1, max(0, (ProcessInfo.processInfo.systemUptime - began) / 0.24))
        let r = CGFloat(1 - u * u * (3 - 2 * u))
        return NSPoint(x: screwOffset.x * r, y: screwOffset.y * r)
    }
    var offeredScrewRect: NSRect { NSRect(x: 41, y: 164, width: 30, height: 20).offsetBy(dx: currentScrewOffset.x, dy: currentScrewOffset.y) }
    var screwHitbox: NSRect { offeredScrewRect.insetBy(dx: -5, dy: -5) }
    func advanceIron(by seconds: Double) {
        let phase = iron.phase, eating = iron.eating
        let eatingAvailable = !screenLocked && !paused && window?.isVisible == true && scheduledMood == nil && canInteract && focusRest == nil && !tutorialActive
        iron.advance(by: seconds, available: iron.eating ? eatingAvailable : (ironAvailable && !pointerIsActive))
        if phase != iron.phase || eating != iron.eating {
            if iron.lowIron { disappoint(.missedIron) }
            react(baseMood)
            onIronChanged?(iron); onPerformanceChanged?(); updateAccessibilityHelp(); needsDisplay = true
        }
        syncCompanionButtons()
    }
    @discardableResult func giveScrews() -> Bool {
        guard ironAvailable, !pointerIsActive, iron.feed() else { return false }
        lifestyle.energy = min(100, lifestyle.energy + 8)
        onLifestyleChanged?(lifestyle); receiveCare(.iron)
        react(.ironSnack); onIronChanged?(iron); onPerformanceChanged?(); syncCompanionButtons(); needsDisplay = true
        return true
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
        NSColor(calibratedWhite: 0, alpha: 0.15).setFill()
        NSBezierPath(ovalIn: NSRect(x: r.minX + 2, y: r.maxY - 1, width: 25, height: 3)).fill()
        drawScrew(at: NSPoint(x: r.minX + 8, y: r.minY + 6), angle: -0.42)
        drawScrew(at: NSPoint(x: r.minX + 22, y: r.minY + 8), angle: 0.48)
    }
    func drawScrewBites() {
        let elapsed = IronState.biteDuration - iron.eatingRemaining
        let hand = screwHandoffStart ?? NSPoint(x: barHandRect.midX, y: barHandRect.midY)
        let mouth = NSPoint(x: crownRect.midX + 4, y: crownRect.minY + crownRect.height * 0.70)
        for index in 0..<2 {
            let t = elapsed - Double(index) * 1.55
            guard t >= 0 && t < 1.45 else { continue }
            let u = CGFloat(min(1, t / 0.8)), smooth = u * u * (3 - 2 * u)
            let point = NSPoint(x: hand.x + (mouth.x - hand.x) * smooth, y: hand.y + (mouth.y - hand.y) * smooth)
            drawScrew(at: point, angle: -0.8 + u * 0.5, scale: 0.65 * CGFloat(t < 0.8 ? 1 : max(0, (1.45 - t) / 0.65)))
        }
    }
    func drawIronDeadline() {
        guard showsScrews && !isCarryingScrews else { return }
        let r = offeredScrewRect, width = CGFloat(iron.lowIron ? 1 : iron.deadlineFraction) * 23
        NSColor(calibratedWhite: 0.6, alpha: 0.3).setFill()
        NSBezierPath(roundedRect: NSRect(x: r.minX + 3, y: r.maxY + 5, width: 23, height: 2), xRadius: 1, yRadius: 1).fill()
        (iron.lowIron ? NSColor.systemOrange : Self.pink).setFill()
        NSBezierPath(roundedRect: NSRect(x: r.minX + 3, y: r.maxY + 5, width: width, height: 2), xRadius: 1, yRadius: 1).fill()
    }
}

extension AppDelegate {
    func syncIronRequest(announce: Bool = false) {
        if announce { ironMessagePending = character.iron.needsScrews }
        guard ironMessagePending && character.showsScrews else { ironPanel?.orderOut(nil); return }
        if ironPanel == nil {
            let bubble = TutorialView(frame: NSRect(x: 0, y: 0, width: 216, height: 96))
            bubble.begin = { [weak self] in self?.ironMessagePending = false; self?.ironPanel?.orderOut(nil) }
            let panel = NotesPanel(contentRect: bubble.bounds, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.title = "Velvet needs iron"; panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
            panel.hidesOnDeactivate = false; panel.isReleasedWhenClosed = false; panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]; panel.contentView = bubble
            ironPanel = panel; ironBubble = bubble
        }
        let text = character.iron.lowIron ? "Low iron… I’m getting sleepy. Hand me my screws, please." : "A few screws, please. Hand them to me within two minutes. My iron is running low."
        if ironBubble?.dialogue != text { ironBubble?.update(text: text, primaryTitle: "Continue", complete: true); ironBubble?.dismissButton.isHidden = true }
        if ironPanel?.isVisible != true { ironPanel?.orderFrontRegardless() }; anchorIronRequest()
    }
    func anchorIronRequest() {
        guard let panel = ironPanel, panel.isVisible, let bubble = ironBubble, let screen = pet.screen ?? NSScreen.main else { return }
        anchorSpeech(panel: panel, bubble: bubble, screen: screen)
    }
}
