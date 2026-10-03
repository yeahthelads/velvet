import Foundation

/// The first routine is earned with real care, not a demonstration of a locked dance.
struct TutorialState: Codable, Equatable {
    enum Step: String, Codable { case welcome, openNote, closeNote, snack, snacking, affection, balletUnlocked, finished }
    private(set) var step: Step = .welcome
    var complete: Bool { step == .finished }
    var text: String {
        switch step {
        case .welcome: return "I’m Velvet. Your notes live with me."
        case .openNote: return "Tap my face to open a note. Write a little thought."
        case .closeNote: return "It saves itself. Close the note with its × when you’re done."
        case .snack: return "Drag the chocolate bar into my hand. Talent needs fuel."
        case .snacking: return "One second. I’m eating."
        case .affection: return "Now hold my head gently for a moment, or stroke it."
        case .balletUnlocked, .finished: return "Ballet is yours. Clap when I ask; three claps earn your next dance."
        }
    }
    var hasDialogue: Bool { [.welcome, .balletUnlocked, .finished].contains(step) }
    mutating func begin() { if step == .welcome { step = .openNote } }
    mutating func continueDialogue() {
        if step == .welcome { begin() }
        else if step == .balletUnlocked { step = .finished }
    }
    mutating func openedNote() { if step == .openNote { step = .closeNote } }
    mutating func closedNote() { if step == .closeNote { step = .snack } }
    mutating func fed() { if step == .snack { step = .snacking } }
    mutating func finishedSnack() { if step == .snacking { step = .affection } }
    @discardableResult mutating func petted() -> Bool {
        guard step == .affection else { return false }
        step = .balletUnlocked; return true
    }
}
