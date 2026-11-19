# Milestone: First Playable Night

## Milestone Goal

Survive one night in a small snowy area in the main lonefire project. Start at dusk, gather wood, and light and feed a fire while managing cold and stamina through dawn. This is the [brief's feel slice](../../design/game-brief.md#build-order), not the full [MVP system scope](../../design/gdd/systems-index.md#priority-tiers).

## Feature List

### Must Ship

| Feature | Scope |
|---|---|
| Move and explore | Control the survivor and reach gathering spots and the fire within one small snowy area. |
| Cold and stamina | Exposure cools the survivor; activity drains stamina; standing near a burning fire counters the cold. Give the player clear, non-numeric feedback for both. |
| Gather wood | Collect usable fuel in the world and carry it to the fire. |
| Light and feed a fire | Start a fire, use gathered wood to extend its burn, and let an unfed fire burn out and stop providing warmth. |
| Complete the night | Launch from the Godot project's main scene without debug setup. Play from dusk through night to the next sunrise, or end earlier from fatal cold. |

### Deferred

Sleep (including sleep-mode and wake integration), full Needs & Weight beyond stamina, and the broader multi-day MVP systems are not exit requirements for this milestone.

## Success Criteria

- [ ] **Start to finish:** Run the main project normally with no demo flags. A new run starts at dusk; the sky darkens into night and brightens at dawn. Keep the survivor alive through the next sunrise and see a clear survival result.
- [ ] **Movement and gathering:** Walk from the starting area to a wood source and back to the fire site. Gathering increases carried fuel.
- [ ] **Fire:** Light a fire from an unlit site. Feed it with wood gathered during the run; the wood is spent and the fire burns longer than it would without feeding.
- [ ] **Cold and stamina:** Observe cold worsen away from heat and the cooling slow or reverse within reach of a burning fire. Observe stamina drain during activity. Both changes have readable, non-numeric feedback.
- [ ] **Failure path:** Let an unfed fire burn out and verify it no longer warms the survivor. If cold becomes fatal before sunrise, the run reports a cold loss, not survival.
- [ ] **Evidence:** The build PR has passing gdUnit4 core rule tests in CI covering gathering, fire/fuel, cold/stamina and run outcomes. A short recording and screenshots show the playable loop from the main project, including the dawn result.
