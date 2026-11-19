# Vertical Slice Report: First Playable Night

> **Date:** 2026-11-19
>
> **Slice Duration:** one recorded work day; effort hours not measured
>
> **Target Scope:** 3–5 minutes of polished, continuous gameplay; built full night is ~16m48s
>
> **Source GDD:** [brief](../../design/game-brief.md), [concept](../../design/gdd/game-concept.md), [milestone](../../production/milestones/first-playable-night.md)

## Validation Question

Can a fresh player, starting from the main scene without guidance, feel loneliness and cold, then relief when their own fire catches, and complete gathering → ignition/tending → dawn? Can this representative loop be produced feasibly at the intended 3–5-minute slice scope? The brief's “感受孤独、寒冷，以及火燃起来那一刻的安心” is the experience test; schedule feasibility needs measured work data, not inferred hours.

## Scope Built

**Location exception:** this is the merged production build in [src/](../../src/), PR #15, evaluated on main b8268dd. This folder holds **only this report**, not prototype code. The template's reference-only / rewrite-production-from-scratch boilerplate does not apply; do not copy or rebuild src/ into prototypes/.

- **Systems included:** run-owned simulation, survivor movement/camera, snowy clearing and gathering, staged fire/fuel/heat, cold and energy-only stamina, dusk/night/dawn, qualitative HUD, pack/pause/restart and run outcomes.
- **Art/audio quality:** representative stylized snow/cold-blue world and warm fire; HUD/shadow readability needs work. Audio/near-shipping polish was not validated.
- **Deliberate limits:** one small area and one night; reduced needs/inventory scope. Debug/demo footage exists from development but is not default-pacing novice evidence.
- **Deferred:** sleep, food and broader multi-day systems. This bounded milestone is not the index's full 18-system MVP or three-day Vertical Slice tier.

## Build Velocity Log

| Day | Recorded work |
|---|---|
| 2026-11-19 | Models/tests → world/adapters → shell/HUD → dusk/demo → review fixes, recorded in [session-log.md](../../production/session-logs/session-log.md). Agent playtesting/reporting occurred the same date. |

**Real git data:** first implementation commit 91a1c7d at 03:47:46Z; last 4370ba2 at 04:19:46Z, a **32-minute commit span**; PR #15 merged as aa2be62 at 04:32:10Z. Initial logical commits followed development already done; this is not 32 minutes of total effort.

**Total elapsed / velocity estimate:** one recorded work day, not a measured elapsed effort duration. No defensible hours-per-scope-unit estimate; no invented hours or extrapolated full-game schedule.

## Playtest Results

See the [analyze-mode playtest report](../../production/qa/playtests/playtest-2026-11-19-devin-agent.md) for method, defects, evidence and routing.

| Attribute | Evidence |
|---|---|
| Runs / testers | 3 runs, 1 returning Devin agent; 0 naive humans |
| Complete loop | Learned Run 2 reached “You saw the dawn”; Run 1 stopped before ignition; Run 3 checked unfed burnout separately |
| Default-pacing scope | main b8268dd, no args; Runs 1–2 no Z wait; pause-assisted ignition; diagnostic F3/code inspection in Run 2 |
| Session length | Average/unpaused duration unmeasured; wall time includes pauses, tool latency and notes |
| First meaningful action | ~24 s after launch including setup/tool overhead; not a clean human discoverability measure |
| External / unguided validation | None; prior knowledge and retries prevent that claim |

## Observations

**Succeeded, but not without prior knowledge/assistance:** gathering and supplies, learned ignition, visible fuel spend, away/near cold trends, dawn result. Separate Z-wait run showed visual burnout and continued cooling.

