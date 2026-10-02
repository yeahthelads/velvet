import Foundation

/// The first routine is earned with real care, not a demonstration of a locked dance.
struct TutorialState: Codable, Equatable {
    enum Step: String, Codable { case welcome, openNote, closeNote, snack, snacking, affection, finished }
    private(set) var step: Step = .welcome
    var complete: Bool { step == .finished }
    var text: String {
        switch step {
        case .welcome: return "I’m Velvet. Your notes live with me. A little care, a little applause, and maybe I’ll dance for you."
        case .openNote: return "First: click me to open a thought. You can write whatever. I’m discreet."
        case .closeNote: return "Your thoughts save themselves. Close the note when you’re done. I don’t perform over your writing."
        case .snack: return "Now, protein. Click the bar beside me—or give me one from my menu. Talent needs fuel."
        case .snacking: return "One second. I’m eating."
        case .affection: return "Good. Now stroke my head, or hold it gently for a moment. A tap doesn’t count."
        case .finished: return "Fine. Ballet’s yours. Care for me and I’ll perform sometimes. Clap quickly when 👏 appears: three claps unlock another dance. Requests cost one clap. My phone time is private."
        }
    }
    mutating func begin() { if step == .welcome { step = .openNote } }
    mutating func openedNote() { if step == .openNote { step = .closeNote } }
    mutating func closedNote() { if step == .closeNote { step = .snack } }
    mutating func fed() { if step == .snack { step = .snacking } }
    mutating func finishedSnack() { if step == .snacking { step = .affection } }
    @discardableResult mutating func petted() -> Bool {
        guard step == .affection else { return false }
        step = .finished; return true
    }
}
