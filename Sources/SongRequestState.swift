import Foundation

struct RequestedSong: Equatable {
    let id: String
    let title: String
    let artist: String
    let trackID: String?
    var titleAliases: [String] = []
    var artistAliases: [String] = []
    var spotifyURL: URL {
        if let trackID { return URL(string: "spotify:track:\(trackID)")! }
        let query = "\(title) \(artist)".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        return URL(string: "spotify:search:\(query)")!
    }
    static let catalog: [RequestedSong] = [
        .init(id: "take-a-bow", title: "Take a Bow", artist: "Rihanna", trackID: "5ox2ypXUEQ5pqCDTzrBra4"),
        .init(id: "ache", title: "Ache", artist: "FKA twigs", trackID: nil),
        .init(id: "superstar", title: "Superstar", artist: "LSDXOXO", trackID: "5dJcOpxZahHNig9pUEgNTk"),
        .init(id: "panic-attack", title: "Panic Attack", artist: "Pussy Riot", trackID: nil),
        .init(id: "noblest-strive", title: "Noblest Strive", artist: "Bladee", trackID: "67FlxevHsQQjgPiDKCNwFU"),
        .init(id: "what-u-wanna-do", title: "What U Wanna Do?", artist: "Erika de Casier", trackID: "1GkFopyb6RNt72rIx7ghhf"),
        .init(id: "without-you", title: "Without You", artist: "Spooky Black", trackID: "6G9w78ki4mR3AxvAwjsZFq", titleAliases: ["Without U"], artistAliases: ["Corbin"]),
        .init(id: "a-thousand-lies", title: "A thousand lies", artist: "Smerz", trackID: nil),
        .init(id: "sticky", title: "Sticky", artist: "FKA twigs", trackID: "4tYob6KRAMp2TIFKlq72ZI"),
        .init(id: "sad-girlz-luv-money", title: "SAD GIRLZ LUV MONEY", artist: "Amaarae feat. Moliy", trackID: nil, titleAliases: ["SAD GIRLZ LUV MONEY (feat. Moliy)", "SAD GIRLZ LUV MONEY (ft. Moliy)"], artistAliases: ["Amaarae"]),
        .init(id: "radw", title: "RADW", artist: "Haftbefehl", trackID: nil),
        .init(id: "nicole-kidman", title: "Nicole Kidman", artist: "ADÉLA", trackID: nil)
    ]
}

/// Local Spotify metadata stays in memory and is paired with real Spotify output.
struct SpotifyPlayback: Equatable {
    let title: String
    let artist: String
    let isPlaying: Bool
    let trackID: String
    init?(notification: [AnyHashable: Any]) {
        guard let title = notification["Name"] as? String,
              let artist = notification["Artist"] as? String,
              let state = notification["Player State"] as? String,
              let trackID = notification["Track ID"] as? String,
              trackID.hasPrefix("spotify:track:"), !title.isEmpty, !artist.isEmpty else { return nil }
        self.title = title; self.artist = artist; self.trackID = trackID
        isPlaying = Self.normalized(state) == "playing"
    }
    static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.map(String.init).joined().lowercased()
    }
    func matches(_ song: RequestedSong) -> Bool {
        let artists = artist.replacingOccurrences(of: " & ", with: ",").replacingOccurrences(of: ";", with: ",")
            .components(separatedBy: ",").map(Self.normalized)
        return isPlaying && ([song.title] + song.titleAliases).map(Self.normalized).contains(Self.normalized(title)) &&
            ([song.artist] + song.artistAliases).map(Self.normalized).contains(where: artists.contains)
    }
    var isRequestedSong: Bool { matches(RequestedSong.catalog[0]) }
}

struct SongRequestState: Codable, Equatable {
    enum Tone: String, Codable, CaseIterable { case sweet, pleading, demanding, bratty }
    static let initialInterval = 25.0 * 60...40.0 * 60
    static let interval = 45.0 * 60...75.0 * 60
    static let confirmationDuration = 2.0
    static let fulfilledText = "Velvet approves of your taste. You’ve earned a clap. She’s ready to continue."
    var timeUntilRequest: Double
    private(set) var waiting = false
    private(set) var songID = "take-a-bow"
    private(set) var tone = Tone.demanding
    private var matchingSeconds = 0.0
    private var cadenceVersion = 3
    var song: RequestedSong { RequestedSong.catalog.first { $0.id == songID } ?? RequestedSong.catalog[0] }
    var requestText: String {
        switch tone {
        case .sweet: return "Velvet would love ‘\(song.title)’ by \(song.artist) on Spotify. Pretty please?"
        case .pleading: return "Velvet really wants to listen to ‘\(song.title)’ by \(song.artist) with you. On Spotify, please."
        case .demanding: return "Velvet needs ‘\(song.title)’ by \(song.artist) on Spotify. Right now."
        case .bratty: return "Velvet has chosen ‘\(song.title)’ by \(song.artist). Spotify. She’ll wait."
        }
    }
    init(timeUntilRequest: Double = Double.random(in: Self.initialInterval)) { self.timeUntilRequest = max(0, timeUntilRequest) }
    private enum CodingKeys: String, CodingKey { case timeUntilRequest, waiting, songID, tone, cadenceVersion }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let value = try c.decodeIfPresent(Double.self, forKey: .timeUntilRequest) ?? Double.random(in: Self.initialInterval)
        waiting = try c.decodeIfPresent(Bool.self, forKey: .waiting) ?? false
        let oldVersion = try c.decodeIfPresent(Int.self, forKey: .cadenceVersion) ?? 1
        // Shorten existing long countdowns once, retaining elapsed progress and pending requests.
        let remaining = value.isFinite ? max(0, value) : Self.initialInterval.lowerBound
        timeUntilRequest = oldVersion < 3 && !waiting ? min(Self.initialInterval.upperBound, remaining * 0.2) : min(Self.interval.upperBound, remaining)
        songID = try c.decodeIfPresent(String.self, forKey: .songID) ?? "take-a-bow"
        if !RequestedSong.catalog.contains(where: { $0.id == songID }) { songID = "take-a-bow" }
        tone = try c.decodeIfPresent(Tone.self, forKey: .tone) ?? .demanding
    }
    @discardableResult mutating func advance(by seconds: Double, eligible: Bool, selection: RequestedSong? = nil, requestTone: Tone? = nil) -> Bool {
        guard eligible, !waiting, seconds.isFinite, seconds > 0 else { return false }
        timeUntilRequest = max(0, timeUntilRequest - seconds)
        guard timeUntilRequest == 0 else { return false }
        songID = selection?.id ?? RequestedSong.catalog.filter { $0.id != songID }.randomElement()!.id
        tone = requestTone ?? Tone.allCases.randomElement()!
        waiting = true; matchingSeconds = 0
        return true
    }
    @discardableResult mutating func observe(by seconds: Double, playback: SpotifyPlayback?, spotifyOutput: Bool) -> Bool {
        guard waiting else { matchingSeconds = 0; return false }
        guard seconds.isFinite, seconds > 0 else { return false }
        guard spotifyOutput, playback?.matches(song) == true else { matchingSeconds = 0; return false }
        matchingSeconds += seconds
        guard matchingSeconds >= Self.confirmationDuration else { return false }
        waiting = false; matchingSeconds = 0; timeUntilRequest = Double.random(in: Self.interval)
        return true
    }
}
