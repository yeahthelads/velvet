# Velvet

A tiny animated macOS desktop robot with a minimal Post-it notes app. Built with SwiftUI, AppKit and a custom transparent sprite atlas based on the supplied character reference. No accounts, API keys or network connection required.

## Get started

Velvet is a local macOS app. Build her on your Mac with Apple's Command Line Tools installed:

```sh
git clone https://github.com/yeahthelads/velvet.git
cd velvet
zsh build.sh
open build/Velvet.app
```

She keeps your notes in `~/Library/Application Support/Velvet/notes.json`. That personal archive, build outputs, and test data are excluded from this repository. The seventeen balanced sound samples are included. There is no cloud sync, telemetry, or network service. The source and character artwork are included; the app currently uses a local ad-hoc signature rather than a notarized release.

## Use

Open `build/Velvet.app`. Velvet appears near the lower-right corner of your desktop; click her face or body to open notes, stroke or briefly hold her head for affection, and drag her body to move. Option-drag moves her from anywhere. The sparkle in the menu bar contains hide/show, pause, always-on-top, position reset and animation previews.

Choose an earned routine from “Choose a dance” in the menu-bar sparkle or her right-click menu. Unlocked Ballet, Floorwork, Robot disco, and House can be performed spontaneously after 3–5 minutes of eligible time, shortened by happiness and recent company. Contemporary, Vogue Fem, Waacking, and Breakdance play only when explicitly selected. Chosen routines play their music, cost one clap per replay, and never offer applause. Three earned claps unlock one routine, including its first performance. The choreography uses short illustrated sprite phrases with small position and tilt changes. Contemporary combines eleven phrase steps; her poses keep the direct changes of the existing animations.

“Vogue Fem” adds hand performance, a cross-step, a low step and a supported dip. The character first rendered 20% smaller and now renders another 30% smaller, at 56% of the original size. Her latte, paper effects, shadow, motion, and rotation pivot scale with her; notes retain their existing size and stay beside her. Notes have unbranded, textured ruled paper and handwriting-style text; the text and rules scroll together.

## Meet Velvet, care and privacy

On first launch a 216-point speech bubble points to her head and teaches one real interaction at a time: open and close a note,
drag her chocolate protein bar into her hand, then stroke or briefly hold her head. Only then does
Ballet unlock, without spending claps. No locked dance is performed, including in
latte zoomies. The tutorial is mandatory. “Continue” advances the greeting and final Ballet dialogue; opening/closing the note, dropping the bar, eating and petting advance automatically. Action steps cannot be skipped, and the saved step resumes after hiding or restarting her.
Ordinary needs pause while learning. The bubble follows her when moved, flips below her near the top of the screen, and leaves the note editor and her head uncovered. Paused animations and existing care gates get a short, actionable instruction; already-open notes and a completed snack resume correctly. Existing earned dances survive an upgrade.

Rarely, after **2–4 hours of eligible awake time**, she asks for a random Spotify song: Take a Bow (Rihanna), Ache or Sticky (FKA twigs), Superstar (LSDXOXO), Panic Attack (Pussy Riot), Noblest Strive (Bladee), What U Wanna Do? (Erika de Casier), Without You (Spooky Black/Corbin), or A thousand lies (Smerz). Her small speech bubble alternates sweet, pleading, demanding and bratty lines. Requests avoid consecutive repeats. The clock runs only with valid Spotify metadata and listening enabled, while she is healthy and free. Notes, focus, the tutorial, evening/bedtime, phone time, naps and performances prevent a new request. She waits for the requested title and artist to play in Spotify for two continuous seconds. Completing it earns exactly one clap and she puts in her white wired earbuds. The request, chosen song and reward persist; repeated playback cannot earn more claps. “Open Spotify” opens the track or its search, without issuing playback commands.

Detection combines Spotify’s local `com.spotify.client.PlaybackStateChanged` notifications with its Core Audio output activity on macOS 14.2+. Nothing is recorded, downloaded or uploaded, and playback metadata is not saved. A track/playback update is needed after Velvet launches; if Spotify sends no usable metadata, she does not start new requests. An already-pending request resumes after restart and can be fulfilled by playing the track again.

She asks for food after about 15–22 minutes, attention after 8–14 minutes, and takes
25–45 seconds of phone time after 12–20 minutes. A hungry robot reaches for a foil
chocolate protein bar beside her; **drag it into her open hand**. She reaches, catches, unwraps and
bites it. A click answers her attention request without opening notes. Ignoring
that request earns a side-eye and leaves the attention need unresolved. She may scroll her lavender phone with a little
screen light on her visor.

