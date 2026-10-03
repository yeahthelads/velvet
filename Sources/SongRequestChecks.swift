import AppKit

extension AppDelegate {
    /// Uses an isolated profile and metadata fixtures, without controlling Spotify.
    func checkSongRequests() -> [String: Bool] {
        var checks: [String: Bool] = [:]
        character.audio.enabled = false
        character.awaitingSong = false; character.wantsCoffee = false
        character.care = CompanionCare(); character.lifestyle = LifestyleState()
        character.stimulation = StimulationState(cooldown: 60)
        character.danceProgress = DanceProgress(unlockedDanceIDs: ["ballet"])
        character.listensToAudio = true; character.paused = false
        tutorialPanel?.orderOut(nil); character.tutorialActive = false; closeNotes(); character.mood = .idle; character.moodUntil = .distantPast
        songRequest = SongRequestState(timeUntilRequest: 0)
        simulateSongRequest()
        checks["songRequestUsesSweetTrialDialogue"] = songBubble?.dialogue == "Could you play ‘Take a Bow’ by Rihanna on Spotify for me? Please?"
        let trial = songRequest
        simulateSongRequest()
        checks["explicitSongTrialDoesNotReplaceOrRepeatPendingRequest"] = songRequest == trial
        checks["songRequestIsSmallAndHasNoSkip"] = songPanel?.frame.width == 216 && (songPanel?.frame.height ?? 1000) < 130 && songBubble?.dismissButton.isHidden == true && songBubble?.primaryButton.title == "Open Spotify"
        checks["songBlocksInteractionsAndNotes"] = !character.canInteract && !character.canGiveNotes && !character.canChooseDance
        let balance = character.danceProgress.clapBalance, noteCount = store.activeCount
        openNotes(); quickCapture(); character.chooseDance(.ballet); character.rubCrown(); giveCoffee(); feedVelvet()
        checks["ordinaryActionsCannotBypassSong"] = songRequest.waiting && character.awaitingSong && !notes.isVisible && store.activeCount == noteCount && pendingNote == nil
        let care = character.lifestyle
        character.advanceLifestyle(by: 1000)
        checks["songWaitFreezesCareClocks"] = character.lifestyle == care
        let menu = makeMenu()
        checks["songHasSpotifyMenuShortcut"] = menu.items.contains { $0.title == "Open ‘Take a Bow’ in Spotify" && $0.isEnabled }
        checks["notesAndListeningMenusRespectSongGate"] = menu.items.first { $0.title == "Open thoughts" }?.isEnabled == false && menu.items.first { $0.title == "Listen to Spotify" }?.isEnabled == false
        let track = SpotifyPlayback(notification: ["Name": "Take A Bow", "Artist": "Rihanna", "Player State": "Playing", "Track ID": "spotify:track:test"])
        let wrong = SpotifyPlayback(notification: ["Name": "Take A Bow", "Artist": "Madonna", "Player State": "Playing", "Track ID": "spotify:track:other"])
        observeRequestedSong(by: 3, playback: wrong, spotifyOutput: true)
        observeRequestedSong(by: 3, playback: track, spotifyOutput: false)
        checks["wrongSongOrNonSpotifyOutputCannotEarnClap"] = songRequest.waiting && character.danceProgress.clapBalance == balance
        store.flush()
        let resumed = NoteStore(directory: store.directory)
        checks["songNeedPersistsWithoutPlaybackHistory"] = resumed.songRequest.waiting && resumed.danceProgress.clapBalance == balance
        observeRequestedSong(by: 1, playback: track, spotifyOutput: true)
        checks["songNeedsSustainedRealPlayback"] = songRequest.waiting && character.awaitingSong
        observeRequestedSong(by: 1, playback: track, spotifyOutput: true)
        checks["matchingSongResumesAndEarnsOneClap"] = !songRequest.waiting && character.canInteract && character.canGiveNotes && character.danceProgress.clapBalance == balance + 1
        checks["songCompletionKeepsNotesClosed"] = !notes.isVisible && pendingNote == nil && store.activeCount == noteCount
        checks["songCompletionPutsInEarbuds"] = character.mood == .plugIn && character.hasHeadphones
        checks["songUsesApprovedThankYou"] = songBubble?.dialogue == "Finally. Taste. You’ve earned a clap. We may continue."
        observeRequestedSong(by: 300, playback: track, spotifyOutput: true)
        checks["repeatPlaybackCannotFarmClaps"] = character.danceProgress.clapBalance == balance + 1
        let saved = NoteStore(directory: store.directory)
        checks["resolvedSongAndRewardPersistTogether"] = !saved.songRequest.waiting && saved.danceProgress.clapBalance == balance + 1
        checks["songCadenceResetsAfterReward"] = SongRequestState.interval.contains(songRequest.timeUntilRequest)
        character.react(.idle); character.mood = .idle; character.moodUntil = .distantPast
        checks["healthyAvailableCharacterCanRequestSong"] = canRequestSong(spotifySupported: true, metadataAvailable: true)
        checks["missingSpotifyMetadataPreventsRequest"] = !canRequestSong(spotifySupported: true, metadataAvailable: false)
        openNotes()
        checks["songRequestsNeverInterruptWriting"] = !canRequestSong(spotifySupported: true, metadataAvailable: true)
        closeNotes(); store.focus.start(seconds: 10)
        checks["songRequestsNeverInterruptFocus"] = !canRequestSong(spotifySupported: true, metadataAvailable: true)
        store.focus.end(); character.tutorialActive = true
        checks["songRequestsNeverInterruptTutorial"] = !canRequestSong(spotifySupported: true, metadataAvailable: true)
        character.tutorialActive = false
        songPanel?.orderOut(nil)
        return checks
    }
}
