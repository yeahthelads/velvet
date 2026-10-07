# Velvet release checks

## 0.2.6 — compact speech bubbles

Checked on 7 October 2026. Shared speech bubbles now reserve an action row only when a button is visible. Text-only tutorial steps and song acknowledgements use ten-point padding above and below the measured text, with the tail placed separately. Tutorial, iron, song and consequence bubbles retain their bounded width and character anchoring.

All 75 native lifestyle/tutorial checks and 24 song-request checks passed in temporary profiles. Actual eating, affection and Continue-button bubble images were visually inspected. The macOS 13 app build and signature validation passed.

## 0.2.5 — accessories follow each pose

Checked on 7 October 2026. The tattoo, navel piercing, heart charm and leg warmers now use the standing body as their size reference; widening a sprite crop with arms or props no longer enlarges the accessories. Torso anchors and tilt are calibrated for individual dance, care and mirror poses. Covered hips conceal the tattoo instead of moving it to the other flank or drawing it onto a hand, cup or note. The charm follows the torso axis toward the neck, including upside-down breakdance poses. Crossed-leg, disco, waacking and mirror calf anchors were corrected separately; soles remain visible.

The standalone accessory rendering suite passed checks of rendered size across eight exposed poses, the inverted collar, hidden surfaces, both calves in fourteen calibrated poses, and unchanged pink sole pixels across the atlas. All 32 native styling checks passed in an isolated profile, including accessory purchases, saved ownership, menu availability and the original alpha/hitbox in all 128 cells. Full pose sheets and the actual desktop mirror preview were visually inspected. Palette verification still passed for all 125 robot poses and three isolated props. The macOS 13 app build and signature validation passed. The rendering continues to use cached pose images.

## 0.2.4 — nighttime caffeine recovery

Checked on 6 October 2026. A live process sample showed the app event loop running normally, while the saved companion was in a caffeine crash after 23:00. Scheduled bedtime had suspended the caffeine timer, leaving character interaction unavailable overnight.

Caffeine recovery now continues through the evening and night poses while Velvet is visible and unpaused. Screen lock, hiding and pause still suspend the clock. A crash continues to block care and notes until recovery; it cannot be bypassed by a nighttime wake-up. After recovery, her normal brief sleepy visit works and returns her to bed without opening notes. Note menu items reflect the crash gate, and the tooltip explains ordinary nighttime sleep separately.

All 73 native care checks passed in a temporary profile, including seven new regressions for overnight crash recovery, disabled note actions, preserved sleeping pose, reachable head hitbox and the short cuddle/return-to-bed cycle. The app build and signature verification passed.

## 0.2.3 — visible navel piercing

The silver bar and pink gem now render at 1.9 times their initial scale, centred higher on the same belly attachment point so the lower gem stays above the pink soles. This preserves the purchased/worn state and the concealed-pose rules. The change addresses an equipped piercing that was difficult to distinguish after desktop pixel rendering.

All 32 native styling checks passed in an isolated profile. The actual desktop preview was inspected and compared against the previous rendering; the visual change is confined to the belly jewellery. The source build and signature validation passed.

## 0.2.2 — consistent blue

Checked on 6 October 2026. Palette correction now covers all robot poses instead of selected sleep/drawing/mirror poses. Supplemental sheets load without their own correction, then the combined atlas is calibrated once against the original standing pose. Sampling the lit blue material avoids dark-crease bias in seated and folded poses. The change adds no per-frame animation processing.

The palette check covers all 128 cells: 125 robot poses and three isolated props. Corrected material median hue differs from the reference by at most 0.00043 turns; saturation differs by at most 0.00179. Per-pixel alpha is unchanged, brightness remains within one byte of the source, and dark visor pixels, mint LEDs, pink details and isolated props remain unchanged. The original standing image remains identical. All four full-pose sheets and representative before/after comparisons were visually inspected.

The macOS 13-targeted app build succeeded, and all 32 native styling checks passed in an isolated profile, including all-pose accessory silhouette checks, cached styling renders, purchases, menu availability and saved ownership.

## 0.2.1 — saving claps

Checked on 6 October 2026. Completing a spontaneous dance now settles an outstanding restless invitation and resets its eligible-time interval. Having enough claps to unlock another routine no longer shows the invitation button or the restless menu label; optional unlocks remain in the menu.

The isolated native interaction suite passed all 292 boolean assertions, including six successive earned claps, the three-clap optional unlock menu, unchanged saved balance after another 30 eligible seconds, paid replay costs, no menu applause farming and note visibility. The separate interaction and styling suites passed, including 10-clap accessory purchases and persistent ownership. No personal companion data was reset.

## 0.2.0

Checked on 6 October 2026. These checks used isolated profiles; personal notes and companion progress were not reset.

## Fixes in this update

- Restored pink leg warmers and the silver heart charm to Styling. Experience unlocks purchase eligibility; each costs 10 claps, and bought items remain owned.
- Styling menu availability refreshes when the menu opens, including after the mirror animation ends.
- Replaced all four BADSISTA vocal clips with short, quieter Jersey drip effects. Removed random idle reaction triggers; drips accompany accepting a drawing and finishing the mirror pose.
- Explicitly compiled for macOS 13. The earlier build inherited macOS 26 as its executable minimum despite declaring macOS 13 in its app metadata.
- Builds finish and validate their resources and signature before replacing the existing app. Failed updates retain the previous working app.
- Unknown future cosmetic identifiers no longer make the personal archive unreadable.

## Passed checks

A fresh source copy, containing repository assets and no local sample kit, built successfully. Both Apple Silicon and Intel executables compiled with a macOS 13 deployment target. The Apple Silicon app's local signature passed verification.

Eight native suites passed all **583 boolean assertions**:

| Suite | Assertions |
| --- | ---: |
| Styling | 32 |
| Drawing gifts | 23 |
| Song requests | 24 |
| Lifestyle and tutorial | 75 |
| Daily routine | 32 |
| Iron and screw feeding | 53 |
| Care and happiness | 66 |
| General interactions | 278 |

Separate state/persistence suites passed for styling, notes, interactions, lifestyle, iron, routines, song requests, drawing gifts and reaction cadence. These include purchase accounting, saved ownership, mandatory tutorial steps, feeding completion, drag-and-drop screws, one-time screw explanations, dance fatigue and note visibility after affection.

The audio asset checks passed for the seventeen existing samples and latte mix. The four replacement drips matched their source waveforms and measured approximately -23 LUFS, with the existing playback cooldown and foreground-audio priority preserved.

Build failure tests simulated a compiler error and a missing required asset. Both preserved the previous executable and removed incomplete staging files.

A live local audio-monitor check excluded non-Spotify output and detected its stopped state. Native Spotify request fixtures checked sustained matching playback and single clap rewards.

All 128 poses with all four cosmetics were rendered for review. Sprite alpha silhouettes remained identical; visible calves, back views, covered jewelry, mirror poses and laptop poses were inspected.

## Limits

Runtime checks were performed on the current Apple Silicon Mac. Intel and older macOS runtime behavior have not been tested on separate machines. Spotify output detection requires macOS 14.2. The build uses a local ad-hoc signature and is not notarized.

These checks cover the exercised cases; they do not guarantee that every combination of long-running companion states is bug-free.
