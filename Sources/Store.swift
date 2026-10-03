import Foundation
import Combine

struct Note: Codable, Identifiable, Equatable {
    var id = UUID()
    var title = ""
    var body = ""
    var pinned = false
    var createdAt = Date()
    var updatedAt = Date()
    var deletedAt: Date?
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let firstLine = body.split(separator: "\n").first.map(String.init) ?? ""
        return firstLine.isEmpty ? "Untitled thought" : String(firstLine.prefix(60))
    }
    var preview: String {
        body.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct Preferences: Codable {
    var x: Double?
    var y: Double?
    var alwaysOnTop = true
    var paused = false
    var shortcut = 0
    var hasMetVelvet: Bool?
    var listensToAudio: Bool? // Missing in older archives means enabled.
}

struct Archive: Codable {
    var version = 1
    var notes: [Note] = []
    var preferences = Preferences()
    var coffee: CoffeeState?
    var care: CompanionCare?
    var danceProgress: DanceProgress?
    var lifestyle: LifestyleState?
    var tutorial: TutorialState?
    var songRequest: SongRequestState?
    var activity: ActivityState?
    var dailyRoutine: DailyRoutine?
}

final class NoteStore: ObservableObject {
    @Published private(set) var archive = Archive()
    @Published var selectedID: UUID?
    @Published var query = ""
    @Published var showingTrash = false
    @Published private(set) var saveError: String?
    @Published private(set) var savedAt: Date?
    @Published var focus = FocusSession()
    @Published var focusDuration: TimeInterval = 25 * 60
    let directory: URL
    private let file: URL
    private var pendingSave: DispatchWorkItem?
    private var loadFailed = false
    var onSaved: (() -> Void)?

    init(directory: URL) {
        self.directory = directory
        self.file = directory.appendingPathComponent("notes.json")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: file.path) {
                archive = try JSONDecoder().decode(Archive.self, from: Data(contentsOf: file))
                // Previous releases already offered Ballet; preserve that upgrade path.
                if archive.danceProgress == nil { archive.danceProgress = DanceProgress(unlockedDanceIDs: ["ballet"]) }
            }
        } catch {
            saveError = "Could not read your notes: \(error.localizedDescription)"
            loadFailed = true
        }
        selectedID = sortedNotes.first?.id
    }

    var preferences: Preferences { archive.preferences }
    var activity: ActivityState { archive.activity ?? ActivityState() }
    func setActivity(_ value: ActivityState) { archive.activity = value; scheduleSave(celebrate: false) }
    var dailyRoutine: DailyRoutine { archive.dailyRoutine ?? DailyRoutine() }
    func setDailyRoutine(_ value: DailyRoutine) { archive.dailyRoutine = value; scheduleSave(celebrate: false) }
    var songRequest: SongRequestState { archive.songRequest ?? SongRequestState() }
    func setSongRequest(_ state: SongRequestState) { archive.songRequest = state; scheduleSave(celebrate: false) }
    var tutorial: TutorialState { archive.tutorial ?? TutorialState() }
    func setTutorial(_ state: TutorialState) { archive.tutorial = state; scheduleSave(celebrate: false) }
    var lifestyle: LifestyleState { archive.lifestyle ?? LifestyleState() }
    func setLifestyle(_ state: LifestyleState) { archive.lifestyle = state; scheduleSave(celebrate: false) }
    var coffee: CoffeeState { archive.coffee ?? CoffeeState() }
    var care: CompanionCare { archive.care ?? CompanionCare() }
    var danceProgress: DanceProgress { archive.danceProgress ?? DanceProgress() }
    func setDanceProgress(_ progress: DanceProgress) { archive.danceProgress = progress; scheduleSave(celebrate: false) }
    func setCare(_ care: CompanionCare) { archive.care = care; scheduleSave(celebrate: false) }
    func setCoffee(_ coffee: CoffeeState) {
        archive.coffee = coffee
        scheduleSave(celebrate: false)
    }
    var activeCount: Int { archive.notes.filter { $0.deletedAt == nil }.count }
    var trashCount: Int { archive.notes.filter { $0.deletedAt != nil }.count }
    var sortedNotes: [Note] {
        archive.notes.filter {
            ($0.deletedAt != nil) == showingTrash &&
            (query.isEmpty || ($0.title + " " + $0.body).localizedCaseInsensitiveContains(query))
        }.sorted {
            if $0.pinned != $1.pinned { return $0.pinned }
            return $0.updatedAt > $1.updatedAt
        }
    }
    var selected: Note? { archive.notes.first { $0.id == selectedID } }

    @discardableResult func create() -> UUID {
        showingTrash = false
        query = ""
        let note = Note()
        archive.notes.insert(note, at: 0)
        selectedID = note.id
        scheduleSave()
        return note.id
    }

    func update(_ id: UUID, title: String? = nil, body: String? = nil) {
        guard let index = archive.notes.firstIndex(where: { $0.id == id }) else { return }
        if let title { archive.notes[index].title = title }
        if let body { archive.notes[index].body = body }
        archive.notes[index].updatedAt = Date()
        scheduleSave()
    }
    func pin(_ id: UUID) {
        guard let index = archive.notes.firstIndex(where: { $0.id == id }) else { return }
        archive.notes[index].pinned.toggle()
        scheduleSave()
    }
    func trash(_ id: UUID) {
        guard let index = archive.notes.firstIndex(where: { $0.id == id }) else { return }
        archive.notes[index].deletedAt = Date()
        selectedID = sortedNotes.first?.id
        scheduleSave()
    }
    func restore(_ id: UUID) {
        guard let index = archive.notes.firstIndex(where: { $0.id == id }) else { return }
        archive.notes[index].deletedAt = nil
        archive.notes[index].updatedAt = Date()
        showingTrash = false
        query = ""
        selectedID = id
        scheduleSave()
    }
    func setPreferences(_ mutation: (inout Preferences) -> Void) {
        mutation(&archive.preferences)
        scheduleSave(celebrate: false)
    }
    func scheduleSave(celebrate: Bool = true) {
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.flush(celebrate: celebrate) }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }
    @discardableResult func flush(celebrate: Bool = false) -> Bool {
        pendingSave?.cancel()
        pendingSave = nil
        // A failed decode must never replace the user's existing file with an empty archive.
        guard !loadFailed else { return false }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(archive)
            try data.write(to: file, options: .atomic)
            saveError = nil
            savedAt = Date()
            if celebrate { onSaved?() }
            return true
        } catch {
            saveError = "Could not save: \(error.localizedDescription)"
            return false
        }
    }
    func markdown(_ note: Note) -> String { "# \(note.displayTitle)\n\n\(note.body)\n" }
}
