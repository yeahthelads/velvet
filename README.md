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

She keeps your notes in `~/Library/Application Support/Velvet/notes.json`. That personal archive, build outputs, and test data are excluded from this repository. The four sound samples are included. There is no cloud sync, telemetry, or network service. The source and character artwork are included; the app currently uses a local ad-hoc signature rather than a notarized release.

## Use

Open `build/Velvet.app`. Velvet appears near the lower-right corner of your desktop; click her face or body to open notes, stroke or briefly hold her head for affection, and drag her body to move. Option-drag moves her from anywhere. The sparkle in the menu bar contains hide/show, pause, always-on-top, position reset and animation previews.

Choose a routine from “Choose a dance” in the menu-bar sparkle or her right-click menu. Ballet, Floorwork, Robot disco, and House also join her occasional idle animations. Vogue Fem, Waacking, and Breakdance play only when explicitly selected. The choreography uses four illustrated poses per dance with continuous bobbing and a subtle sway; it is a short sprite animation, not motion-captured dance.

“Vogue Fem” adds hand performance, a cross-step, a low step and a supported dip. The character first rendered 20% smaller and now renders another 30% smaller, at 56% of the original size. Her latte, paper effects, shadow, motion, and rotation pivot scale with her; notes retain their existing size and stay beside her. Notes have unbranded, textured ruled paper and handwriting-style text; the text and rules scroll together.

## Coffee and attitude

After 15 minutes of visible, unpaused time she gets grumpy. Drag the rendered iced latte into her waiting hand on the right. She reaches toward it, accepts the cup, raises the pink straw, sips and gives an approving nod. A missed drop slides the cup back without feeding her or resetting the timer. You can also click the cup or choose “Give her an iced latte” in the menu. The drink has a clear lid, ice cubes and milk/espresso layers, with lighting matched to the character. She refuses notes and dances until she gets her latte. If a note was open, she tucks it away and returns it once her needs are met; its contents stay saved. A blocked new-note request creates one note after she is soothed, rather than accumulating empty notes. Hiding her, pausing animations, focus mode, or sleeping the Mac pauses the coffee clock. Her coffee state persists across restarts. “Make her grumpy” in the menu lets you try the mechanic immediately.

Her whole head, including her face, is pettable. Stroke at least 8 points or hold for about 0.35 seconds to give affection and see a happy pixel smile with tiny hearts. A head gesture stays a pet even if the pointer leaves her head; it cannot become a window drag. A quick tap opens notes. Drag her body or hold Option to move her instead. Her idle float is now less than half a point from top to bottom.

Four quick head pokes within three seconds earn crossed arms. She keeps that mood and withholds notes until she gets affection; waiting or giving coffee does not clear it. If she needs both affection and coffee, both must be given. Her upset state survives restarts. “A little head rub” in the menu provides the same affection reaction without a pointer gesture.

A rare stumble makes her fall onto her side, then cry with tiny pixel tears. Head strokes or a brief hold comfort her; she sits up with hearts and returns any waiting note. Tumbles happen after a randomized 30–60 minutes of eligible visible, awake time. Their clock pauses during focus, sleep, animation pause, reduced motion, dancing, dragging, and care interactions; she cannot tumble again while upset. Her remaining interval and crying state are saved. Existing 45–90 minute countdowns are shortened proportionally once, while preserving current upset states. The animation preview menu can demonstrate a stumble immediately.

## Latte zoomies and reconciliation

After a successful iced latte she finishes her six-second sip and any queued paper gesture, then gets eight seconds of zoomies: a quick in-place strut, three House footwork poses, a nod/wink, and a gentle settle. Opening notes interrupts the burst immediately for the paper gesture, then the remaining zoomies resume. Nothing moves her desktop window. Each accepted latte triggers at most one burst; missed drops do not trigger it. Focus and new upset states cancel a queued or active burst, and reduced-motion mode keeps a settled pose. Animation pause, hiding, and dragging freeze the eligible response clock.

Comforting crossed arms or crying starts 90 seconds of quiet reconciliation after the initial affection/recovery. She leans slightly toward the visible note and gives a shy pixel smile after 12 seconds, then every 16 seconds for about two seconds each. Normal head rubs still work without starting a new reconciliation. Her random dances, hover side-eye, and autosave celebrations stay quiet during this phase. Notes remain accessible. Focus pauses the phase while she stretches/naps, a new upset overrides it, and she returns to her usual idle behavior when it ends. These brief responses are session-only; notes and care needs remain saved. The animation menu includes “Latte zoomies”, “Staying close”, and “A shy little smile” for previews. Existing approved sprites are reused with small position, tilt, and crossfade changes.

## Restless and show-off moods