**Confused/stuck:** missing-material prompts disappeared; brief smolder glow expired between tool actions; stamina was not identifiable; pack looked paused; initial controls could not be reopened. The [playtest's B1](../../production/qa/playtests/playtest-2026-11-19-devin-agent.md#bugs-encountered) is a source-checked missing-refusal defect, not an invented recipe-design gap.

**Emotional response:** cold atmosphere/urgency, strong relief when flame caught and dawn returned. Loneliness and unassisted ignition satisfaction are not independently established. Mid-night became largely stationary after a log buffer; survivor shadows hid the ring.

## Metrics

| Metric | Target | Actual / limitation |
|---|---|---|
| First meaningful action | Learn within 2 minutes | Agent action ~24 s including setup; no naive-human result |
| Continuous slice play | 3–5 minutes | Model calculation 1,007.5 s (~16m48s) at default normal rate; not timed wall-clock proof |
| Independent full loop | Unguided from scratch | Not assessed |
| Critical fun blockers | 0 | Missing-material dead end observed; severity for novice completion unmeasured |
| Implementation defects | None blocking | 1 confirmed recoverable feedback omission (B1); no confirmed crash/hard softlock |
| Pipeline / architecture | Feasible representative production | Production build exists; effort, performance and full-game feasibility not established here |

**Feel assessment:** fire relief landed after assisted retries; unseen recipe requirements and a nominal 3–4.5 s smolder window undermine readable survival decisions. Warning-only energy did not demonstrate readable stamina drain. See [top three priorities](../../production/qa/playtests/playtest-2026-11-19-devin-agent.md#top-3-priorities-from-this-session).

### Milestone evidence versus remaining gaps

| Success criterion | Evidence | Still missing |
|---|---|---|
| Start to finish | Main scene/no args; Dusk → Night → Dawn; learned Run 2 survival overlay | Fresh-player unguided full loop |
| Movement and gathering | Walked to resources/back; qualitative supplies increased | No independent novice replication |
| Fire | Learned ignition; feeding spent supplies and enlarged flame/light | **Exact burn extension / controlled fed-versus-unfed comparison not measured** |
| Cold and stamina | Band cooled away and recovered near fed fire | **Ordinary-HUD stamina drain/readability inconclusive**; diagnostic energy is not that evidence |
| Failure path | Separate unfed fire → embers → dark ring; continued cooling (Z wait) | **Exact zero heat after Out not instrumented**; no fatal-cold result observed in these runs |
| Evidence | Raw notes/captures; PR #15 previously recorded passing core-rule CI (54 tests), not rerun for this report | Captures include assisted/condensed runs, not an independent default-paced validation recording |

## Recommendation: NOT ASSESSED

No naive human has played the full loop from scratch without guidance. The only playthroughs are agent runs needing retries, prior knowledge and timing assistance; even the successful dawn run cannot answer the validation question. This is **not PROCEED**, nor an invented human PIVOT/KILL decision. Agent observations support concrete follow-up, not production sign-off.

CD-PLAYTEST skipped — Lean mode.

## If Proceeding

Not authorized by this report. No new architecture decision, performance sign-off, sprint velocity or scope expansion is inferred.

## If Not Assessed

**Next step:** Scott (or a fresh player) plays **one silent run** from the main scene at default pacing, no debug/demo args and no coaching, starting from scratch. Complete the loop or record where it stops. Fixing the top-three onboarding issues first is optional; record the tested build either way. Then answer the six skill Phase 5 questions, one at a time:

1. Did you complete start → challenge → resolution on your own, without guidance or prior knowledge?
2. How long to the first meaningful action?
3. Did you feel loneliness, cold and relief when fire caught? Specifically what, and when?
4. What stopped, confused or pulled you out; where did you not know what to do or something broke?
5. As developer, is this quality achievable for the full game; what surprised you about build time?
6. PROCEED, PIVOT or KILL, and the specific reason?

Use those answers to update this report and [index](../index.md), not to retroactively label the agent run blind. Fixes remain optional before that run; no code/gameplay change is part of this documentation task.

## If Pivoting

No PIVOT selected. If later chosen, route Fire/HUD/energy feedback through design-impact review and balance checks as listed in the playtest report before tuning.

## If Killing

No KILL selected; no evidence-based full-loop rejection by a naive human exists here.

## Lessons Learned

- Implemented mechanics and passing rules tests do not establish discoverable ignition or non-numeric stamina readability.
- GUI-tool latency confounds a seconds-long ignition window; pauses rescued coverage, not evidence of natural usability.
- Commit batching is not effort measurement. Preserve the one-day session evidence without inventing hours.
- Keep this production first-night milestone distinct from the generic prototype-code template and broader MVP/three-day scope.
