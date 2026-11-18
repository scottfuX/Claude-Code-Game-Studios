# Review Log — Item Database & Inventory

## Review — 2026-11-17 — Verdict: APPROVED
Review mode: lean · Workflow: standard
Scope signal: M
Specialists: none (lean)
Blocking items: 0 | Recommended: 4
Summary: Data-first foundation doc lands every cross-system contract verbatim on approved consumers (Needs food fields, Body insulation range, Morale loss event shape). All five formulas verified at boundaries; MVP kit mass (6.9 kg) and the day-3 hunger beat (4,000 + 1,200 kcal vs ~5,400 burn through day 2) recompute exactly. Provisional fields and the sleeping-bag deferral are honestly flagged.
Prior verdict resolved: First review
Findings:
- [RECOMMENDED] I4: `dry_fast`/`dry_slow` share names with Body B2 at different values (0.5/0.05 vs 0.6/0.1) — namespace or mark independent
- [RECOMMENDED] Edge Cases vs Rule 5/table: `winter_clothing` `can_get_wet: yes` contradicts worn-wetness delegation to Body — one garment, two trackers
- [RECOMMENDED] Rule 12: 5 of 16 table rows (pot, tarp, paracord, fishing_kit, snare_wire) unregistered; I5 cites fishing_kit/snare_wire durability
- [RECOMMENDED] Registry: add item-db to `game_minute_tick` and `effective_temp_c` referenced_by
Reviewed-Content-Hash: design/gdd/item-database-and-inventory.md 07a4b58050bdb93e22c5c8feac72fe5ed9bef552
Reviewed-Content-Hash: design/registry/entities.yaml cef308c2a806d9102608706f017c292e744890db
Reviewed-Content-Hash: .claude/skills/design-review/SKILL.md 4dcc8b81162613c757144532f1b72708ab3ba27f
Reviewed-Content-Hash: design/gdd/needs-and-weight.md 4f1252d3d0658bc27e6c910506fbb88a5ea3325b
Reviewed-Content-Hash: design/gdd/body-temperature.md fe502c8c38af6510d749917cf550971ec001c969
Reviewed-Content-Hash: design/gdd/morale-and-mental-state.md 839af1e8afb3c784803cd146bf7890721208a27a
Reviewed-Content-Hash: design/gdd/time-and-day-cycle.md 1532944c4c8849a8c5821554f96eb83245869cac
Reviewed-Content-Hash: design/gdd/thermal-environment.md e562d08a3055b49147f7716aed69e0363452e11d
Reviewed-Content-Hash: design/gdd/systems-index.md 7fb29525cae2e451ea810915511ba084fd617a37
