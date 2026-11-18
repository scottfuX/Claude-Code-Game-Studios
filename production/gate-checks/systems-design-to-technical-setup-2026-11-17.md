# Gate Check: Systems Design → Technical Setup

- **Date:** 2026-11-17
- **Verdict:** FAIL (1 blocker, 3 concerns)
- **Config:** workflow standard · review lean · qa.level standard · team individual
- **Stage written:** none (project.stage stays unset)
- **Directors:** not run — the verdict is decided by an artifact blocker; they run on the next attempt

## Checklist

| Check | Status |
|---|---|
| Systems index exists with MVP systems | PASS — 33 systems, 18 MVP |
| All MVP GDDs exist | PASS — 18/18 |
| All MVP GDDs pass `/design-review` | **FAIL** — 16/18 approved; `morale-and-mental-state.md` and `input-and-action-map.md` were NEEDS REVISION, revised, awaiting re-review |
| 5 standard sections (+ conditional Formulas) | PASS — all 18 |
| Cross-GDD review report (`/review-all-gdds`) | CONCERNS — absent (recommended at standard) |
| Dependencies bidirectionally consistent | CONCERNS — soft inputs missing from index rows: Camera→Input, Mishaps→Terrain/Thermal, Thermal/Camera/Character/Fire→Map |
| MVP priority tier defined | PASS |
| No stale GDD references | CONCERNS — Character C8 missing cos(pitch); Character In-water tagged VS (ice is MVP); Needs `needs_move_speed_mult` rename; Item DB `feather_stick`; Interaction + Map adopt `gather_grass` / `gather_stones`; Thermal zone table add drift field + scoured ridge |

## To pass

1. Re-review in fresh sessions: `/design-review design/gdd/morale-and-mental-state.md`, `/design-review design/gdd/input-and-action-map.md`.
2. Recommended: `/review-all-gdds`.
3. Optional: fold in the stale-reference follow-ups and add the missing soft dependencies to the systems index.
4. Re-run `/gate-check`.
