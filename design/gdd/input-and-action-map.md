# Input & Action Map

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: skipped — Lean mode
> **Author**: owner + Devin (game-designer / ux-designer / gameplay-programmer lenses)
> **Last Updated**: 2026-11-17
> **Last Verified**: 2026-11-17
> **Implements Pillar**: 冷是真的 · 亲手做 (supporting — the controls must stay out of the way of the feel)

## Summary

Input & Action Map is the one place where keys, mouse and gamepad buttons become named game actions — move, interact, secondary, backpack, pause, camera turn. Every other system reads actions, never raw keys, so controls can be remapped, shown with the right button icons for the device in use, and later carried to touch screens. It also defines how a press is read (tap, hold, hold-to-confirm), how analog sticks are cleaned up, and which actions are live in gameplay versus in menus.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

Input & Action Map is an infrastructure layer on Godot's InputMap. It defines the action set (Core Rule 2), the default bindings for keyboard/mouse and gamepad (Rule 3), three input contexts that decide which actions are live (Rule 4), and the reading rules other systems rely on: a radial deadzone for sticks (Formula IN1), tap / hold / hold-to-confirm classification (IN2), and a short buffer so a press made just before an action ends is not lost (IN3). It publishes the active device so prompts show the right glyphs.

For the player the goal is that controls disappear: WASD and one context key (E) carry almost everything, as the brief says ("WASD 移动，E 情境动作，Tab 背包，Esc 菜单；手柄等价映射"), and nothing important is one accidental press away — tapping out (VS) needs a deliberate hold. The fire prototype taught two lessons kept here: all input must go through actions (it did), and one key must never mean two things in the same context (its R key was both "rotate camera" and "restart"). What each action *does* belongs to the systems that consume it: Interaction decides what E means for a given target, Character Controller turns the move vector into motion, Camera decides how turning works.

## Detailed Design

### Core Rules

1. **Actions only.** No gameplay or UI code reads a raw key, button or axis. All input is read through named actions in the project's InputMap (defined in `project.godot`, not created at runtime). Action names are a contract shared with consuming GDDs.
2. **Action set** (MVP unless marked):

   | Action | Kind | Meaning (owner of the behaviour) |
   |---|---|---|
   | `move_forward`, `move_back`, `move_left`, `move_right` | analog | movement vector (Character Controller) |
   | `move_hurry` | hold | push on — faster, costlier movement if Character allows it (Character Controller) |
   | `interact` | press / hold | primary context action on the current target (Interaction) |
   | `secondary` | press | secondary context action (e.g. add fuel vs. light; rest at the fire) (Interaction) |
   | `cancel_action` | press | stop the current timed action (Interaction); moving also cancels unless Interaction says otherwise |
   | `backpack` | press | open/close the backpack (Inventory UI) |
   | `pause_menu` | press | pause and open the menu (Screens & Menus) |
   | `camera_turn_left`, `camera_turn_right` | press | turn the camera (Camera) |
   | `camera_zoom_in`, `camera_zoom_out` | press / wheel | optional zoom within limits (Camera) |
   | `radio` | hold-to-confirm | VS: call extraction / tap out (Tap-out & Run Results) |
   | `diary_camera` | press | VS: start the self-filmed diary (Diary) |
   | `ui_*` | press | Godot's built-in UI navigation (`ui_accept`, `ui_cancel`, `ui_up` …) used by every screen |

3. **Default bindings:**

   | Action | Keyboard / mouse | Gamepad |
   |---|---|---|
   | move | W A S D | left stick (and D-pad) |
   | `move_hurry` | Left Shift | left stick click (L3) |
   | `interact` | E | A / Cross |
   | `secondary` | F | X / Square |
   | `cancel_action` | C · right mouse button | B / Circle |
   | `backpack` | Tab | Y / Triangle |
   | `pause_menu` | Esc | Start / Options |
   | `camera_turn_left` / `right` | Q / R | LB / RB |
   | `camera_zoom_in` / `out` | mouse wheel | right stick up / down |
   | `radio` (VS) | hold T | hold Back / Share |
   | `diary_camera` (VS) | N | right stick click (R3) |

   Mouse movement is not used in gameplay (the camera is fixed-angle and high); the mouse is used in menus and for zoom.
