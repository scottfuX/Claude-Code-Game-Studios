# First-night feel-pass overrides

The production slice Resource assets/data/slice_defaults.tres overrides GDD clock rates with 0.47 real seconds per game minute in every normal phase: 963 minutes = 452.61 seconds (7m32.61s), still day 1 16:30 to day 2 sunrise. Wait stays separate. Fire fuel/burn per game minute is unchanged; one log cannot carry an idle survivor warm to dawn.

Fire GDD specifies three game minutes with no tuning range. This slice deliberately overrides smolder_life to 16 minute ticks: nominal 7.52 real seconds, at least about 7.05 seconds depending tick alignment. Blow initially takes 0.47 seconds. This is a slice exception, not a GDD range claim. Ember lifetime remains 90 game minutes (42.3 real seconds).

HUD slice Resource keeps onboarding until first flame, with H-reopenable help and pause help. Always-visible qualitative stamina fill/state and trend depart from HUD H4's warning-only energy display; no internal numeric meters are shown. Backpack remains live, now explicitly labeled. Simple missing recipe counts are user-facing item counts, not fuel/thermal numbers.

Atmosphere quality is selected once per run from assets/data/atmosphere_defaults.tres. Auto keeps full ambient wind/fire loops on GPUs and selects Low for llvmpipe, softpipe, lavapipe, SwiftShader and software adapter names. Low disables those two loops but retains footstep/action sounds and all visual effects; High and Low can be forced in the Resource, and both loop defaults are editable. This is an explicit software-renderer audio-quality exception, not missing audio content.

A single-pass, staged night/fire ablation at 1152×648 OpenGL3 (30 warm-up frames, 180 measured frames per variant) found audio-off fastest: median 10.61 FPS versus 8.98 all-on. Other removals were sometimes slower, so this noisy software-renderer result is a quality-selection input, not a confirmed bottleneck or a prediction of GPU performance.

## Deferred feel issues

[Scott's replay of main fce1b66](../production/qa/playtests/playtest-2026-11-20-scott-replay.md) records flat snow contact and contextually strange animations as polish backlog for the next feel/art-animation pass. Ground remains flat with visual footprint marks; broad reused clips and procedural layers need later contextual art/animation work. Neither is changed in code here.

The screen flicker was classified S2/P1 and fixed rather than deferred: fog colour now has one owner; sun/moon energy, colour and direction blend through twilight, with shadow opacity fading instead of switching the shadow path off at night. Keeping that path enabled removes the separately observed OpenGL3 boundary pop, but its night-time rendering cost was not benchmarked. Before/after GUI evidence and regression details are in the replay report. Scott's GPU recheck remains pending; slice timing and gameplay rules are unchanged.
