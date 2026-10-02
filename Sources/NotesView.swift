import SwiftUI
import AppKit

extension Color {
    static let velvetCream = Color(nsColor: CharacterView.cream)
    static let velvetInk = Color(nsColor: CharacterView.ink)
    static let velvetPink = Color(nsColor: CharacterView.pink)
    static let velvetAcid = Color(nsColor: CharacterView.acid)
}

struct NotesView: View {
    @ObservedObject var store: NoteStore
    var close: () -> Void
    var export: (Note) -> Void
    var create: () -> Void
    var trash: (Note) -> Void
    var focusToggle: () -> Void
    var focusStart: (Int) -> Void
    var focusEnd: () -> Void
    var focusAdjust: (TimeInterval) -> Void
    var focusEditing: (Bool) -> Void
    @State private var focusToken = 0
    @State private var hovering = false
    private let paper = Color(red: 0.99, green: 0.97, blue: 0.81)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                Spacer()
                Button { create(); focusToken += 1 } label: { Image(systemName: "plus") }
                    .help("New note · ⌘N").keyboardShortcut("n", modifiers: .command)
                noteMenu
                Button(action: close) { Image(systemName: "xmark") }
                    .help("Close · Escape").keyboardShortcut(.escape, modifiers: [])
            }
            .font(.system(size: 11, weight: .medium)).buttonStyle(.plain)
            .foregroundStyle(Color.velvetInk.opacity(hovering ? 0.75 : 0.45))
            .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 8)

            if let note = store.selected, note.deletedAt == nil {
                ZStack(alignment: .topLeading) {
                    NoteTextEditor(noteID: note.id, text: note.body, editable: true, focusToken: focusToken) {
                        store.update(note.id, body: $0)
                    }
                    if note.body.isEmpty {
                        Text("Write something…").font(.custom("Noteworthy-Light", size: 17)).foregroundStyle(Color.velvetInk.opacity(0.25))
                            .padding(.top, 8).padding(.leading, 14).allowsHitTesting(false)
                    }
                }.padding(.horizontal, 18).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Button { create(); focusToken += 1 } label: {
                    Text("Write something…").font(.custom("Noteworthy-Light", size: 17)).foregroundStyle(Color.velvetInk.opacity(0.35))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(.top, 8)
                }.buttonStyle(.plain).padding(.horizontal, 18)
            }

            HStack {
                if let error = store.saveError {
                    Text("Couldn't save").foregroundStyle(.red).help(error)
                } else {
                    Text(store.savedAt == nil ? "" : "saved").opacity(0.3)
                }
                Spacer()
                FocusTimer(seconds: store.focus.isActive ? store.focus.remaining : store.focusDuration,
                           label: store.focus.phase == .complete ? store.focus.label : FocusSession.formatTime(store.focus.isActive ? store.focus.remaining : store.focusDuration),
                           active: store.focus.isActive, paused: store.focus.phase == .paused,
                           toggle: focusToggle, adjust: focusAdjust, editing: focusEditing)
                    .frame(width: 90, height: 20)
                if store.focus.isActive {
                    Button(action: focusEnd) {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                            Text("stop")
                        }.frame(minHeight: 18)
                    }.buttonStyle(.plain).opacity(0.65)
                        .accessibilityLabel("Stop focus").accessibilityIdentifier("focus.stop")
                        .help("Stop focus and let her wake up")
                }
                if let note = store.selected, note.pinned {
                    Image(systemName: "pin.fill").foregroundStyle(Color.velvetInk.opacity(0.3))
                }
                if store.activeCount > 1 {
                    Text("\(store.activeCount) notes").opacity(0.3)
                }
            }.font(.system(size: 9)).padding(.horizontal, 18).padding(.bottom, 13).padding(.top, 7)
        }
        .foregroundStyle(Color.velvetInk)
        .background {
            LinearGradient(colors: [paper, Color(red: 0.98, green: 0.95, blue: 0.77)], startPoint: .top, endPoint: .bottom)
                .overlay(PaperGrain().allowsHitTesting(false))
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(alignment: .bottomTrailing) {
            FoldCorner().fill(Color(red: 0.91, green: 0.86, blue: 0.53)).frame(width: 12, height: 12).allowsHitTesting(false)
        }
        .padding(9)
        .preferredColorScheme(.light)
        .onHover { hovering = $0 }
        .onChange(of: store.selectedID) { _ in focusToken += 1 }
    }

    private var noteMenu: some View {
        Menu {
            Menu("Focus mode") {
                ForEach([15, 25, 45], id: \.self) { minutes in
                    Button("\(minutes) minutes") { focusStart(minutes) }
                }
                if store.focus.isActive {
                    Divider()
                    Button(store.focus.phase == .paused ? "Resume" : "Pause", action: focusToggle)
                    Button("Stop focus", action: focusEnd)
                }
            }
            Divider()
            Menu("Your notes") {
                ForEach(store.archive.notes.filter { $0.deletedAt == nil }.sorted {
                    if $0.pinned != $1.pinned { return $0.pinned }
                    return $0.updatedAt > $1.updatedAt
                }) { note in
                    Button {
                        store.showingTrash = false; store.query = ""; store.selectedID = note.id
                    } label: {
                        if note.id == store.selectedID { Label(note.displayTitle, systemImage: "checkmark") }
                        else { Text(note.displayTitle) }
                    }
                }
            }
            if let note = store.selected, note.deletedAt == nil {
                Divider()
                Button(note.pinned ? "Unpin note" : "Pin note") { store.pin(note.id) }
                Button("Export as Markdown…") { export(note) }
                Button("Move to trash") {
                    trash(note)
                }
            }
            if store.trashCount > 0 {
                Divider()
                Menu("Restore a deleted note") {
                    ForEach(store.archive.notes.filter { $0.deletedAt != nil }) { note in
                        Button(note.displayTitle) { store.restore(note.id) }
                    }
                }
            }
        } label: { Image(systemName: "ellipsis") }
        .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().help("Focus, switch notes, export, or recover a note")
    }
}

