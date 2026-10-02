import AppKit

/// Bundled, loudness-balanced samples; builds without audio stay silent.
final class CompanionAudio {
    private final class DanceSample {
        let sound: NSSound?
        private var started = false
        private var paused = false
        var isPlaying: Bool { !paused && sound?.isPlaying == true }
        init(_ sound: NSSound?, loops: Bool) { self.sound = sound; sound?.loops = loops }
        func update(playing: Bool, pause: Bool) {
            guard playing else { stop(); return }
            if pause {
                if started && !paused { paused = sound?.pause() == true }
            } else if paused {
                if sound?.resume() == true { paused = false }
            } else if !started { started = sound?.play() == true }
        }
        func stop() {
            if started || paused { sound?.stop() }
            started = false; paused = false
        }
    }
    private let chant: DanceSample
    private let breakdance: DanceSample
    private let headPet: NSSound?
    private let tumble: NSSound?
    private let coffee: NSSound?
    private let crossedArms: NSSound?
    private let quiet: NSSound?
    private var oneShots: [NSSound] { [headPet, tumble, coffee, crossedArms, quiet].compactMap { $0 } }
    var enabled = true { didSet { if !enabled { stopAll() } } }
    // Assets share a measured -20 LUFS level; this remains the master control.
    var volume: Float = 0.65 { didSet { applyVolume() } }
    var available: Bool { hasChant || hasBreakdance || !oneShots.isEmpty }
    var hasChant: Bool { chant.sound != nil }
    var hasBreakdance: Bool { breakdance.sound != nil }
    var hasHeadPet: Bool { headPet != nil }
    var hasTumble: Bool { tumble != nil }
    var hasCoffee: Bool { coffee != nil }
    var hasCrossedArms: Bool { crossedArms != nil }
    var hasQuiet: Bool { quiet != nil }
    var isChantPlaying: Bool { chant.isPlaying }
    var isBreakdancePlaying: Bool { breakdance.isPlaying }
    var isHeadPetPlaying: Bool { headPet?.isPlaying == true }
    var isTumblePlaying: Bool { tumble?.isPlaying == true }
    var isCoffeePlaying: Bool { coffee?.isPlaying == true }
    var isCrossedArmsPlaying: Bool { crossedArms?.isPlaying == true }
    var isQuietPlaying: Bool { quiet?.isPlaying == true }
    init(bundle: Bundle = .main) {
        func sample(_ name: String) -> NSSound? {
            for ext in ["wav", "mp3", "m4a", "aiff", "aif"] {
                if let url = bundle.url(forResource: name, withExtension: ext), let sound = NSSound(contentsOf: url, byReference: false) { return sound }
            }
            return nil
        }
        chant = DanceSample(sample("vogue-chant") ?? sample("vogue-sound"), loops: true)
        // The supplied track covers the phrase; its ending stays intact.
        breakdance = DanceSample(sample("breakdance"), loops: false)
        headPet = sample("head-pet")
        tumble = sample("tumble")
        coffee = sample("coffee")
        crossedArms = sample("crossed-arms")
        quiet = sample("overwhelmed-sleep")
        applyVolume()
    }
    private func applyVolume() {
        for sound in oneShots + [chant.sound, breakdance.sound].compactMap({ $0 }) { sound.volume = volume }
    }
    func updateDance(vogue: Bool, breaking: Bool, paused: Bool = false) {
        chant.update(playing: enabled && vogue, pause: paused)
        breakdance.update(playing: enabled && breaking, pause: paused)
    }
    func updateVogue(playing: Bool, paused: Bool = false) { updateDance(vogue: playing, breaking: false, paused: paused) }
    private func playOnce(_ sound: NSSound?) {
        guard enabled else { return }
        // Restart one sound without layering reactions or music.
        stopAll(); sound?.play()
    }
    func playHeadPet() { playOnce(headPet) }
    func playTumble() { playOnce(tumble) }
    func playCoffee() { playOnce(coffee) }
    func playCrossedArms() { playOnce(crossedArms) }
    func playQuiet() { playOnce(quiet) }
    func stopDance() { chant.stop(); breakdance.stop() }
    func stopAll() {
        stopDance()
        for sound in oneShots where sound.isPlaying { sound.stop() }
    }
}
