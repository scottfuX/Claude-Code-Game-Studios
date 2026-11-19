# ADR-0016: Non-numeric HUD and MVP inventory facade contracts

## Status
Accepted

Accepted by Scott (owner) on 2026-11-19: “Accept all 16” (ADR-0001–ADR-0016). Acceptance records the architecture decision, not runtime verification or resolution of open QQ items.

## Date
2026-11-18

## Last Verified
2026-11-18 — GDD/registry/engine-reference audit only; HUD not rendered or visually verified.

## Decision Makers
Scott (owner, QQ-08 already resolved), Devin (author/inline godot-specialist reviewer); Owner acceptance: Scott, 2026-11-19. No independent review approval is claimed.

## Summary
The HUD must communicate warmth, needs and available actions without numbers or UI leaking gameplay input. Propose a read-only SurvivalHud snapshot renderer and minimal Inventory command facade, with device glyph/context ownership in InputRouter, final Camera projection and backpack UI explicitly independent of pause.

## Engine Compatibility
| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2.stable.official.ed1daf0bf / GDScript / Jolt |
| **Domain** | UI / Input / Rendering |
| **Layer** | Presentation |
| **Knowledge Risk** | MEDIUM UI/input post-cutoff; HIGH global pin |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `modules/ui.md`, `modules/input.md`, `modules/rendering.md`, `breaking-changes.md`, `deprecated-apis.md`, `current-best-practices.md` |
| **Post-Cutoff APIs Used** | 4.6 mouse/touch focus separate from keyboard/gamepad; 4.7 stretch defaults are not retroactive and accessibility_live is typed. Use updated RichTextLabel image units if glyph adapter needs images. |
| **Verification Required** | Dual-focus/input leak, glyph lookup, actual project stretch/projection mapping, locale text sizing, keyboard/gamepad reconnect and UI rendering on pin |

## ADR Dependencies
| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001, ADR-0002, ADR-0003, ADR-0007, ADR-0008, ADR-0009, ADR-0011, ADR-0013, ADR-0014, ADR-0015 (all Accepted; acceptance required) |
| **Enables** | None within this allocated backlog; deferred full inventory/settings/screens remain unallocated scope |
| **Blocks** | SurvivalHud and MVP inventory facade implementation; no story files exist |
| **Ordering Note** | UI sends commands to existing owners and requests contexts, never edits gameplay state or constructs another pause clock. |

## Context
### Problem Statement
HUD prompts must reflect the latest target and input device, remain legible at720p and not turn the backpack into an accidental pause/command bypass.
### Constraints
- Registry: InputRouter owns raw events/context/pause tokens; C4 owns action admission; Inventory/Needs own transactions; Camera owns final projection. Detached snapshots only.
- No morale/Resolve display, numeric temperature/hunger/mass/day/time/count labels, thermometer/minimap/markers/damage numbers. Developer debug surfaces stay separate and disabled in release.
- QQ-09 scale/settings/full-inventory scope and QQ-01 budgets remain owner-only; MVP100% scale, not a new settings menu. QQ-08 backpack behavior is resolved, not proposed.
### Requirements
- Backlog coverage (verbatim): All HUD TRs; glyphs/context, icon/band/arc hierarchy, safe-area/projection and decided QQ-08 semantics: backpack/inventory keeps time/actions running; pause menu pauses all
- Preserve H1–H5, all visibility/edge/localization requirements and AC1–11/performance.

## Decision
SurvivalHud owns presentation state only: body band/trend, at most3 need icons, sun/moon arc, localized prompts/refusal/hint, calm fade and minimal backpack list facade. Use one run-owned CanvasLayer/Control tree with a validated Theme and localized keys, no gameplay queries from draw callbacks. Render a complete detached end-of-update snapshot; cache only derived visuals, never duplicate food/load/stage authority. Missing target/verbs clears old prompts immediately. InputRouter active_device/glyph bindings choose labels, never hard-coded E/F when rebound/gamepad active.

H1 fill=clamp((core−30)/7,0,1), no printed values, snowflake/flame icons plus fill direction/ticks preserve colourblind readability. H2 thresholds±0.1 single/±1double, arrow candidate must persist2unpaused real seconds before replacement; steady hides it. H3 calm=Warm/no trend/no need warning/no prompt, after8real seconds targetalpha0.35 eased down1.5s; any warning/trend/stage/prompt raises1 within0.5s. H4 energy/water/food first-warning icon normal ink, urgent bold+pulse1Hz/10% scale; one per need, max3. H5 angle180×sun_progress by Dawn/Day/Dusk, otherwise normalized minutes since nightfall/night length; no hour/day numerals. Invalid snapshot logs/holds last valid band/arc rather than displaying NaN; absent optional warning is hidden.

