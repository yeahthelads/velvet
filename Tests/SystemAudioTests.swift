import Foundation
import CoreAudio

@main enum SystemAudioTests {
    static func main() throws {
        for identifier in ["com.spotify.client", "com.spotify.client.helper", "com.spotify.client.helper.renderer", "com.spotify.client.helper.gpu", "com.spotify.client.helper.plugin"] {
            precondition(SystemAudioMonitor.isSpotifyBundle(identifier))
        }
        for identifier in ["", "com.apple.Safari", "com.google.Chrome", "com.spotify.client.fake", "fake.com.spotify.client", "com.apple.afplay"] {
            precondition(!SystemAudioMonitor.isSpotifyBundle(identifier))
        }
        let monitor = SystemAudioMonitor()
        guard monitor.supported else { print("SKIP: playback detection needs macOS 14.2 or later."); return }
        let helper = Process()
        helper.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
        helper.arguments = ["-v", "0", CommandLine.arguments[1]]
        try helper.run()
        defer { if helper.isRunning { helper.terminate(); helper.waitUntilExit() } }
        let limit = Date().addingTimeInterval(4)
        var detected = false
        repeat {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            detected = SystemAudioMonitor.isProcessPlaying(helper.processIdentifier)
        } while !detected && Date() < limit
        precondition(detected && !SystemAudioMonitor.isSpotifyProcessPlaying(helper.processIdentifier), "A real non-Spotify output stream must not trigger Spotify listening")
        helper.terminate(); helper.waitUntilExit()
        let stopLimit = Date().addingTimeInterval(3)
        while SystemAudioMonitor.isProcessPlaying(helper.processIdentifier) && Date() < stopLimit {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        precondition(!SystemAudioMonitor.isProcessPlaying(helper.processIdentifier), "Stopped output must clear the playback flag")
        print("PASS: exact Spotify identity filtering, live non-Spotify output exclusion and stopped-stream recovery.")
    }
}
