import AppKit

/// A bounded speech bubble. AppKit owns its size, so hosting-view layout cannot
/// expand this panel over the desktop or cover the character's hitboxes.
final class TutorialView: NSView {
    static let bubbleWidth: CGFloat = 216
    private let message = NSTextField(wrappingLabelWithString: "")
    let primaryButton = NSButton(title: "Show me", target: nil, action: nil)
    let dismissButton = NSButton(title: "Later", target: nil, action: nil)
    var begin: (() -> Void)?
    var dismiss: (() -> Void)?
    var tailX: CGFloat = 108 { didSet { needsDisplay = true } }
    var tailAtTop = false { didSet { layoutMessage(); needsDisplay = true } }
    private(set) var bubbleSize = NSSize(width: bubbleWidth, height: 96)
    private(set) var dialogue = ""
    private var textHeight: CGFloat = 44

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        message.font = .systemFont(ofSize: 12)
        message.textColor = NSColor(calibratedRed: 0.18, green: 0.19, blue: 0.25, alpha: 1)
        message.isSelectable = false
        addSubview(message)
        for button in [primaryButton, dismissButton] {
            button.isBordered = false
            button.font = .systemFont(ofSize: 11, weight: .medium)
            button.target = self
            addSubview(button)
        }
        primaryButton.contentTintColor = .systemIndigo
        primaryButton.action = #selector(start)
        dismissButton.contentTintColor = NSColor(calibratedWhite: 0.45, alpha: 1)
        dismissButton.action = #selector(closeBubble)
        dismissButton.isHidden = true
        setAccessibilityLabel("Velvet says")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(text: String, primaryTitle: String?, complete: Bool) {
        dialogue = text
        message.stringValue = text
        primaryButton.title = primaryTitle ?? ""
        primaryButton.isHidden = primaryTitle == nil
        dismissButton.title = complete ? "Got it" : "Later"
        dismissButton.isHidden = dismiss == nil
        let attributes: [NSAttributedString.Key: Any] = [.font: message.font!]
        textHeight = ceil((text as NSString).boundingRect(
            with: NSSize(width: Self.bubbleWidth - 28, height: 200),
            options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes).height) + 3
        layoutMessage()
        needsDisplay = true
    }
    private func layoutMessage() {
        let padding: CGFloat = 10
        let hasButtons = !primaryButton.isHidden || !dismissButton.isHidden
        let buttonSpace: CGFloat = hasButtons ? 24 : 0
        // Text-only replies need no empty action row. Keep the same padding
        // above and below their text, independent of which edge has the tail.
        bubbleSize = NSSize(width: Self.bubbleWidth, height: textHeight + padding * 2 + buttonSpace + 10)
        setFrameSize(bubbleSize)
        let bottom: CGFloat = tailAtTop ? 0 : 10
        message.frame = NSRect(x: 14, y: bottom + padding + buttonSpace, width: Self.bubbleWidth - 28, height: textHeight)
        dismissButton.sizeToFit()
        dismissButton.frame = NSRect(x: Self.bubbleWidth - 14 - dismissButton.frame.width, y: bottom + padding,
                                     width: dismissButton.frame.width, height: 18)
        primaryButton.sizeToFit()
        primaryButton.frame = NSRect(x: 14, y: bottom + padding, width: primaryButton.frame.width, height: 18)
    }
    @objc private func start() { begin?() }
    @objc private func closeBubble() { dismiss?() }

    override func draw(_ dirtyRect: NSRect) {
        let body = NSRect(x: 0.5, y: tailAtTop ? 0.5 : 10.5, width: bounds.width - 1, height: bounds.height - 11)
        let path = NSBezierPath(roundedRect: body, xRadius: 12, yRadius: 12)
        let x = min(bounds.width - 22, max(22, tailX))
        let edge = tailAtTop ? body.maxY : body.minY
        path.move(to: NSPoint(x: x - 7, y: edge))
        path.line(to: NSPoint(x: x, y: tailAtTop ? bounds.maxY : 0))
        path.line(to: NSPoint(x: x + 7, y: edge))
        path.close()
        NSColor(calibratedRed: 0.99, green: 0.98, blue: 0.94, alpha: 1).setFill()
        path.fill()
        NSColor(calibratedRed: 0.74, green: 0.74, blue: 0.78, alpha: 0.35).setStroke()
        path.lineWidth = 0.75
        path.stroke()
    }
}