Interrupt phone time and she gives an offended glance, turns her **whole body**
away, and ignores care and animation requests for 45 visible, unpaused seconds.
Her rear view has a back panel, pink heels, rounded robot hips and one anatomically consistent pink piercing. Petting
cannot shorten or restart that interval. Notes remain reachable from the menu
and quick-capture shortcut during this sulk; existing coffee/affection gates
remain independent. Overstimulation still blocks notes as before.

At **22:00 local Mac time**, she winds down watching her series on a little MacBook, with screen light on her visor. At **23:00** she closes it and sleeps; sometimes she clumsily flops onto her belly. At **08:00** she yawns, stretches awake and regains energy. The same overnight pose survives midnight and restarts; needs pause overnight. Notes remain available through the menu. The beginner tutorial takes precedence over the bedtime poses.

Her enthusiasm follows recent company gradually. Lingering over her for a moment, stroking her head and moving her lift her activity, with cooldowns to prevent rapid-hover farming. Without company she settles into quieter activities and stops spontaneous dances. Unanswered attention bids make her more withdrawn; responding and petting help her reconnect. Yoga is a rare solo activity: an opportunity every 15–25 visible, unpaused minutes alone, with at least five uninterrupted minutes without company before she starts. Hovering, petting, moving her or opening notes resets that solitude. She only starts when free and physically rested, doing cat/cow, a compact downward dog, cobra and child’s pose. Yoga is not a menu action.
She spends energy while awake and dancing. Each routine costs 20 energy when it **starts**, including an interrupted performance. A running dance cannot be replaced or restarted from the menu; after a few routines, she needs her nap before dancing again. Food restores some energy; coffee
still handles her latte mood rather than replacing sleep. After about 30–45
minutes awake or enough routines, she yawns and takes a 2–4 minute beauty nap,
then uncurls and wakes. Focus naps also recover energy. Hunger, tiredness,
attention, phone time, care needs and open notes all prevent dancing. Need clocks
freeze while hidden, paused or closed, and care state persists across restarts.
Automatic performances start after 3–5 eligible minutes, faster when happy and only use unlocked
routines, so applause cannot be farmed from the menu. Ordinary recent company lets that countdown complete; long solitude or repeatedly ignored attention bids stop it. A pending restless invitation does not permanently block her spontaneous performances. Restlessness cannot start until Ballet has been earned; resuming a mandatory tutorial clears stale dance invitations.

Contemporary is a twelve-second phrase with breath, reach, contraction, spiral,
floor reach, roll and recovery. Its selected performance plays a licensed excerpt
of “Dreams Become Real” by Kevin MacLeod. Credits and license details are bundled
and available at the bottom of the app menu.

## Happiness, screen rest and a fresh start

Ignoring attention or applause, poking her, tumbling and overstimulation lower happiness. Interrupting phone time has the largest penalty (45 percentage points), and a 25% chance of removing an additional unlocked dance. Ballet remains available. A small bubble explains the loss, and three new claps earn the dance back; the original unlock cost is not refunded. Food is offered as a drag-and-drop bar beside her, without a menu shortcut.

Three extra, unneeded lattes within five visible, unpaused minutes produce an eight-second rush after sipping, then a three-minute crash. During the crash, care, notes and animation requests are blocked. Needed coffees do not count. The cycle survives restarts and ends with reduced energy. The shutdown sample plays on every new overwhelm or sleep entry, including screen-lock rest, with normal volume/mute settings.


Spaced-out head rubs, accepted lattes, feeding a real hunger need and answering an attention bid increase happiness. Once she is cared for and free, a care reward can lead to a spontaneous unlocked dance after 8–20 eligible seconds. Happiness also speeds her regular dance countdown and settles gradually without care. Repeated rubs and extra coffees have cooldowns; automatic dances have a minimum two-minute rest between performances. Notes, focus, tiredness and unmet needs still prevent dancing. These dances offer normal applause and do not spend claps or play menu-only music.