struct FocusTimer: NSViewRepresentable {
    var seconds: TimeInterval
    var label: String
    var active: Bool
    var paused: Bool
    var toggle: () -> Void
    var adjust: (TimeInterval) -> Void
    var editing: (Bool) -> Void
    func makeNSView(context: Context) -> FocusTimerControl { FocusTimerControl(frame: .zero) }
    func updateNSView(_ view: FocusTimerControl, context: Context) {
        view.seconds = seconds; view.label = label; view.active = active; view.paused = paused
        view.onToggle = toggle; view.onAdjust = adjust; view.onEditing = editing
        let click = active ? (paused ? "resume" : "pause") : "start focus"
        view.toolTip = "Drag up to add time, down to shorten it. Click to \(click)."
        view.setAccessibilityValue(label)
        view.setAccessibilityHelp(view.toolTip)
        view.needsDisplay = true
    }
}

/// Native pointer tracking gives the tiny footer a reliable scrub gesture;
/// releasing a drag never fires the start/pause click action.
final class FocusTimerControl: NSView {
    var seconds: TimeInterval = 25 * 60
    var label = "25:00"
    var active = false
    var paused = false
    var onToggle: (() -> Void)?
    var onAdjust: ((TimeInterval) -> Void)?
    var onEditing: ((Bool) -> Void)?
    private var interaction: FocusDurationDrag?
    private var originY = 0.0
    override var isFlipped: Bool { true }
    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityElement(true); setAccessibilityRole(.button)
        setAccessibilityLabel("Adjustable focus timer"); setAccessibilityIdentifier("focus.timer")
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .resizeUpDown) }
    override func accessibilityPerformPress() -> Bool { onToggle?(); return true }
    override func accessibilityPerformIncrement() -> Bool { onAdjust?(seconds + 60); return true }
    override func accessibilityPerformDecrement() -> Bool { onAdjust?(seconds - 60); return true }
    func beginInteraction(y: Double) { cancelInteraction(); originY = y; interaction = FocusDurationDrag(originalSeconds: seconds) }
    func updateInteraction(y: Double) {
        guard var drag = interaction else { return }
        let previouslyDragged = drag.hasDragged
        let value = drag.update(upwardDistance: y - originY)
        interaction = drag
        if !previouslyDragged && drag.hasDragged { onEditing?(true) }
        if let value { onAdjust?(value) }
    }
    func finishInteraction() {
        guard let drag = interaction else { return }
        interaction = nil
        if drag.hasDragged { onEditing?(false) }
        else { onToggle?() }
    }
    func cancelInteraction() {
        if interaction?.hasDragged == true { onEditing?(false) }
        interaction = nil
    }
    override func mouseDown(with event: NSEvent) { beginInteraction(y: event.locationInWindow.y) }
    override func mouseDragged(with event: NSEvent) { updateInteraction(y: event.locationInWindow.y) }
    override func mouseUp(with event: NSEvent) { updateInteraction(y: event.locationInWindow.y); finishInteraction() }
    override func viewWillMove(toWindow newWindow: NSWindow?) { if newWindow == nil { cancelInteraction() }; super.viewWillMove(toWindow: newWindow) }
    override func draw(_ dirtyRect: NSRect) {
        let ink = CharacterView.ink.withAlphaComponent(active ? 0.65 : 0.45)
        let symbol = active ? (paused ? "play.fill" : "pause.fill") : "timer"
        if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil) {
            image.draw(in: NSRect(x: 1, y: 5, width: 11, height: 11), from: .zero, operation: .sourceOver, fraction: active ? 0.65 : 0.45, respectFlipped: true, hints: nil)
        }
        (label as NSString).draw(at: NSPoint(x: 17, y: 4), withAttributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular), .foregroundColor: ink])
        ("↕" as NSString).draw(at: NSPoint(x: 78, y: 4), withAttributes: [.font: NSFont.systemFont(ofSize: 10), .foregroundColor: ink.withAlphaComponent(0.35)])
    }
}