4. **Contexts.** Exactly one is active:
   - **Gameplay** — movement, interact, secondary, cancel, backpack, pause, camera, radio, diary.
   - **UI** — when any screen is open (backpack, pause, diary, results): only `ui_*`, `backpack` (to close), `pause_menu` (to close or back) and `radio` (VS — always reachable, see Rule 7).
   - **Locked** — loading, fades, death/evacuation screens' first 1.0 s: no actions except `pause_menu`.
   Changing context clears held states and buffers, so a key held while a menu opens does not fire on close.
5. **One meaning per key per context.** At load, the binding table is validated: no input event may be bound to two actions in the same context (UI and Gameplay are checked separately; built-in `ui_*` events overlapping gameplay keys are allowed because the contexts never run together). A conflict rejects that binding and logs an error.
6. **Reading presses** (IN2): every press/hold action reports `pressed`, `released`, `held_seconds` (real time) and a classification — **tap** (released before `tap_max_s`) or **hold** (held ≥ `hold_min_s`). Consumers choose which they use; Interaction decides whether a timed action needs E held or just started.
7. **Hold-to-confirm for irreversible choices.** Actions that end the run or destroy something (VS: `radio` tap-out) require holding for `hold_confirm_s` (default 1.5 s real time) with a visible fill; releasing early does nothing. `radio` stays reachable in the UI context and in Body Temperature's Critical stage — tapping out is never blocked by input routing.
8. **Buffer.** A press of `interact`, `secondary` or `cancel_action` made while the consumer cannot accept it (an action is finishing) is kept for `buffer_s` (default 0.15 s) and delivered when it can, then dropped (IN3).
9. **Active device and glyphs.** The most recent meaningful input (a key, a button, or a stick past the deadzone) sets `active_device` to `keyboard_mouse` or `gamepad`; HUD prompts and screens show matching glyphs. Device identity is read from the event *type*, never from `device == 0` (Godot 4.7 change).
10. **Disconnects.** If the active gamepad disconnects during Gameplay, the game pauses and shows a reconnect prompt; keyboard input still works.
11. **Remapping.** All bindings are data and remappable per action (accessibility floor). The MVP ships the defaults; the remap screen arrives with Save/Load & Settings (Alpha). Remaps are validated by Rule 5.
12. **Real time, not game time.** All input timings are real seconds and are not affected by Time & Day Cycle's rate modes or pause.

### States and Transitions

| Machine | States | Transitions |
|---|---|---|
| Context | Gameplay · UI · Locked | Gameplay → UI when a screen opens; UI → Gameplay when the last screen closes; any → Locked on load/fade/death screen; Locked → previous after it ends. Each change clears holds and buffers. |
| Press (per action) | idle · down (< `tap_max_s`) · held (≥ `hold_min_s`) · confirming (hold-to-confirm only) · confirmed | idle → down on press; down → idle on release = **tap**; down → held at `hold_min_s`; held → idle on release = **hold ended**; confirming → confirmed at `hold_confirm_s`; confirming → idle on early release (nothing happens) |
| Active device | keyboard_mouse · gamepad | switches on the first meaningful input from the other device |

### Interactions with Other Systems

| System | Direction | Data | Interface owner |
|---|---|---|---|
| Character Controller & Animation | out | `move_vector` (IN1, magnitude 0–1), `move_hurry` held | Input |
| Interaction & Timed Actions | out | `interact`, `secondary`, `cancel_action` with tap/hold classification and `held_seconds`; buffered presses | Input |
| Camera | out | turn and zoom presses | Input |
| HUD / Screens & Menus | in/out | out: `active_device` for glyphs, `ui_*`; in: screen open/close changes the context | Input / UI |
| Tap-out & Run Results (VS) | out | `radio` confirm progress and `confirmed` | Input |
| Self-Filmed Diary (VS) | out | `diary_camera` | Input |
| Body Temperature (approved) | — | no link: Critical restricts *actions* in Interaction; input routing never blocks `radio` | — |
| Save/Load & Settings (Alpha) | in/out | remapped bindings | Settings |
| Localization, Accessibility & Onboarding | out | remapping, glyph sets, prompt text keys | Input |

