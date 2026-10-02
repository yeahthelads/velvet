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
    private let house: DanceSample
    private let waacking: DanceSample
    private let floorwork: DanceSample
    private let disco: DanceSample
    private let ballet: DanceSample
    private let contemporary: DanceSample
    private let coffee: DanceSample
    private var coffeeActive = false
    let hasLatteMix: Bool
    private let headPet: NSSound?
    private let tumble: NSSound?
    private let crossedArms: NSSound?
    private let quiet: NSSound?
    private let clap: NSSound?
    private var oneShots: [NSSound] { [headPet, tumble, crossedArms, quiet, clap].compactMap { $0 } }
    var enabled = true { didSet { if !enabled { stopAll() } } }
    // Assets share a measured -20 LUFS level; this remains the master control.
    var volume: Float = 0.65 { didSet { applyVolume() } }
    var available: Bool { hasContemporary || hasDisco || hasChant || hasBreakdance || hasHouse || hasWaacking || hasBallet || hasFloorwork || hasCoffee || !oneShots.isEmpty }
    var hasContemporary: Bool { contemporary.sound != nil }
    var isContemporaryPlaying: Bool { contemporary.isPlaying }
    var hasChant: Bool { chant.sound != nil }
    var hasBreakdance: Bool { breakdance.sound != nil }
    var hasHeadPet: Bool { headPet != nil }
    var hasTumble: Bool { tumble != nil }
    var hasCoffee: Bool { coffee.sound != nil }
    var hasHouse: Bool { house.sound != nil }
    var hasWaacking: Bool { waacking.sound != nil }
    var hasFloorwork: Bool { floorwork.sound != nil }
    var hasDisco: Bool { disco.sound != nil }
    var hasBallet: Bool { ballet.sound != nil }
    var hasClap: Bool { clap != nil }
    var latteDuration: TimeInterval { coffee.sound?.duration ?? 0 }
    var hasCrossedArms: Bool { crossedArms != nil }
    var hasQuiet: Bool { quiet != nil }
    var isChantPlaying: Bool { chant.isPlaying }
    var isBreakdancePlaying: Bool { breakdance.isPlaying }
    var isHeadPetPlaying: Bool { headPet?.isPlaying == true }
    var isTumblePlaying: Bool { tumble?.isPlaying == true }
    var isCoffeePlaying: Bool { coffee.isPlaying }
    var isHousePlaying: Bool { house.isPlaying }
    var isWaackingPlaying: Bool { waacking.isPlaying }
    var isFloorworkPlaying: Bool { floorwork.isPlaying }
    var isDiscoPlaying: Bool { disco.isPlaying }
    var isBalletPlaying: Bool { ballet.isPlaying }
    var isClapPlaying: Bool { clap?.isPlaying == true }
    var isAnyDancePlaying: Bool { isContemporaryPlaying || isChantPlaying || isBreakdancePlaying || isHousePlaying || isWaackingPlaying || isBalletPlaying || isFloorworkPlaying || isDiscoPlaying }
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
        house = DanceSample(sample("house"), loops: true)
        waacking = DanceSample(sample("waacking"), loops: true)
        floorwork = DanceSample(sample("floorwork"), loops: false)
        disco = DanceSample(sample("disco"), loops: false)
        ballet = DanceSample(sample("ballet"), loops: false)
        contemporary = DanceSample(sample("contemporary"), loops: false)
        let latteMix = sample("latte-sip")
        hasLatteMix = latteMix != nil
        coffee = DanceSample(latteMix ?? sample("coffee"), loops: false)
        crossedArms = sample("crossed-arms")
        quiet = sample("overwhelmed-sleep")
        clap = sample("clap")
        applyVolume()
    }
    private func applyVolume() {
        for sound in oneShots + [chant.sound, breakdance.sound, house.sound, waacking.sound, floorwork.sound, ballet.sound, disco.sound, contemporary.sound, coffee.sound].compactMap({ $0 }) { sound.volume = volume }
    }
    func updateDance(vogue: Bool, breaking: Bool, house: Bool = false, waacking: Bool = false, ballet: Bool = false, floorwork: Bool = false, disco: Bool = false, contemporary: Bool = false, paused: Bool = false) {
        chant.update(playing: enabled && vogue, pause: paused)
        breakdance.update(playing: enabled && breaking, pause: paused)
        self.house.update(playing: enabled && house, pause: paused)
        self.waacking.update(playing: enabled && waacking, pause: paused)
        self.ballet.update(playing: enabled && ballet, pause: paused)
        self.floorwork.update(playing: enabled && floorwork, pause: paused)
        self.disco.update(playing: enabled && disco, pause: paused)
        self.contemporary.update(playing: enabled && contemporary, pause: paused)
    }
    func updateVogue(playing: Bool, paused: Bool = false) { updateDance(vogue: playing, breaking: false, paused: paused) }
    private func playOnce(_ sound: NSSound?) {
        guard enabled else { return }
        // Restart one sound without layering reactions or music.
        stopAll(); sound?.play()
    }
    func playHeadPet() { playOnce(headPet) }
    func playTumble() { playOnce(tumble) }
    func playCoffee(paused: Bool = false) {
        guard enabled else { return }
        stopAll(); coffeeActive = true
        coffee.update(playing: true, pause: paused)
    }
    func updateCoffee(playing: Bool, paused: Bool = false) {
        guard playing else { stopCoffee(); return }
        if coffeeActive { coffee.update(playing: enabled, pause: paused) }
    }
    func stopCoffee() { coffee.stop(); coffeeActive = false }
    func playClap() { playOnce(clap) }
    func playCrossedArms() { playOnce(crossedArms) }
    func playQuiet() { playOnce(quiet) }
    func stopDance() { chant.stop(); breakdance.stop(); house.stop(); waacking.stop(); ballet.stop(); floorwork.stop(); disco.stop(); contemporary.stop() }
    func stopAll() {
        stopDance(); stopCoffee()
        for sound in oneShots where sound.isPlaying { sound.stop() }
    }
}
