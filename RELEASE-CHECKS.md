# Velvet release checks

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