Implementation note → becomes an ADR: whether contexts are implemented by a single input router node or by per-screen `_unhandled_input` handling.

## Formulas

**IN1 — Move vector with radial deadzone.** The `move_vector` formula is defined as:

`raw = (right − left, back − forward)`; `m = |raw|`; `move_vector = m < dz ? (0, 0) : raw / m × min(1, (m − dz) / (1 − dz))`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| raw | Vector2 | each axis −1–1 | calculated | from the four move actions (keys give 0/1; sticks give analog) |
| m | float | 0–1.414 | calculated | raw length (keyboard diagonals are 1.414) |
| dz | float | 0.05–0.4 | data file | stick deadzone (default 0.2); must be < 1 |

**Output Range:** length 0–1; keyboard diagonals are normalised to 1. **Examples:** stick at 0.15 → **0**; stick at 0.6 → length **0.5**; W + D → (0.707, −0.707), length **1.0**.

**IN2 — Press classification.** The `press_class` rule is defined as:

`tap` if released with `held_seconds < tap_max_s`; `hold` once `held_seconds ≥ hold_min_s`; `confirm_progress = clamp(held_seconds / hold_confirm_s, 0, 1)`, confirmed at 1

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| tap_max_s | float | 0.1–0.5 | data file | default 0.25 s |
| hold_min_s | float | 0.2–1.0 | data file | default 0.35 s; must be ≥ tap_max_s |
| hold_confirm_s | float | 0.5–3.0 | data file | default 1.5 s |
| held_seconds | float | 0–∞ | calculated | real seconds since press |

A press released between `tap_max_s` and `hold_min_s` (0.25–0.35 s) is neither a tap nor a hold and is ignored — the gap prevents a slow tap from starting a hold action by accident, and a short hold from firing a tap action.

**Output Range:** tap · hold · none; progress 0–1. **Example:** E released after 0.2 s → **tap**; E held 0.5 s → **hold** (from 0.35 s on); `radio` held 0.9 s → progress **0.6**, released → nothing.

**IN3 — Buffer.** The `buffered_press` rule is defined as:

deliver a buffered press if the consumer becomes ready within `buffer_s` real seconds of the press; otherwise drop it. One buffered press per action; a newer press replaces an older one.

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| buffer_s | float | 0–0.3 | data file | default 0.15 s |

**Output Range:** delivered or dropped. **Example:** E pressed 0.1 s before the current chop ends → delivered at the end; pressed 0.2 s before → dropped.

*systems-designer lens applied (Section D, high-risk in Lean mode): every variable at min, max and 0. Findings folded in: `dz = 1` → division by zero (IN1) — rejected at load (< 1); `hold_min_s < tap_max_s` would let one press be both tap and hold — rejected; `buffer_s = 0` is valid (buffering off). No feedback loops.*

## Edge Cases

- **If keyboard and gamepad move at the same time**: use the larger-magnitude vector; `active_device` follows the newer meaningful input.
- **If a stick drifts below the deadzone**: no movement and no device switch.
- **If a screen opens while E is held**: the hold is cleared; closing the screen does not fire E.
- **If the active gamepad disconnects during gameplay**: pause and show the reconnect prompt; reconnecting does not auto-resume (the player unpauses).
- **If a gamepad disconnects while the keyboard is the active device**: nothing happens.
- **If two actions share a key in the same context** (bad data or a remap): reject the newer binding, keep the old, log an error; the remap screen (Alpha) shows the conflict.
- **If `radio` is released at 99 % progress**: nothing happens; the fill drains back.
- **If the game is paused during a hold**: the hold is cleared (context changes to UI).
- **If a Time sleep skip is running**: input still works in real time; `cancel_action` or any interrupt is handled by Interaction/Needs.
- **If a press arrives during Locked**: dropped (only `pause_menu` is live).
- **If two buffered presses of different actions arrive**: each action keeps its own buffer; consumers decide priority.
- **If input focus differs between mouse and gamepad in menus** (Godot 4.6 dual focus): keyboard/gamepad focus drives `ui_*`; mouse hover never moves gamepad focus.