Visibility precedence: end hides all; sleep/ritual hides all except body band0.35; ordinary Critical forces band1 and keeps applicable needs/prompts (only owner-approved verbs), else calm rules. This makes contextual hide explicit rather than competing fades; verify conflict cases before acceptance. Ritual ends restore0.5s. First-minute localized hint disappears on first Kindling flame OR after10game minutes, latches gone until new run; save/settings restore remains deferred. Refusals newest replaces previous for1.5real seconds; no queue. Reconnect overlay uses InputRouter recovery path, not a new gameplay pause authority.

Use final Camera.project_world output, reject behind-camera/invisible points, map viewport coordinates through CanvasLayer/stretch once. Keep prompts40px clear of actual projected survivor silhouette; clamp to safe rectangle without overlapping survivor or inventing offscreen markers. At720p text≥18px, anchors5% safe area; ultrawide uses centred16:9 safe rectangle before5% inset. Long localization text wraps/reflows; missing key dev shows key/release empty+log. Paper/off-white/ink strokes remain UI, not low-poly world meshes. MVP scale100%; reserve80–140% Alpha hook without adding settings controls.4.7 line rendering lost antialias feather, so thin band/arc strokes require actual screenshot verification, not assuming old widths.

Backpack open requests InputRouter UI context ONLY. It does not request pause, stop Clock, cancel active action or freeze physiology/Fire/Morale. Existing in-flight action continues, even if it completes/death occurs behind the list; continuously refresh inventory from owner snapshots so stale rows cannot become commands. Buttons send action/transfer requests with stable stack ID/revision to C4/C6; running hands/action/critical/tool constraints still apply. Unknown/deleted row fails/reloads harmlessly, never directly mutates stack/count/Needs. Minimal list shows localized item identity and qualitative wetness/load bands, no numbers; no drag-grid, nested crafting, full settings or scope addition. Use/drop/eat routes through existing owner resolver, never calls engine Input gameplay handlers directly.

Explicit pause menu acquires an F2 pause token; world Clock/action timers freeze until all pause tokens released. If backpack stays open behind pause, closing pause returns to UI context, not Gameplay. Closing backpack releases only its UI request; rearm gameplay bindings after release per F2 so Tab/confirm doesn't leak a use/step. Noninteractive HUD nodes ignore input/focus; keyboard/gamepad focus for active list restored explicitly while mouse hover remains independent. Disconnect safety retains InputRouter gate/reconnect instructions; next keyboard action updates glyphs. Terminal closes/disables command facade and uses C4's single end snapshot, never accepts new stale commands.

### Architecture Diagram
`Body/Needs/Time/Action/Inventory snapshots + Input glyphs + final Camera projection → SurvivalHud`; `backpack → UI context`; `pause menu → pause token`; `list commands → C4/C6 owners`.
### Key Interfaces
- Preserve `render_snapshot(snapshot)` and `set_visibility_context(context)` from architecture; facade issues typed owner commands, not mutable Inventory views.
- Use F2 `request_ui_context(source,open)` / `request_pause(source)` / `release_pause(token)`, C13 `project_world` and C4/C6 token/stack IDs. These are application ports, not native Godot APIs.
- Hold progress/radio ring remains VS hook, not a new MVP extraction mechanic. UI paper/ink Audio requests have no simulation effects.
### Implementation Guidelines
- UI must be read-only to models and non-numeric; prompt/glyph/target must reflect current owner snapshot, no stale actionable affordance.
- Backpack must not pause/cancel time/actions; pause menu must pause through token ownership, not SceneTree mutations. Closing overlays must not leak Gameplay input.
- Text≥18px at720p,5% safe area,40px survivor clearance and at most3icons must survive aspect/locale changes.

## Alternatives Considered
### Alternative 1: Full-screen UI automatically pauses SceneTree
- **Pros**: Conventional menu implementation. **Cons**: Contradicts QQ-08/updated Time Rule8 and in-flight action behavior.
- **Rejection Reason**: Context and pause are independent authoritative F2 requests.
### Alternative 2: Bind numeric Inventory/model fields directly to widgets
- **Pros**: Quick inspector-style UI. **Cons**: Mutable aliases/bypass owner transactions, forbidden numbers and stale targets.
- **Rejection Reason**: GDD requires non-numeric read-only facade and owner commands.