Locking the screen or switching away from the active user session leaves her in a still sleeping pose, silences her and stops animation and activity timers. Time spent resting restores energy while hunger, care, focus and reward clocks remain frozen. Previously open notes return on unlock. Screen rest uses macOS lock notifications and the public [workspace session notifications](https://developer.apple.com/documentation/appkit/nsworkspace/sessiondidresignactivenotification), following the notification combination used by [Electron](https://github.com/electron/electron/blob/main/shell/browser/api/electron_api_power_monitor_mac.mm).

At bedtime, tap her to wake her for a sleepy 30-second cuddle. A small bubble offers “Back to bed”; otherwise she returns automatically to her original sleeping pose. Petting does not extend the visit, restore morning energy or start dances. Her normal 08:00 wake-up remains unchanged.

Launch with `--reset-companion` to test the beginner journey again: it resets the tutorial, dance unlocks, claps, care, happiness and song requests, preserving all notes and app preferences such as position and shortcut. Before resetting, she saves a recoverable `before-companion-reset-UUID.json` beside her normal archive. A failed backup or unreadable archive prevents the reset. Native `--care-smoke /absolute/result.json` checks these mechanics with `--data-dir /absolute/temporary/profile`, including actual protein-bar drags and simulated lock notifications without locking the computer.

## Coffee and attitude

After 15 minutes of visible, unpaused time she gets grumpy. Drag the rendered iced latte into her waiting hand on the right. She reaches toward it, accepts the cup, raises the pink straw, sips and gives an approving nod. A missed drop slides the cup back without feeding her or resetting the timer. You can also click the cup or choose “Give her an iced latte” in the menu. The drink has a clear lid, ice cubes and milk/espresso layers, with lighting matched to the character. She refuses notes and dances until she gets her latte. If a note was open, she tucks it away and returns it once her needs are met; its contents stay saved. A blocked new-note request creates one note after she is soothed, rather than accumulating empty notes. Hiding her, pausing animations, focus mode, or sleeping the Mac pauses the coffee clock. Her coffee state persists across restarts. Care triggers are grouped separately from app controls in the menu.

Her whole head, including her face, is pettable. Stroke at least 8 points or hold for about 0.35 seconds to give affection and see a happy pixel smile with tiny hearts. A head gesture stays a pet even if the pointer leaves her head; it cannot become a window drag. A quick tap opens notes. Drag her body or hold Option to move her instead. Her idle float is now less than half a point from top to bottom.

Four quick head pokes within three seconds earn crossed arms. She keeps that mood and withholds notes until she gets affection; waiting or giving coffee does not clear it. If she needs both affection and coffee, both must be given. Her upset state survives restarts. “A little head rub” in the menu provides the same affection reaction without a pointer gesture.

A rare stumble makes her fall onto her side, then cry with tiny pixel tears. Head strokes or a brief hold comfort her; she sits up with hearts and returns any waiting note. Tumbles happen after a randomized 30–60 minutes of eligible visible, awake time. Their clock pauses during focus, sleep, animation pause, reduced motion, dancing, dragging, and care interactions; she cannot tumble again while upset. Her remaining interval and crying state are saved. Existing 45–90 minute countdowns are shortened proportionally once, while preserving current upset states. The animation preview menu can demonstrate a stumble immediately.

## Latte zoomies and reconciliation

After a successful iced latte she finishes her six-second sip and any queued paper gesture, then gets eight seconds of zoomies: a quick in-place strut, three House footwork poses, a nod/wink, and a gentle settle. Opening notes cancels the burst immediately. No dancing takes place while notes are open. Nothing moves her desktop window. Each accepted latte triggers at most one burst; missed drops do not trigger it. Focus and new upset states cancel a queued or active burst, and reduced-motion mode keeps a settled pose. Animation pause, hiding, and dragging freeze the eligible response clock.

Comforting crossed arms or crying starts 90 seconds of quiet reconciliation after the initial affection/recovery. She leans slightly toward the visible note and gives a shy pixel smile after 12 seconds, then every 16 seconds for about two seconds each. Normal head rubs still work without starting a new reconciliation. Her hover side-eye and autosave celebrations stay quiet during this phase; a care-driven happy dance can follow once her needs are met. Notes remain accessible. Focus pauses the phase while she stretches/naps, a new upset overrides it, and she returns to her usual idle behavior when it ends. These brief responses are session-only; notes and care needs remain saved. Quiet response poses are automatic. Existing approved sprites are reused with small position, tilt, and crossfade changes.

## Restless and show-off moods

After 12–18 minutes of eligible awake time she gets restless, tapping and shifting her feet until you click the **🩰** beside her and choose an unlocked routine. New profiles earn Ballet through the short care tutorial; Contemporary, Floorwork, Vogue Fem, Robot disco, House, Waacking, and Breakdance are earned one at a time. Existing earned routines are preserved. The robot’s right-click menu, menu-bar sparkle, and restless chooser share the same alphabetized list of unlocked dances. Finishing that twelve-second routine settles her and resets the interval; an interrupted routine leaves the need unresolved. Every completed spontaneous dance holds the actual finishing pose with a small clickable **👏** beside her. Its countdown ring and emoji fade over six visible, unpaused seconds. Clap before the ring runs out: the emoji disappears, she gives a bow with tiny hearts, and you earn one clap. Missing the window gives her a brief disappointed reaction and earns no credit; previous progress stays intact. The timer freezes while she is hidden or paused. Opening notes, focus, and care interruptions cancel it without disappointment. The emoji click leaves notes and her desktop position alone. Face and body clicks keep their normal notes behavior. A head stroke or brief hold still gives affection. “Needs a dance break” and “Waiting for applause” in the animation menu let you try both moods; “Applaud her” also appears in her menu while she is waiting.

These playful moods keep notes available. Opening notes cancels the applause prompt and stops the dance; a paid replay interrupted by opening notes refunds its one clap. Restlessness remains unresolved. Focus suspends restlessness and cancels applause requests; care needs and overstimulation override both, and dances or applause cannot clear coffee or affection requirements. Restless time pauses while hidden, asleep, paused, in reduced-motion mode, dancing, receiving care, interacting, or reconciling. Restlessness and applause prompts are session-only; earned claps and chosen dance unlocks persist with her notes. Existing sprites keep the same small size, pixel rendering, and direct pose changes; the 🩰 button appears only while she is restless, and the 👏 button appears only while she is waiting for applause. Both stay outside her silhouette and disappear during focus or care needs. The 🩰 also offers earned dance rewards after her bow; it never overlaps the clap prompt.

## Overstimulation and grounding

Six deliberate head rubs, completed moves, or chosen dances within twenty seconds can overstimulate her. She withdraws from her usual animations, first looking overwhelmed and then settling into a closed-eye pose. She plays the same sample used for sleep once, then ignores all character interactions for thirty visible, unpaused seconds. Head rubs, pokes, body or Option dragging, coffee, note requests, new focus sessions, dances, and animation previews cannot interrupt her or restart that interval. An existing focus timer can continue in the background. After settling she has a sixty-second cooldown before she can become overstimulated again. Ordinary note clicks, typing, applause, and coffee do not build stimulation.

Notes are unavailable during overstimulation. An already open note is saved and tucked away, then returned after recovery; closed notes stay closed and ignored note requests create no queued notes. Underlying coffee and affection needs remain intact and resume after the quiet break. Character interaction menus are disabled; app settings, mute, hide, and quit remain available. Overstimulation is session-only. Try “A little quiet, please” in the animation menu to see it immediately. A soft, translucent oval shadow grounds her beneath her feet, following her position and widening for floorwork and resting poses; the shadow does not intercept desktop clicks.

Giving affection keeps previously closed notes closed. Head taps while she is upset do not queue note requests. Only an explicitly requested note, or a note she took away while it was open, returns after care. Explicitly closing notes cancels a pending request.

## Focus mode

The tiny timer on the Post-it is adjustable by dragging its time vertically: up adds time, down removes it, at one-minute steps per six points of movement, between one minute and twenty-four hours. Adjust it before starting, while running, or while paused. A click starts the chosen duration, or pauses/resumes an active session; releasing a drag never fires that click. The countdown freezes while actively dragging, and changing remaining time preserves elapsed time and her current stretch. The chosen duration remains available for later sessions until the app quits. It starts at 25 minutes. The “…” menu and robot/menu-bar menu offer 15, 25, or 45 minutes, plus pause, resume, and stop. A visible “■ stop” button sits beside the timer whenever focus is running or paused; stopping wakes her and preserves the current note. During focus she gently stretches for fourteen seconds at the start and every three minutes: warm-up, seated straddle, supported middle split, a side lean, pancake preparation, a half fold, a low pancake, and recovery. She then curls up and naps. The same routine occasionally joins her normal quiet idle behavior. Dances, coffee needs, and tumbles pause so she stays quiet; notes remain usable while she is content. A paused session freezes the countdown and leaves her napping. When the timer finishes she takes 4.2 seconds to wake: sleepy eyes, uncurling into a seated pose, a little side stretch, an overhead stretch, a blink, and her familiar visor wink. This reuses her existing artwork with direct pose changes. Notes stay available and previously closed notes stay closed. Reduced motion uses a settled pose. Mac sleep suspends the session clock; sessions end when the app quits, while notes and care state remain saved.

Opening or creating a note makes her unfold a miniature lined Post-it. Closing the note makes her fold it and tuck it away. “Move to trash” gets a dramatic crumple and paper-ball toss; the note stays recoverable in the existing restore menu. Notes open immediately during a sip, and the paper gesture follows after she finishes. The focus timer and its small stop button are the additional visible Post-it controls. Reduced-motion preferences suppress moving decorations and use settled poses.

**Control–Option–N** opens a new note from any app. Choose one of three shortcut combinations from the menu bar if another app uses that combination. **Command–N** creates a note while the notes panel has focus. **Escape** closes the panel.

Notes save automatically after a short typing pause. Write directly on a small yellow Post-it. The “…” menu switches notes, pins favorites, exports Markdown and restores deleted notes. Closing Velvet saves immediately. Notes and preferences live in `~/Library/Application Support/Velvet/notes.json`; the menu's “Show notes folder” opens their location. Back up this folder to keep a copy of your notes.

## Build

Requires macOS 13 or later, Apple silicon, and Apple's Command Line Tools. This build was tested on macOS 26.4.1 with Swift 6.3.1.

```sh
zsh build.sh
open build/Velvet.app
```

The build uses only system frameworks and applies a local ad-hoc signature. It has not been notarized for public distribution.

## Verification

```sh
swiftc -swift-version 5 -module-cache-path build/module-cache Sources/CoffeeState.swift Sources/CompanionCare.swift Sources/FocusSession.swift Sources/PerformanceState.swift Sources/LifestyleState.swift Sources/TutorialState.swift Sources/SongRequestState.swift Sources/CompanionRoutine.swift Sources/Store.swift Tests/StoreTests.swift -o build/store-tests
build/store-tests
swiftc -swift-version 5 -module-cache-path build/module-cache Sources/CompanionCare.swift Sources/FocusSession.swift Sources/CompanionInteraction.swift Sources/CompanionResponse.swift Sources/PerformanceState.swift Sources/ListeningState.swift Sources/StimulationState.swift Tests/InteractionTests.swift -o build/interaction-tests
build/interaction-tests
swiftc -swift-version 5 -module-cache-path build/module-cache Sources/LifestyleState.swift Sources/TutorialState.swift Sources/PerformanceState.swift Tests/LifestyleTests.swift -o build/lifestyle-tests
build/lifestyle-tests
python3 Tests/AudioAssetsTests.py
```

Persistence tests cover Unicode text, search, pinning, trash, restore, preferences, export content and preservation of an unreadable archive. `--data-dir /absolute/path` uses an isolated data folder for development. `--smoke-test /absolute/path/result.json` checks windows, focus, hit regions and hotkey registration, renders a notes preview, and exits. `--render-preview /absolute/path` renders the character's poses and exits.

Interaction checks cover short strokes and holds without window movement, body and Option dragging, missed latte drops, independent coffee/affection gates, deferred note delivery, persistent upset states, tumble timing, focus stretching, napping, pausing, and completion, latte-to-zoomies timing, paper-gesture priority, shy smiles, quiet reconciliation, natural response expiry, restless timing, completed versus interrupted dances, held finishing poses, applause clicks, and focus/care priority. The native app check runs against an isolated archive, checks all 116 loaded sprites, and renders the lined Post-it and focus/tumble poses.

The previous native run passed 211 checks across timer dragging, splits/pancake stretching, overstimulation, quiet recovery, soft shadow rendering, intentional note restoration, restless/show-off moods, emoji applause, focus stop/stretch controls, Robot disco, latte/reconciliation responses, and existing mechanics, including operating-system key-window status, editor first-responder focus, window visibility, shortcut registration, independent note gates, and note restoration. The pure interaction and persistence suites also pass.

## First-version scope

Velvet blinks, breathes, waves, shuffles, dances, reacts when picked up or when a note saves, gives side-eye, and sleeps after inactivity. The strut happens in place; it does not roam across your desktop. Hidden characters stop their timer. Reduced-motion preferences suppress the movement. Shortcut configuration currently provides three presets. There is no cloud sync or automatic launch at login.

Her navy screen uses tiny cyan pixel LED expressions with subtle pink accents, while her blue shell stays softly rendered in 3D. The current artwork is saved in `Assets/velvet-sprites-v5.png`, `Assets/vogue-sprites-v2.png` and `Assets/iced-latte-sprites-v2.png`. The built-in image tool was used. Face-edit prompts are in `Assets/PIXEL-FACE-PROMPTS.txt`; the original generation prompts are in `Assets/SPRITE-PROMPT.txt`, `Assets/VOGUE-PROMPT.txt` and `Assets/ICED-LATTE-PROMPT.txt`. Earlier sheets are kept for reference.

The sixteen additional interaction sprites are in `Assets/interaction-sprites-v2.png`. The built-in image tool generated the sheet with the saved prompts `Assets/INTERACTION-PROMPT.txt` and `Assets/INTERACTION-LAYOUT-PROMPT.txt`. The atlas loader accounts for the sheet's uneven transparent row gutters and normalizes its character size to the existing standing robot.


Eight matching stretch, nap, tumble, crying, and recovery poses are saved in `Assets/wellbeing-sprites-v1.png`, generated with the built-in image tool using `Assets/WELLBEING-PROMPT.txt`. The loader respects its uneven row gutter and matches the standing sprite height while keeping the existing robot size.


“Robot disco” adds four matching poses: alternating diagonal points, a mechanical groove, and a wink/step finish, with gentle side steps and short crossfades. Choose it from her right-click or menu-bar menu; it also joins occasional idle dances once unlocked. Focus and care needs override it. New artwork is `Assets/disco-sprites-v1.png`, generated using the built-in image tool with the saved prompt in `Assets/DISCO-PROMPT.txt`.


The whole companion now renders on a 1.6-point pixel grid with nearest-neighbor display, solid pixel edges, and simplified color levels for a subtle 8-bit look. Pixel blocks are 20% smaller than the earlier two-point treatment, with finer color steps; the character's size stays unchanged. This applies to all existing dances, expressions, the iced latte, and hearts. The lined note and its text stay sharp at their normal resolution. Original artwork files are preserved; this is an app rendering style.

House adds four grounded jack, heel-toe, cross-step, and loose-leg poses. Waacking adds four quick arm-arc, sweep, orbit, and flourish poses. Both are sprite routines inspired by the styles rather than motion-captured choreography. Once unlocked, House joins the automatic repertoire and replaces Ballet poses in latte zoomies; Vogue Fem and Waacking remain choices only. Her cyan pixel `> -` visor expression appears for roughly half of normal idle time, while waving, and in the restless steps. The blank belly and current size/pixel rendering stay unchanged. The twelve additional poses are in `Assets/club-sprites-v1.png`, generated with the built-in image tool using `Assets/CLUB-SPRITES-PROMPT.txt`. The loader follows its transparent row gutters to avoid clipping the third row.

The eight additional supported splits and pancake poses are saved in `Assets/stretch-sprites-v1.png`, generated with the built-in image tool using `Assets/STRETCH-PROMPT.txt`. The first cell is standing so the atlas keeps her existing head size in the seated poses; the loader follows the uneven row gutter. Native timer checks cover actual hit regions, clicks versus drags, duration changes before start and while running/paused, countdown suspension while dragging, preserved stretch progress, stopping, and unchanged notes.


Breakdance is a menu-only twelve-second routine: toprock, a go-down, alternating six-step-inspired footwork and leg sweeps, a baby freeze, a backspin pose, and a held side-freeze finish. It appears under “Choose a dance” in the menu bar, robot right-click menu, and restless dance chooser; it never joins idle dancing or latte zoomies. Focus and care needs take priority. Eight new illustrations are in `Assets/breakdance-sprites-v1.png`, generated with the built-in image tool using `Assets/BREAKDANCE-PROMPT.txt`. The app preserves the tiny size, subtle pixel rendering, and direct pose changes.

Included sounds: `Assets/vogue-chant.wav` (or `vogue-sound.wav`) plays the longer chant only during a chosen Vogue routine, looping as needed until the dance ends. `Assets/head-pet.wav` plays the shorter sample once per head stroke or hold. Repeated pets restart a single sound rather than layering it. Interrupting Vogue, hiding Velvet, or starting focus stops playback; animation pause pauses the chant. `Assets/tumble.wav` plays once when she falls over, and comforting her replaces it with the head-pet sound. `Assets/latte-sip.wav` plays a six-second mix when she accepts an iced latte, including a successful cup drop or the coffee menu action; a missed drop stays silent. Yung Riser and Liquor start together as the cup reaches her mouth, and Nelly enters with her approving nod at 4.8 seconds. Liquor is balanced eight dB quieter than the riser. The original balanced components remain in `Assets/latte-riser.wav`, `Assets/latte-liquor.wav`, and `Assets/coffee.wav`. The finished mix keeps their original timing and pitch. Interruptions stop it; animation pause freezes the sip and audio together. Starting focus stops this sample too. “Companion sounds” in her menu turns all sounds off. The Vogue sprite rhythm follows the supplied 128 BPM loop and holds its final dip. WAV, MP3, M4A, AIFF, and AIF files are supported. The samples and prepared latte mix ship in this repository with the character artwork. Additional unnamed audio imports stay ignored until explicitly added. Builds without samples still run silently.


`Assets/crossed-arms.wav` plays once when she becomes annoyed, then stays quiet while she holds that mood. `Assets/breakdance.wav` plays the supplied track once during a chosen Breakdance routine, pauses/resumes with animation pause, and stops on interruption, focus, hiding, or the end of the routine. `Assets/overwhelmed-sleep.wav` plays once at the start of an overwhelmed episode, ordinary idle sleep, or a focus nap; it never loops or restarts on every animation frame. Outside overstimulation, affection replaces a mood sound with the head-pet sample. Bundled sounds match roughly -20 LUFS, with the Liquor layer deliberately at -28 LUFS and a 0.65 master volume. The prepared sip mix also measures -20 LUFS. The level measurements are saved in `Assets/AUDIO-LEVELS.json`; very short effects are repeated for measurement only. Original imports remain untouched locally. Building Velvet needs no additional audio tools.


`Assets/clap.wav` plays once when you click the 👏 button or successfully choose the applause action; waiting for applause and refused applause actions stay silent. `Assets/house.wav` and `Assets/waacking.wav` supply the new dance loops. Dance music plays only when a routine is chosen from the menu bar, robot menu, animation menu, or restless dance chooser. Spontaneous routines and latte zoomies stay silent. Switching routines replaces the track; pets, focus, hiding, ending the routine, or muting stop it. Pausing freezes chosen dance time and music together, then resumes both. House loops as needed through its twelve-second phrase; the longer Waacking track stops when its routine ends. No new libraries or audio tools are needed to build the app.


`python3 Tests/AudioAssetsTests.py` verifies all seventeen bundled WAV assets against their saved loudness/peak measurements and checks the actual latte mix waveform: simultaneous riser/Liquor starts, the quieter Liquor layer, Nelly at the 4.8-second approving nod, and an exact six-second duration. It uses only Python’s standard library.


## Dance unlocks

Ballet is earned free through the first-launch tutorial. Three timely claps buy one dance of your choice, including its first performance. Replaying any unlocked routine from the menu costs one clap; the menu shows the spendable balance and disables unaffordable choices. Menu dances never offer applause afterward. Only spontaneous dances offer the six-second fading 👏 prompt. Missing the prompt earns no credit and briefly disappoints her. Lifetime claps, unlocks and replay spending persist together; existing profiles keep their progress. Actions and dances remain in separate, alphabetically sorted menus. The first profile can earn its initial claps from spontaneous Ballet without spending anything. When restless at zero balance, she offers a free Ballet to settle that need; this selected performance grants no applause reward.


The native suites cover regression behavior, care/tutorial interactions, song requests and daily routines. The suite covers menu-replay spending and no applause farming, zero-balance restless Ballet, spontaneous clap rewards, unlocks and persistence, the white-earbud animation, focus priority, preserved notes, and every chosen dance track including Contemporary, Robot disco and licensed Floorwork. The care checks exercise the real bar drag and head hold, resumable Ballet tutorial, whole-body phone sulk, naps/waking, hunger/attention gates, and refund when notes interrupt a paid replay. Interaction, persistence, seventeen bundled audio assets and the live non-Spotify playback exclusion check also pass. Native checks can be launched with `open -n build/Velvet.app --args --data-dir /absolute/temporary/path --smoke-test /absolute/path/result.json`. Spotify filtering is checked against its exact installed bundle identifiers; a live Spotify playback session was not started for the tests.


Ballet now plays a twelve-second excerpt of Chopin’s **Waltz in A minor, B. 150**, performed by **Aya Higuchi**, when deliberately chosen. The performance is explicitly released under CC0; the composition is public domain. Source, license, excerpt boundaries, preparation recipe, and recording checksum are recorded in [Assets/BALLET-AUDIO.md](Assets/BALLET-AUDIO.md). The piano preserves its dynamics and matches the other foreground sounds at -20 LUFS, with a gentle one-second ending. Spontaneous Ballet and latte zoomies stay silent.

Completed spontaneous routines offer the six-second fading 👏 prompt. All selected routines, the first unlock performance, interrupted routines and preview applause do not award clap credit.


## Listening with headphones

“Listen to Spotify” is enabled by default on macOS 14.2 and later and can be turned off in her menu. After a second of sustained playback from the Spotify desktop app, Velvet puts in tiny white wired earbuds and gently sways with a sleepy, content visor. Three seconds of silence starts a short taking-off animation; brief gaps between tracks keep the headphones on. Pausing freezes the animation. Care, focus, chosen dances, applause, paper gestures and dragging take priority; she returns to listening when free and playback continues. Listening leaves notes available and pauses the restless-dance clock. Only Spotify’s exact desktop and helper bundle identifiers are accepted; browsers, other players and her own sounds are excluded.

The detector caches Spotify’s audio-process identities, refreshes them on CoreAudio process-list changes, and reads only their playback flags every half-second. When no Spotify audio process exists, it uses a ten-second fallback instead; it does not tap, record, analyze or store sound, and does not need microphone or screen-recording access. The indication is active output streams, so an app that keeps a silent stream running may still trigger listening. Older macOS versions run Velvet normally with this option unavailable. The saved optional preference is backward-compatible with existing note archives.

The detector tests verify Spotify identity filtering and exclusion of a real silent non-Spotify output stream:

```sh
swiftc -swift-version 5 -module-cache-path build/module-cache Sources/SystemAudioMonitor.swift Sources/SongRequestState.swift Tests/SystemAudioTests.swift -framework CoreAudio -o build/system-audio-tests
build/system-audio-tests Assets/ballet.wav
```

Robot disco uses “Disco Medusae” by Kevin MacLeod and Floorwork uses “Sexy Scene Instrumentals Vol. 8” by Sascha Ende. Both recordings are CC BY 4.0, ship in the repository and app, and have attribution available through Music credits. Twelve-second excerpts are matched to the other foreground sounds at approximately -20 LUFS. Contemporary uses “Dreams Become Real” by Kevin MacLeod under the same license and loudness target; see [Contemporary credits and preparation](Assets/CONTEMPORARY-AUDIO.md). See [Disco credits and preparation](Assets/DISCO-AUDIO.md), [Floorwork credits and preparation](Assets/FLOORWORK-AUDIO.md) and [bundled credits](Assets/MUSIC-CREDITS.txt).

The care artwork was generated with the built-in imagegen tool. The bundled sixteen-frame sheet is `Assets/care-sprites-v2.png`; its final prompt and layout are saved in [Assets/CARE-ART.md](Assets/CARE-ART.md). Native care checks use a separate profile:

```sh
build/Velvet.app/Contents/MacOS/Velvet --data-dir /absolute/temporary/path --lifestyle-smoke /absolute/path/result.json
```


Additional isolated checks:

```sh
swiftc -swift-version 5 -module-cache-path build/module-cache Sources/CompanionRoutine.swift Sources/CompanionInteraction.swift Tests/RoutineTests.swift -o build/routine-tests
build/routine-tests
swiftc -swift-version 5 -module-cache-path build/module-cache Sources/SongRequestState.swift Sources/PerformanceState.swift Tests/SongRequestTests.swift -o build/song-tests
build/song-tests
```

Native `--routine-smoke`, `--song-smoke` and `--lifestyle-smoke` accept an absolute result JSON path alongside `--data-dir` pointing to a temporary profile. They do not control Spotify or access the personal notes archive. The latte riser/liquor/Nelly mix plays at 65% of the chosen master volume (35% quieter than previously), with its internal balance unchanged.

The sixteen daily-routine frames are in `Assets/daily-sprites-v1.png`. Their layout and the downward-dog proportion correction are recorded in [Assets/ROUTINE-ART.md](Assets/ROUTINE-ART.md).


## CPU usage

Velvet now uses 12 updates per second for idle expressions, four for quiet poses, and 24 for dances, head gestures and prop dragging. Mouse-movement monitoring keeps the click-through hitbox responsive between quiet updates. Care clocks advance by elapsed time rather than frame count. Unchanged sleeping/paused poses stop repainting, and repeated static draws reuse their pixel image. The bitmap drawing context, shadow gradient and colour lookup are reused. Spotify detection caches matching processes and responds to process-list changes, avoiding a complete audio-process scan every half-second.

A reproducible native measurement runs five-second idle, sleep, pause, dance and hidden scenarios, with silent samples, Spotify monitoring disabled, temporary notes and no global shortcut. It also checks static image reuse, changed-pose/resize invalidation and head-hold handling:

```sh
build/Velvet.app/Contents/MacOS/Velvet --data-dir /absolute/temporary/path --cpu-profile /absolute/path/cpu.json
```

See [PERFORMANCE.md](PERFORMANCE.md) for before/after results and their limits.