After 6–10 minutes of eligible awake time she gets restless, tapping and shifting her feet until you click the **🩰** beside her and choose **Ballet**, **Floorwork**, **Vogue Fem**, **Robot disco**, **House**, **Waacking**, or **Breakdance** from the menu it opens. The robot’s right-click menu and the menu-bar sparkle also have an explicit “Choose a dance” submenu with the same seven choices. Finishing that twelve-second routine settles her and resets the interval; an interrupted routine leaves the need unresolved. Every completed dance has a 15% chance of holding the actual finishing pose with a small clickable **👏** beside her. Most dances simply finish and settle her. Click that emoji to applaud: it disappears and she gives a bow with tiny hearts. The emoji click leaves notes and her desktop position alone. Face and body clicks keep their normal notes behavior. A head stroke or brief hold still gives affection. “Needs a dance break” and “Waiting for applause” in the animation menu let you try both moods; “Applaud her” also appears in her menu while she is waiting.

These playful moods keep notes available. Paper gestures briefly interrupt them and return to the same need or held finish. Focus suspends restlessness and cancels applause requests; care needs override both, and dances or applause cannot clear coffee or affection requirements. Restless time pauses while hidden, asleep, paused, in reduced-motion mode, dancing, receiving care, interacting, or reconciling. These moods are session-only. Existing sprites keep the same small size, pixel rendering, and direct pose changes; the 🩰 button appears only while she is restless, and the 👏 button appears only while she is waiting for applause. Both stay outside her silhouette and disappear during focus or care needs.

## Overstimulation and grounding

Six deliberate head rubs, completed moves, or chosen dances within twenty seconds can overstimulate her. She withdraws from her usual animations, first looking overwhelmed and then settling into a closed-eye pose. Leave her alone for thirty visible, unpaused seconds to resolve it; more fussing restarts that interval. Focus also provides quiet recovery while she stretches and naps. After settling she has a sixty-second cooldown before she can become overstimulated again. Ordinary note clicks, typing, applause, and coffee do not build stimulation.