## Consequences
### Positive
- Minimal readable HUD preserves diegetic uncertainty and input/pause ownership; facade reuses atomic commands.
### Negative
- Aspect/locale/dual-focus and nested contexts need visual/device evidence; numeric debug widgets cannot be reused in release HUD.

## Risks
- Inline godot-specialist review: CanvasLayer/Control/Theme/tr and final projection adapter fit references;4.6 dual focus and4.7 stretch/line changes must be tested. Avoid obsolete RichTextLabel *_in_percent arguments; typed accessibility_live if used. No UI rendered, no device test. TD-ADR skipped — Lean mode; no independent approval.
- GDD sync checked HUD/Input/Time/Interaction/Inventory/Camera/Feedback/Body/Needs/Fire (10): names and non-numeric hierarchy align; checked updated Time Rule8 consistent with resolved QQ-08, no pending pause correction. Visibility precedence above is explicit proposal for combined sleep/Critical fixtures, not GDD editing. No GDD edit.
- Autonomous calls: Proceed assumptions/dependencies/full range; separate tabs snapshot UI, glyph/projection layout, minimal command facade and orthogonal UI/pause; ADR-only write, append registry, stop after requested backlog. QQ-08 supplied by owner, not auto-taken. No HUD/settings expansion approved.

## GDD Requirements Addressed
| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [hud.md](../../design/gdd/hud.md) | Full provisional TR-hud-001 … TR-hud-024; all rules/H1–H5/states/edges/dependencies and AC1–11/performance | Snapshot band/trend/icons/arc, no numbers, localized glyphs/prompts/hint, safe layout/visibility, read-only Inventory facade and resolved backpack/nonpause versus explicit pause. |

## Performance Implications
- **CPU/GPU**: GDD HUD draw≤0.3ms/frame; benchmark layout/projection/localization updates separately, not claimed measured.
- **Memory**: Reused3icons/fixed controls and current list snapshot; remove stale rows on owner revision, no event/refusal backlog.
- **Load Time**: Validate theme/glyph/localization refs and actual stretch settings; missing keys follow dev/release behavior, never invent gameplay text values.
- **Network**: None.

## Migration Plan
After acceptance implement pure H math/context fixtures, then owner-command facade and one720p/wide/locale visual scene with keyboard/gamepad recovery. Do not edit settings/GDD/prototypes now or implement full screen inventory/Alpha scale controls without QQ-09.

## Validation Criteria
- AC1–6: release tree no numbers/morale/clock;core37/35.5/32/29→1/0.786±0.005/0.286/0;rates−0.81/−1.49/+1.6/+0.05→single/double/double/none with2s guard;calm8s→0.35/trend→1within0.5s;Tiredwarn/Exhaustedurgent/Restedhidden,max3;day12:30arc90°,nightfallmoon0°.
- AC7–9:firstfireKindling removes hint permanently or10min timeout;ritual/sleep band0.35 only;greyscale Cold/Warm distinguished byfill/icons. Simultaneous Critical/sleep/end verifies explicit context priority;owner-approved critical verbs only and newest refusal1.5s.
- Empty target/list clears verbs/rows;missing key dev/release/log behavior;invalid snapshot no NaN;long locales/ultrawide/720p maintain18px/5%/40px;behind-camera target no marker;active device glyph switch and separate mouse/key focus;disconnect gate/recovery and no ghostconfirm;stale stack command refused without mutation.
- Open backpack mid-chop/across minute keeps progress/ticks, no movement/action leak;pause over backpack freezes both, close pause remains UI until backpack closes;second pause token keeps pause;action/death while UI open refreshes/disables rows, no stale command. No whole-tree pause or UI-owned inventory writes.
- AC10–11 unperformed visual/owner evidence:10min testers recall warmth/little else,first-minute hint/prompts understood. Draw≤0.3ms and screenshot720p/ultrawide/greyscale/longlocale required; visually/runtime/performance unverified.

## Related
- [Architecture](architecture.md), P4; [ADR-0002](adr-0002-input-routing-contexts-and-ui-pause-requests.md), [ADR-0009](adr-0009-item-action-data-validation-inventory-transfers-and-tool-use-transactions.md), [ADR-0013](adr-0013-camera-framing-arbitration-collision-and-projection-ports.md).
- QQ-01 budgets/hardware, QQ-09 hide-when-calm/day-title/full-inventory/settings scope and QQ-10 deferred screens remain owner-only. `/architecture-decision accept ADR-0016` separate; fresh-session `/architecture-review` required, no story unblocked.
