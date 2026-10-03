import Foundation

@main struct SongRequestTests {
    static func track(_ name: String = "Take A Bow", artist: String = "Rihanna", state: String = "Playing", id: String = "spotify:track:test") -> SpotifyPlayback? {
        SpotifyPlayback(notification: ["Name": name, "Artist": artist, "Player State": state, "Track ID": id])
    }
    static func main() throws {
        var request = SongRequestState(timeUntilRequest: 3)
        precondition(!request.advance(by: .infinity, eligible: true))
        precondition(!request.advance(by: 300, eligible: false) && request.timeUntilRequest == 3)
        precondition(!request.advance(by: 2, eligible: true))
        precondition(request.advance(by: 1, eligible: true, selection: RequestedSong.catalog[0], requestTone: .demanding) && request.waiting)
        precondition(!request.advance(by: 5000, eligible: true))
        precondition(!request.observe(by: 3, playback: track("Umbrella"), spotifyOutput: true))
        precondition(!request.observe(by: 3, playback: track(artist: "Madonna"), spotifyOutput: true))
        precondition(!request.observe(by: 3, playback: track(state: "Paused"), spotifyOutput: true))
        precondition(!request.observe(by: 3, playback: track(), spotifyOutput: false))
        precondition(track(id: "spotify:local:fake") == nil)
        precondition(SpotifyPlayback(notification: [:]) == nil)
        precondition(!request.observe(by: 1, playback: track(), spotifyOutput: true))
        precondition(!request.observe(by: 1, playback: nil, spotifyOutput: true))
        precondition(!request.observe(by: 1, playback: track(), spotifyOutput: true), "Interrupted matching cannot accumulate")
        let restarted = try JSONDecoder().decode(SongRequestState.self, from: JSONEncoder().encode(request))
        var resumed = restarted
        precondition(resumed.waiting && !resumed.observe(by: 1, playback: track(), spotifyOutput: true), "Restart keeps the need, not a stale playback match")
        precondition(resumed.observe(by: 1, playback: track(" take a bow ", artist: " rIHANNA "), spotifyOutput: true))
        precondition(!resumed.waiting && SongRequestState.interval.contains(resumed.timeUntilRequest))
        precondition(!resumed.observe(by: 10, playback: track(), spotifyOutput: true), "Only one clap can be earned per request")
        for song in RequestedSong.catalog {
            var randomRequest = SongRequestState(timeUntilRequest: 0)
            precondition(randomRequest.advance(by: 1, eligible: true, selection: song, requestTone: .sweet))
            let encoded = try JSONEncoder().encode(randomRequest)
            var decoded = try JSONDecoder().decode(SongRequestState.self, from: encoded)
            precondition(decoded.song.id == song.id && decoded.requestText.contains(song.title))
            precondition(decoded.observe(by: 2, playback: track(song.title, artist: song.artist), spotifyOutput: true))
            precondition(!decoded.observe(by: 2, playback: track(song.title, artist: song.artist), spotifyOutput: true))
            precondition(!track(song.title + " Remix", artist: song.artist)!.matches(song))
        }
        precondition(track("Without U", artist: "Corbin")!.matches(RequestedSong.catalog[6]))
        var progress = DanceProgress(unlockedDanceIDs: ["ballet"])
        if request.observe(by: 1, playback: track(), spotifyOutput: true) { progress.recordClap() }
        if request.observe(by: 5, playback: track(), spotifyOutput: true) { progress.recordClap() }
        precondition(progress.clapBalance == 1)
        print("PASS: rare eligible cadence, exact title/artist, paused/missing/non-Spotify exclusion, uninterrupted playback, restart and one-clap reward")
    }
}