## Dependencies

**Upstream — hard:** none (Foundation).

**Upstream — soft:** Screens & Menus / HUD (open/close events that change the context), Save/Load & Settings (Alpha, remaps).

**Downstream:** Character Controller & Animation (hard: `move_vector`), Interaction & Timed Actions (hard: `interact`, `secondary`, `cancel_action`), Camera, HUD, Screens & Menus, Tap-out & Run Results (VS), Self-Filmed Diary (VS), Localization/Accessibility/Onboarding.

**Bidirectional check:** the systems index lists Input with no dependencies (matches) and lists Character Controller and Interaction as depending on it (matches). Camera's index row does not list Input (it reads turn/zoom actions) — soft; fix when Camera is designed. No existing GDD references Input yet.

## Visual/Audio Requirements

Optional for a Core system; brief notes:
- **Prompts** use the art bible's paper-and-ink UI style (§4): hand-drawn key/button glyphs for the active device, shown near the target in world space only when an action is available.
- **Hold-to-confirm** shows a hand-drawn ring filling around the glyph; a soft radio crackle rises with progress (VS).
- No input sound effects beyond UI confirm/cancel clicks.

## Game Feel

- **Controls disappear.** In a five-minute session the player should need only WASD, E and occasionally F, Tab and Esc.
- **Responsive starts.** A move press must start the walk animation within one rendered frame of being read (≤ 16.6 ms at the 60 fps target); the *heaviness* is the Character Controller's acceleration, never input lag.
- **No accidents.** Nothing irreversible happens on a tap; the run never ends from a mis-press.
- **Analog is honoured.** A half-pushed stick walks slowly through deep snow; the keyboard always gives full intent.

## UI Requirements

- **Context prompts:** glyph + short verb near the target when an action is available, matching `active_device`.
- **Hold-to-confirm ring** for `radio` (VS).
- **Reconnect prompt** on gamepad disconnect.
- **Remap screen (Alpha):** per action, keyboard and gamepad columns, conflict warnings; part of Settings.
- **Debug overlay (dev only):** active context, active device, raw and processed move vector, held actions with timers, buffered presses.

> **📌 UX Flag — Input & Action Map**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for each screen or HUD element this system contributes to **before** writing epics. Stories that reference UI should cite `design/ux/[screen].md`, not the GDD directly.

## Cross-References

| This GDD references | Target (GDD) | What | Status |
|---|---|---|---|
| Rule 7 | Body Temperature (`design/gdd/body-temperature.md`) | tap-out never blocked in Critical | approved — consistent |
| Rules 2, 6, 8 | Interaction & Timed Actions (`design/gdd/interaction-and-timed-actions.md`) | meaning of interact/secondary/cancel, tap vs hold use | approved — consistent |
| Rules 2, IN1 | Character Controller & Animation (`design/gdd/character-controller-and-animation.md`) | move vector, `move_hurry` | approved — consistent |
| Rule 2 | Camera (`design/gdd/camera.md`) | turn and zoom | approved — consistent |
| Rules 2, 7 | Tap-out & Run Results (`design/gdd/tap-out-and-run-results.md`) | `radio` hold-to-confirm | VS |
| Rule 9, 4.7 note | `docs/engine-reference/godot/modules/input.md` | device IDs, dual focus, VirtualJoystick for later touch | exists |
| Overview | `design/game-brief.md` Controls | default scheme | exists |
| Overview | `prototypes/firebeforedark-concept/README.md` | R-key conflict lesson | exists |

## Acceptance Criteria

*qa-lead lens applied (Section H, high-risk in Lean mode).* **[A]** automated logic test · **[P]** playtest / evidence.