Notes remain usable during overstimulation. Dances and latte zoomies stay quiet, and her coffee/affection needs keep their existing priority. Overstimulation is session-only. Try “A little quiet, please” in the animation menu to see it immediately. A soft, translucent oval shadow grounds her beneath her feet, following her position and widening for floorwork and resting poses; the shadow does not intercept desktop clicks.

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
swiftc -swift-version 5 -module-cache-path build/module-cache Sources/CoffeeState.swift Sources/CompanionCare.swift Sources/FocusSession.swift Sources/Store.swift Tests/StoreTests.swift -o build/store-tests
build/store-tests
swiftc -swift-version 5 -module-cache-path build/module-cache Sources/CompanionCare.swift Sources/FocusSession.swift Sources/CompanionInteraction.swift Sources/CompanionResponse.swift Sources/PerformanceState.swift Sources/StimulationState.swift Tests/InteractionTests.swift -o build/interaction-tests
build/interaction-tests
```

Persistence tests cover Unicode text, search, pinning, trash, restore, preferences, export content and preservation of an unreadable archive. `--data-dir /absolute/path` uses an isolated data folder for development. `--smoke-test /absolute/path/result.json` checks windows, focus, hit regions and hotkey registration, renders a notes preview, and exits. `--render-preview /absolute/path` renders the character's poses and exits.

Interaction checks cover short strokes and holds without window movement, body and Option dragging, missed latte drops, independent coffee/affection gates, deferred note delivery, persistent upset states, tumble timing, focus stretching, napping, pausing, and completion, latte-to-zoomies timing, paper-gesture priority, shy smiles, quiet reconciliation, natural response expiry, restless timing, completed versus interrupted dances, held finishing poses, applause clicks, and focus/care priority. The native app check runs against an isolated archive, checks all 84 loaded sprites, and renders the lined Post-it and focus/tumble poses.

The native run passed 154 checks across timer dragging, splits/pancake stretching, overstimulation, quiet recovery, soft shadow rendering, intentional note restoration, restless/show-off moods, emoji applause, focus stop/stretch controls, Robot disco, latte/reconciliation responses, and existing mechanics, including operating-system key-window status, editor first-responder focus, window visibility, shortcut registration, independent note gates, and note restoration. The pure interaction and persistence suites also pass.

## First-version scope

Velvet blinks, breathes, waves, shuffles, dances, reacts when picked up or when a note saves, gives side-eye, and sleeps after inactivity. The strut happens in place; it does not roam across your desktop. Hidden characters stop their timer. Reduced-motion preferences suppress the movement. Shortcut configuration currently provides three presets. There is no cloud sync or automatic launch at login.

Her navy screen uses tiny cyan pixel LED expressions with subtle pink accents, while her blue shell stays softly rendered in 3D. The current artwork is saved in `Assets/velvet-sprites-v5.png`, `Assets/vogue-sprites-v2.png` and `Assets/iced-latte-sprites-v2.png`. The built-in image tool was used. Face-edit prompts are in `Assets/PIXEL-FACE-PROMPTS.txt`; the original generation prompts are in `Assets/SPRITE-PROMPT.txt`, `Assets/VOGUE-PROMPT.txt` and `Assets/ICED-LATTE-PROMPT.txt`. Earlier sheets are kept for reference.

The sixteen additional interaction sprites are in `Assets/interaction-sprites-v2.png`. The built-in image tool generated the sheet with the saved prompts `Assets/INTERACTION-PROMPT.txt` and `Assets/INTERACTION-LAYOUT-PROMPT.txt`. The atlas loader accounts for the sheet's uneven transparent row gutters and normalizes its character size to the existing standing robot.


Eight matching stretch, nap, tumble, crying, and recovery poses are saved in `Assets/wellbeing-sprites-v1.png`, generated with the built-in image tool using `Assets/WELLBEING-PROMPT.txt`. The loader respects its uneven row gutter and matches the standing sprite height while keeping the existing robot size.


“Robot disco” adds four matching poses: alternating diagonal points, a mechanical groove, and a wink/step finish, with gentle side steps and short crossfades. Choose it from her right-click or menu-bar menu; it also joins occasional idle dances. Focus and care needs override it. New artwork is `Assets/disco-sprites-v1.png`, generated using the built-in image tool with the saved prompt in `Assets/DISCO-PROMPT.txt`.


The whole companion now renders on a 1.6-point pixel grid with nearest-neighbor display, solid pixel edges, and simplified color levels for a subtle 8-bit look. Pixel blocks are 20% smaller than the earlier two-point treatment, with finer color steps; the character's size stays unchanged. This applies to all existing dances, expressions, the iced latte, and hearts. The lined note and its text stay sharp at their normal resolution. Original artwork files are preserved; this is an app rendering style.

House adds four grounded jack, heel-toe, cross-step, and loose-leg poses. Waacking adds four quick arm-arc, sweep, orbit, and flourish poses. Both are sprite routines inspired by the styles rather than motion-captured choreography. House joins the automatic repertoire and replaces Vogue poses in latte zoomies; Vogue Fem and Waacking remain choices only. Her cyan pixel `> -` visor expression appears for roughly half of normal idle time, while waving, and in the restless steps. The blank belly and current size/pixel rendering stay unchanged. The twelve additional poses are in `Assets/club-sprites-v1.png`, generated with the built-in image tool using `Assets/CLUB-SPRITES-PROMPT.txt`. The loader follows its transparent row gutters to avoid clipping the third row.

The eight additional supported splits and pancake poses are saved in `Assets/stretch-sprites-v1.png`, generated with the built-in image tool using `Assets/STRETCH-PROMPT.txt`. The first cell is standing so the atlas keeps her existing head size in the seated poses; the loader follows the uneven row gutter. Native timer checks cover actual hit regions, clicks versus drags, duration changes before start and while running/paused, countdown suspension while dragging, preserved stretch progress, stopping, and unchanged notes.


Breakdance is a menu-only twelve-second routine: toprock, a go-down, alternating six-step-inspired footwork and leg sweeps, a baby freeze, a backspin pose, and a held side-freeze finish. It appears under “Choose a dance” in the menu bar, robot right-click menu, and restless dance chooser; it never joins idle dancing or latte zoomies. Focus and care needs take priority. Eight new illustrations are in `Assets/breakdance-sprites-v1.png`, generated with the built-in image tool using `Assets/BREAKDANCE-PROMPT.txt`. The app preserves the tiny size, subtle pixel rendering, and direct pose changes.

Included sounds: `Assets/vogue-chant.wav` (or `vogue-sound.wav`) plays the longer chant only during a chosen Vogue routine, looping as needed until the dance ends. `Assets/head-pet.wav` plays the shorter sample once per head stroke or hold. Repeated pets restart a single sound rather than layering it. Interrupting Vogue, hiding Velvet, or starting focus stops playback; animation pause pauses the chant. `Assets/tumble.wav` plays once when she falls over, and comforting her replaces it with the head-pet sound. `Assets/coffee.wav` plays once when she accepts an iced latte, including a successful cup drop or the coffee menu action; a missed drop stays silent. Starting focus stops this sample too. “Companion sounds” in her menu turns all four off. The Vogue sprite rhythm follows the supplied 128 BPM loop and holds its final dip. WAV, MP3, M4A, AIFF, and AIF files are supported. The four samples ship in this repository with the character artwork. Additional unnamed audio imports stay ignored until explicitly added. Builds without samples still run silently.
