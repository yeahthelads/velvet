import AppKit

extension AppDelegate {
    var eligibleForSongRequest: Bool {
        canRequestSong(spotifySupported: systemAudio.supported, metadataAvailable: systemAudio.hasTrackUpdates)
    }
    func canRequestSong(spotifySupported: Bool, metadataAvailable: Bool) -> Bool {
        character.scheduledMood == nil && spotifySupported && metadataAvailable && character.listensToAudio &&
        pet.isVisible && !character.paused && character.canInteract && character.canGiveNotes &&
        character.lifestyle.readyToDance && !character.tutorialActive &&
        tutorialPanel?.isVisible != true && !notes.isVisible && !store.focus.isActive &&
        !character.pointerIsActive && character.mood != .pickedUp &&
        !character.isBusy && !character.mood.isDance && character.mood != .sleep &&
        !character.hasGentleResponse && !character.performance.isEngaged
    }
    func advanceSongRequest(by seconds: Double) {
        if songRequest.waiting {
            observeRequestedSong(by: seconds, playback: systemAudio.playback, spotifyOutput: systemAudio.playing)
        } else if songRequest.advance(by: seconds, eligible: eligibleForSongRequest) {
            showSongRequest()
            store.setSongRequest(songRequest)
        }
    }
    func showSongRequest() {
        guard songRequest.waiting else { return }
        pendingNote = nil
        character.awaitingSong = true
        if songPanel == nil {
            let bubble = TutorialView(frame: NSRect(x: 0, y: 0, width: TutorialView.bubbleWidth, height: 96))
            bubble.begin = { [weak self] in self?.openRequestedSong() }
            let panel = NotesPanel(contentRect: bubble.bounds, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.title = "Velvet’s song request"
            panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
            panel.isReleasedWhenClosed = false; panel.hidesOnDeactivate = false
            panel.becomesKeyOnlyIfNeeded = true; panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = bubble
            songBubble = bubble; songPanel = panel
        }
        songBubble?.update(text: songRequest.requestText, primaryTitle: "Open Spotify", complete: false)
        // This need has no dismiss/skip button. Playback is the way back.
        songBubble?.dismissButton.isHidden = true
        if pet.isVisible && character.scheduledMood == nil { songPanel?.orderFrontRegardless(); anchorSongBubble() }
        rebuildMenu()
    }
    func anchorSongBubble() {
        guard let panel = songPanel, panel.isVisible, let bubble = songBubble,
              let screen = pet.screen ?? NSScreen.main else { return }
        anchorSpeech(panel: panel, bubble: bubble, screen: screen)
    }
    @objc func openRequestedSong() {
        guard songRequest.waiting else { return }
        NSWorkspace.shared.open(songRequest.song.spotifyURL)
    }
    func observeRequestedSong(by seconds: Double, playback: SpotifyPlayback?, spotifyOutput: Bool) {
        guard songRequest.observe(by: seconds, playback: playback, spotifyOutput: spotifyOutput) else { return }
        // Persist the reward and resolved need together, even if she is hidden.
        character.danceProgress.recordClap()
        store.setSongRequest(songRequest)
        store.flush()
        character.awaitingSong = false
        if character.canGiveNotes && character.scheduledMood == nil {
            character.externalAudioPlaying = true
            character.react(.idle, duration: 0.2)
            character.advanceListening(by: ListeningState.onsetDelay)
        }
        songBubble?.update(text: SongRequestState.fulfilledText, primaryTitle: nil, complete: true)
        songBubble?.dismissButton.isHidden = true
        anchorSongBubble(); rebuildMenu()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self, !self.songRequest.waiting else { return }
            self.songPanel?.orderOut(nil)
        }
    }
}
