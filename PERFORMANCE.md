# CPU optimisation

Measured on the same Mac on 3 October 2026, using the native `--cpu-profile` harness. Each mode warms up for 0.8 seconds and then measures roughly five seconds of actual AppKit window drawing. CPU time includes user and system time, reported as a percentage of one CPU core. Samples are silent, Spotify monitoring is stopped and notes use isolated temporary folders. The idle fixture freezes needs through tutorial mode, so activity remains comparable. Normal care mechanics are exercised separately.

| Mode | Before (% of one core) | After | Before draws / ~5 s | After draws / ~5 s |
| --- | ---: | ---: | ---: | ---: |
| Idle | 9.50% | 5.40% | 87 | 61 |
| Sleeping | 9.12% | 0.15% | 86 | 0 |
| Paused | 3.47% | 0.15% | 6 | 0 |
| Dancing | 9.56% | 9.68% | 84 | 121 |
| Hidden | 0.08% | 0.09% | 0 | 0 |

Idle CPU use fell about 43%; sleeping use fell about 98%, and paused use about 96%. Dance CPU use is comparable within sampling variation. Active choreography, pointer gestures and prop returns retain the 24 Hz timer; idle expressions use 12 Hz, quiet poses four Hz. The old extra redraw throttle skipped some active frames; the new scheduler preserves all active ticks. Hidden companion animation work remains stopped.

The comparison covers character rendering and its behaviour clock. It excludes Spotify detection and disk checkpoints to isolate that cost; real use also depends on screen scaling, pointer activity, visible notes, audio, other apps and current mood. Five-second samples are indicative, not a battery-life prediction.

## Changes

- Skip invalidating a pose that has not visibly changed. Sleeping or paused poses produce zero steady-state redraws in the measured window.
- Cache static pixel images; invalidate them for changed poses, bounds, pause state or motion settings. Reuse the bitmap graphics context, pixel-channel lookup and shadow gradient. Source art and pixel colour levels are unchanged.
- Avoid moving invisible controls or repeatedly setting window click-through state. Mouse-movement monitors keep hit testing responsive between quiet timer updates.
- Advance care by elapsed time with a one-second stall cap, preserving quiet-mode timing. Restarting a hidden/stopped companion resets that clock.
- Cache Spotify audio-process identities. CoreAudio process-list notifications refresh the cache immediately; a ten-second rescan handles missed driver notifications. Playback polling queries only cached Spotify process flags at 0.5-second intervals, slowing to ten seconds when there are no candidates. The observer, cache and timers are removed on stop. Exact bundle filtering and song matching remain unchanged.

## Validation

All 377 native assertions pass: 278 regression, 45 care/tutorial, 24 daily routine, 22 song-request and eight rendering/cadence checks. The rendering checks verify repeated static capture produces identical pixels without another rasterisation, pose/size invalidation, full dance/gesture cadence and head-hold affection. The focus scrub assertion allows one millisecond of floating-point roundoff while preserving its exact two-minute adjustment and pose requirement. Pure interaction checks, 17 balanced audio assets, code-signature verification, Spotify cache reuse/restart and live non-Spotify stream exclusion also pass. A real Spotify track was not started for validation.

```sh
zsh build.sh
build/Velvet.app/Contents/MacOS/Velvet --data-dir /absolute/temporary/profile --cpu-profile /absolute/path/cpu.json
```

Use a new temporary profile for each comparison. The result includes CPU percentages, timer ticks, draw counts and boolean rendering checks.
