# Save/Load — Run Checkpoint Slice

> **Status**: Designed — ADR-0018 Accepted
> **Author**: Scott (direction) + Devin (autonomous drafting)
> **Last Updated**: 2026-11-20
> **Last Verified**: 2026-11-20 — document/code survey only; not runtime verified
> **Decision label**: Default (reversible; accepted under Scott delegation via ADR-0018). This label applies to every rule, table row, formula, copy fixture and acceptance target below; ADR acceptance is recorded in ADR-0018, not evidence of runtime verification.
> **Implements Pillar**: Know More Each Run

## Summary
Keep one recoverable, nonterminal run checkpoint so the player can leave deliberately. This owner-requested MVP slice pulls run persistence forward from Alpha; settings, profiles, manual slots and cloud sync remain out of scope.

> **Quick reference** — Layer: Foundation · Priority: MVP slice of Alpha system #28 · Key deps: Time, Body, Needs, Inventory, Fire, Gathering, survivor and every enabled stateful owner

## Overview
The shell owns SaveStore; gameplay owners export detached versioned values at a stopped transaction boundary. Continue validates and builds a fresh run using those values, never serializing nodes or Resources.

## Player Fantasy
Leaving the game does not erase a night I have not yet lost.

## Detailed Design

### Core Rules
1. **TR-save-load-001:** One slot: `user://saves/run_checkpoint.json`. Envelope fields: `schema_version` (integer 1), `profile` (first_night/three_night), `seed` (integer), `saved_at_unix` (nonnegative Unix seconds), `owners` (DTO map). Encode full-width seed/RNG integers as decimal strings where JSON precision would otherwise lose bits; validated DTO restores typed integers.
2. **TR-save-load-002:** Save at each sunrise after the ordered survival/terminal check, only if nonterminal; also on Save & Return to Title and confirmed Quit from live pause. No per-frame or timed-action snapshot, no action progress restoration.
3. A quiescent boundary has no minute dispatch, prepared owner commit or in-flight timed action. Manual save cancels admitted work with no reward/RNG use, retaining already-committed target progress; sunrise save queues until active work resolves/cancels, then rechecks terminal and captures current state (not a retroactive sunrise). Pending autosave does not freeze play. Terminal cancels any pending save.
4. **TR-save-load-003:** Write validated UTF-8 JSON to a temporary sibling file, flush/close and replace by same-directory atomic rename. Never remove the old slot before replacement; write/rename failure keeps prior valid slot and reports error. Ignore orphan temp files at boot. Platform replacement semantics must be verified; unsupported atomic overwrite fails safely rather than delete-then-rename.
5. **TR-save-load-004:** Before mounting, validate every required envelope/DTO field, exact types, finite numbers, enum IDs, profile compatibility, bounds, unique stable IDs and cross-owner relationships using owner rules. Unknown schema or unknown owner/key is rejected in v1, not guessed/migrated. Validate in isolated staged owners, then publish complete initial snapshot; no partially restored active run.
6. Invalid/unreadable save is ignored, Continue hidden, and file renamed to `.corrupt` (unique suffix if needed); quarantine failure leaves Continue hidden and shows warning, never overwrites evidence automatically. Missing file is a normal empty state. Valid load whose scene/bootstrap fails preserves save and offers retry.
7. **TR-save-load-005:** Death or victory invalidates slot and deletes checkpoint before results navigation. A deletion failure blocks retry/title/quit behind Retry and explains failure; never advertise Continue or silently close with a resumable dead run. OS kill/crash during failed deletion cannot be made one-life-safe without durable invalidation; strict anti-rollback/anti-cheat is out of scope.
8. **TR-save-load-006:** Continue restores with gameplay/action time paused, pause menu closed and input Locked during a one-second fade-in. “Paused” here is a loading-gate token, not an open explicit pause menu. On completion release only that token and resume play unless disconnect/another pause remains.
9. **TR-save-load-007:** Enabled owners register stable DTO key/version, exporter, pure validator and restore dependency order. Existing profile owners needed for continuity must register before Continue is enabled. Later optional owners either register or explicitly declare reset-to-authored-default behavior; no silent omission. Profile/schema changes must reject incompatible checkpoints until migration is designed.

### States and Transitions
| State | Event | Next |
|---|---|---|
| Unknown slot | BOOT probe | Absent / Valid / Invalid quarantined |
| Live run | Save request | Pending quiescence → Export → Atomic replace |
| Save pending | Terminal | Cancel export/write admission, invalidate slot |
| Valid slot | Continue | Validate/stage → fresh mount → Locked fade → playing |
| Read/write/restore error | Failure | Retain title or paused run, localized Retry/Cancel |
| Terminal | Delete failure | Terminal cleanup error, Retry only |