struct FoldCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(); path.move(to: CGPoint(x: 0, y: rect.height)); path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height)); path.closeSubpath(); return path
    }
}

struct PaperGrain: View {
    var body: some View {
        Canvas { context, size in
            for i in 0..<500 {
                let x = Double((i * 47 + 11) % 997) / 997 * size.width
                let y = Double((i * 83 + 29) % 991) / 991 * size.height
                var fiber = Path()
                fiber.move(to: CGPoint(x: x, y: y))
                fiber.addLine(to: CGPoint(x: x + 0.6 + Double(i % 4) * 0.25, y: y + 0.35))
                context.stroke(fiber, with: .color(Color.brown.opacity(0.06)), lineWidth: 0.4)
            }
        }
    }
}

final class EditorTextView: NSTextView {
    override var needsPanelToBecomeKey: Bool { true }
    static let ruleSpacing: CGFloat = 26
    override func draw(_ dirtyRect: NSRect) {
        let firstRule = textContainerInset.height + Self.ruleSpacing
        let start = max(0, floor((dirtyRect.minY - firstRule) / Self.ruleSpacing))
        let rules = NSBezierPath()
        var y = firstRule + start * Self.ruleSpacing
        while y <= dirtyRect.maxY {
            rules.move(to: NSPoint(x: 0, y: y))
            rules.line(to: NSPoint(x: bounds.width, y: y))
            y += Self.ruleSpacing
        }
        NSColor(calibratedRed: 0.4, green: 0.53, blue: 0.63, alpha: 0.20).setStroke()
        rules.lineWidth = 0.5; rules.stroke()
        let margin = NSBezierPath()
        margin.move(to: NSPoint(x: 6, y: dirtyRect.minY)); margin.line(to: NSPoint(x: 6, y: dirtyRect.maxY))
        NSColor(calibratedRed: 0.73, green: 0.33, blue: 0.34, alpha: 0.20).setStroke()
        margin.lineWidth = 0.6; margin.stroke()
        super.draw(dirtyRect)
    }
}

final class RuledScrollView: NSScrollView {
    override func layout() {
        super.layout()
        guard let editor = documentView as? EditorTextView else { return }
        if editor.minSize.height != contentSize.height {
            editor.minSize = NSSize(width: 0, height: contentSize.height)
        }
        if editor.frame.height < contentSize.height {
            editor.setFrameSize(NSSize(width: contentSize.width, height: contentSize.height))
        }
    }
}

struct NoteTextEditor: NSViewRepresentable {
    var noteID: UUID
    var text: String
    var editable: Bool
    var focusToken: Int
    var onChange: (String) -> Void

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NoteTextEditor
        var currentID: UUID?
        var focusToken = -1
        init(_ parent: NoteTextEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let view = notification.object as? NSTextView else { return }
            parent.onChange(view.string)
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSScrollView {
        let scroll = RuledScrollView()
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        let view = EditorTextView(frame: .zero)
        view.isRichText = false
        let font = NSFont(name: "Noteworthy-Light", size: 17) ?? .systemFont(ofSize: 17)
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = EditorTextView.ruleSpacing
        paragraph.maximumLineHeight = EditorTextView.ruleSpacing
        paragraph.paragraphSpacing = 0
        view.font = font
        view.defaultParagraphStyle = paragraph
        view.typingAttributes = [.font: font, .paragraphStyle: paragraph, .foregroundColor: CharacterView.ink]
        view.textColor = CharacterView.ink
        view.insertionPointColor = CharacterView.pink
        view.drawsBackground = false
        view.textContainerInset = NSSize(width: 14, height: 8)
        view.isVerticallyResizable = true
        view.isHorizontallyResizable = false
        view.autoresizingMask = [.width]
        view.textContainer?.widthTracksTextView = true
        view.textContainer?.lineFragmentPadding = 0
        view.minSize = .zero
        view.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        view.delegate = context.coordinator
        view.isAutomaticSpellingCorrectionEnabled = false
        view.isContinuousSpellCheckingEnabled = true
        scroll.documentView = view
        return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let view = scroll.documentView as? NSTextView else { return }
        context.coordinator.parent = self
        let changedNote = context.coordinator.currentID != noteID
        if changedNote || view.string != text {
            view.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: view.typingAttributes))
        }
        view.isEditable = editable
        if editable && (changedNote || context.coordinator.focusToken != focusToken) {
            DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        }
        if changedNote { view.setSelectedRange(NSRange(location: view.string.utf16.count, length: 0)) }
        context.coordinator.currentID = noteID
        context.coordinator.focusToken = focusToken
    }
}
