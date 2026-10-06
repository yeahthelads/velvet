import AppKit

/// A small, read-only paper keepsake, separate from the notes editor.
final class DrawingCardView: NSView {
    let image: NSImage
    var dismiss: (() -> Void)?
    init(image: NSImage) {
        self.image = image
        super.init(frame: NSRect(x: 0, y: 0, width: 360, height: 240))
        let close = NSButton(title: "×", target: self, action: #selector(closeCard))
        close.frame = NSRect(x: 328, y: 8, width: 24, height: 24)
        close.contentTintColor = CharacterView.ink
        close.isBordered = false; close.font = .systemFont(ofSize: 19)
        close.setAccessibilityLabel("Close drawing")
        addSubview(close)
        setAccessibilityElement(true); setAccessibilityRole(.image)
        setAccessibilityLabel("Velvet’s crayon drawing: two little blue robots holding hands and kissing")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        image.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }
    @objc private func closeCard() { dismiss?() }
}

extension AppDelegate {
    @objc func openHerDrawing(_ sender: NSMenuItem) {
        guard character.canInteract else { return }
        if let picture = character.drawingGift.received.first { showDrawing(picture) }
    }
    @objc func collectHerDrawing() { _ = character.acceptDrawingGift() }
    func showDrawing(_ picture: DrawingKeepsake) {
        guard let url = Bundle.main.url(forResource: picture.resourceName, withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return }
        if drawingPanel == nil {
            let card = DrawingCardView(image: image)
            let panel = NotesPanel(contentRect: card.bounds, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.title = "A drawing from Velvet"; panel.backgroundColor = CharacterView.cream
            panel.isOpaque = true; panel.hasShadow = true; panel.isReleasedWhenClosed = false
            panel.hidesOnDeactivate = false; panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = card
            card.dismiss = { [weak self] in self?.drawingPanel?.orderOut(nil) }
            drawingPanel = panel
        }
        anchorDrawing(); drawingPanel?.orderFrontRegardless()
    }
    func anchorDrawing() {
        guard let panel = drawingPanel, let screen = pet.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let x = min(visible.maxX - panel.frame.width - 8, max(visible.minX + 8, pet.frame.midX - panel.frame.width / 2))
        let above = pet.frame.maxY + 8
        let y = above + panel.frame.height <= visible.maxY ? above : max(visible.minY + 8, pet.frame.minY - panel.frame.height - 8)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