### Interactions with Other Systems
| Owner key | Required values / restore constraint |
|---|---|
| clock | day, minute, fractional accumulator, rate_mode; no tick replay |
| body | core temperature, wetness, stage; validate derived stage consistency |
| needs | all authoritative fields, stage/grace/starving/dehydration timers, sleep/collapse state |
| inventory | tools, stacks/counts/conditions, stable IDs and revisions; no authored definitions |
| fires | stable site IDs/positions, stage, fuel, burning wetness, ember timer, ring/target progress |
| gathering | stable node IDs, depletion and committed target progress |
| survivor | finite valid world position and facing; locomotion/action restores Free |
| rng | full stream state/draw position as well as envelope seed; never replay draws |
Current first-night/chapter inventory includes tools, not just carried fuel. Rebuild thermal registrations from restored fire/other source owners before first sample. Needs asleep state may restore physiological sleep; Free means no timed action, not forcibly waking a sleeping survivor.

### Extension and explicit resets
Snow footprints/trail marks and transient audio/feedback reset to defaults. This is a deliberate exception to Terrain's exact-mark restore contract, accepted under ADR-0018; do not claim full Terrain GDD compliance. Physical cell depths/compaction/broken ice require Terrain DTO when enabled, not trail-visual replay. Shelter/snare/food-site progression must register if enabled in the selected profile, or profile validation refuses Continue; resetting finite-resource progression would duplicate resources and is not an acceptable optional reset. UI focus, pause tokens, queued input/events and action attempts are never restored. Loading/safety tokens are fresh.

## Formulas
Schema version = 1. Slot count = 1. Restore fade = 1 real second gated by loading ownership; gameplay delta remains zero. Timestamp is metadata, never offline survival progression. Export preserves RNG stream state in addition to seed for deterministic continuation.

## Edge Cases
Disk-full/permission/rename failure preserves prior checkpoint; manual save failure retains paused run with Retry/Cancel, autosave failure uses a nonmodal warning and retries only on a later request. Concurrent save/terminal is serialized on the coordinator boundary; terminal wins before commit. Restore duplicate IDs, invalid profile, NaN/out-of-map position or inconsistent totals fails as a unit. Missing required owner is corruption; no partial “best effort” survival state. Starting a new profile confirms discard and only invalidates old checkpoint after successful mount.

## Dependencies
ADR-0001 lifecycle/DTOs, ADR-0002 gates, ADR-0003 ordered minutes/RNG, ADR-0007 action/terminal precedence, ADR-0008 physiology; [ADR-0018](../../docs/architecture/adr-0018-shell-navigation-end-shot-and-run-checkpoint.md) Accepted. Owner DTO ports require implementation verification.

## Tuning Knobs
One slot, sunrise cadence, one-second fade and schema v1 are Default (reversible; accepted under Scott delegation via ADR-0018); no player settings added.

## Visual/Audio Requirements
Localized Saving/Save failed/Checkpoint unavailable statuses, no fabricated successful toast. Fade conceals staged restoration; do not replay old action sounds or end-shot feedback.

## Game Feel
Continue is honest and predictable, not an escape from committed death. No offline drains or silent loss of the previous valid checkpoint.

## UI Requirements
Title advertises Continue only after validation. Paused manual save stays pending until result; prevent duplicate navigation. File errors leave readable retry/cancel; terminal deletion failure allows Retry but no unsafe close command.

## Cross-References
[Screens](screens-and-menus.md); [Interaction save edge](interaction-and-timed-actions.md#edge-cases); [Time](time-and-day-cycle.md); [Terrain](terrain-and-snow-surface.md); [Fire](fire.md); [Needs](needs-and-weight.md).

## Acceptance Criteria
- [ ] Round-trip every registered owner for both profiles, including depleted gathering, fire, tools and RNG continuation.
- [ ] Missing slot hides Continue; invalid/malformed/unsupported/partial data quarantines without mounting.
- [ ] Simulated disk-full, overwrite-rename failure, quarantine failure and interrupted temp write preserve safe behavior.
- [ ] Sunrise does not save terminal state; active action defers autosave, manual save cancels without result/use/draw.
- [ ] Terminal beats pending save, deletes slot, and deletion failure blocks unsafe navigation.
- [ ] Continue mounts fresh ownership, no old subscriptions/tokens/actions; one-second Locked fade gates time then resumes safely.
- [ ] Explicit visual resets tested; new required owner without adapter refuses Continue.

## Open Questions
All contracts are Default (reversible; accepted under Scott delegation via ADR-0018). ADR-0018 accepts narrowed Terrain visual persistence, pulled-forward checkpoint scope and the operational deletion-failure policy. Platform atomic replacement and durable flush guarantees need implementation/platform tests; no corruption-proof or crash-proof claim is made.
