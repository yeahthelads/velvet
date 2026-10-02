import AppKit

/// Optional local samples. Source-only builds work silently without them.
final class CompanionAudio {
    private let chant: NSSound?
    private let headPet: NSSound?
    private let tumble: NSSound?
    private var chantStarted = false
    private var chantPaused = false
    var enabled = true { didSet { if !enabled { stopAll() } } }
    var volume: Float = 0.65 {
        didSet { chant?.volume = volume; headPet?.volume = volume; tumble?.volume = volume }
    }
    var available: Bool { chant != nil || headPet != nil || tumble != nil }
    var hasChant: Bool { chant != nil }
    var hasHeadPet: Bool { headPet != nil }
    var hasTumble: Bool { tumble != nil }
    var isChantPlaying: Bool { !chantPaused && chant?.isPlaying == true }
    var isHeadPetPlaying: Bool { headPet?.isPlaying == true }
    var isTumblePlaying: Bool { tumble?.isPlaying == true }
    init(bundle: Bundle = .main) {
        func sample(_ name: String) -> NSSound? {
            for ext in ["wav", "mp3", "m4a", "aiff", "aif"] {
                if let url = bundle.url(forResource: name, withExtension: ext), let sound = NSSound(contentsOf: url, byReference: false) { return sound }
            }
            return nil
        }
        chant = sample("vogue-chant") ?? sample("vogue-sound")
        headPet = sample("head-pet")
        tumble = sample("tumble")
        chant?.loops = true
        chant?.volume = volume; headPet?.volume = volume; tumble?.volume = volume
    }
    func updateVogue(playing: Bool, paused: Bool = false) {
        guard enabled, playing else { stopVogue(); return }
        if paused {
            if chantStarted && !chantPaused { chantPaused = chant?.pause() == true }
            return
        }
        if chantPaused { if chant?.resume() == true { chantPaused = false } }
        else if !chantStarted { chantStarted = chant?.play() == true }
    }
    func playHeadPet() {
        guard enabled else { return }
        // A new stroke restarts one sample; repeated pets never layer sounds.
        tumble?.stop(); headPet?.stop(); headPet?.play()
    }
    func playTumble() {
        guard enabled else { return }
        stopAll(); tumble?.play()
    }
    func stopVogue() { chant?.stop(); chantStarted = false; chantPaused = false }
    func stopAll() { stopVogue(); headPet?.stop(); tumble?.stop() }
}