**Core rules**
1. [A] **GIVEN** the project's code, **WHEN** searched, **THEN** no gameplay or UI script reads raw keycodes, joypad buttons or axes outside the input layer (static check).
2. [A] **GIVEN** the default binding table, **WHEN** validated, **THEN** no event is bound to two actions in the same context.
3. [A] **GIVEN** a remap of F to `camera_turn_left` while F is `secondary`, **THEN** the remap is rejected and an error logged.
4. [A] **GIVEN** the backpack is open, **WHEN** E or W is pressed, **THEN** no `interact` or movement is delivered to gameplay; **WHEN** the backpack closes with E still held, **THEN** E does not fire.
5. [A] **GIVEN** the Locked context, **WHEN** E is pressed, **THEN** it is dropped; `pause_menu` still works.
6. [A] **GIVEN** a gamepad input after keyboard use, **THEN** `active_device` = gamepad; a stick move of 0.1 does not switch it.
7. [A] **GIVEN** the active gamepad disconnects in gameplay, **THEN** the game pauses and shows the reconnect prompt.
8. [A] **GIVEN** time is paused or in sleep mode, **THEN** IN2/IN3 timings measured in real seconds are unchanged.

**States**
9. [A] **GIVEN** a screen opens during a `radio` hold at progress 0.5, **THEN** the hold is cleared and no tap-out happens.

**Formulas**
10. [A] IN1: stick 0.15 → (0, 0); stick (0.6, 0) → length 0.5 ± 0.001; W + D → length 1.0 ± 0.001; data with dz = 1 is rejected.
11. [A] IN2: release at 0.2 s → tap; held 0.5 s → hold reported at 0.35 s; release at 0.3 s → neither tap nor hold (ignored); `radio` released at 1.4 s → nothing; held 1.5 s → confirmed.
12. [A] IN3: E 0.1 s before the consumer is ready → delivered once; 0.2 s before → dropped; two E presses inside the window → one delivery.

**Cross-system & feel**
13. [A] **GIVEN** Body Temperature Critical, **WHEN** `radio` (VS) is held 1.5 s, **THEN** Tap-out receives `confirmed` (input routing does not block it).
14. [P] **GIVEN** a first-time tester with a gamepad and one with keyboard, **WHEN** they play 5 minutes of the MVP with no instructions beyond prompts, **THEN** both can move, gather and light a fire, and neither triggers an unintended action.
15. [P] **GIVEN** a frame capture, **WHEN** W is pressed, **THEN** the walk starts on the next rendered frame (≤ 16.6 ms).

**Performance:** input processing ≤ 0.05 ms per frame.

*QA gaps found and resolved: context hold-clearing (4, 9), drift vs device switch (6), real-time vs game-time (8), tap/hold gap (11), buffer de-duplication (12). Feel lines moved to playtest criteria 14–15.*

## Open Questions

| Question | Owner | Resolve by | How |
|---|---|---|---|
| ~~Does `move_hurry` exist at all in deep snow (heavy-effort feel), or only on packed trails?~~ **Resolved 2026-11-17**: exists — a lunge ×1.3 costing heavy work, blocked when hauling, Exhausted or Hypothermic+ (Character Rule 5) | game-designer | Character Controller GDD | decided by Character |
| ~~Does Camera allow free turning (Q/R) and zoom, or a fixed angle with small adjustments?~~ **Resolved 2026-11-17**: 45° turn steps (0.4 s, hold repeats), zoom 14–40 m in 3 m steps (Camera Rules 3–4) | game-designer | Camera GDD | decided by Camera |
| ~~Should timed actions need E held throughout (more physical) or start on tap (more relaxed)?~~ **Resolved 2026-11-17**: tap to start; repeat-mode actions take one tap per attempt (Interaction bidirectional check) | owner + game-designer | Interaction GDD | decided by Interaction |
| Mobile (later): touch layout with Godot 4.7's VirtualJoystick and an on-screen context button. | ux-designer | after the PC release | actions already abstract the device |
| Gamepad rumble for cold/shivering and failed strikes? | ux-designer | Emotional Feedback GDD | SDL3 rumble support exists (engine reference) |
