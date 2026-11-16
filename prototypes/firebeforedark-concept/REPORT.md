# Concept Prototype Report: fire-before-dark

> Date: 2026-11-15 · Path: engine (Godot 4.7) · Build: commits 4431468, d20a972 · Played by: owner

## Hypothesis
Under the high far camera, "gather wood and light a fire before dark, or freeze" is tense for ~10 minutes and readable on screen.

## Riskiest Assumption Tested
Actions (pick, chop, strike) read from the gameplay camera without skeletal animation (procedural bob/tilt only).

## Approach
Throwaway Godot project: flat snow clearing, look-dev assets, 4-step fire with fuel, 15:00→06:00 clock (2 real min per game hour), body temperature with freeze death, minimal HUD, scripted autoplay bot for evidence.

## Result
**Hypothesis REFUTED.** Owner, verbatim:
1. "不紧张，时间过的特别慢"
2. "几乎没有动作，所有就看到任务动动就干完了"
3. "还有很多问题："
   - "地形看不出来，需要有地形的感觉"
   - "脚印太假，雪地里应该有陷入的感觉"
   - "人物没有动作"
   - "行走起来没有质感"
   - "出去体温也没有怎么降"
   - "《荒野独居》还有很多各种各样的特点和场景，需要你体现出来"
   - "饥饿感，孤独感，无力，失望，伤心，痛苦，等等感觉都需要体现出来"

Riskiest assumption: **refuted** — procedural motion on an unrigged mesh does not read as work. Real skeletal animation is required.

## Metrics
- Autoplay bot: fire lit before 16:00; survived to 06:00 by clearing nearly every stick pile on the map.
- No-fire run: died at 20:00 (≈4 real min after dark). Day-time drain 0.30 °C/real-min → only −1.8 °C before dark: too gentle (matches owner note 5).
- Real minutes to dark: ~6 — felt slow because nothing happened in them, not only because of the length.

## Recommendation: PIVOT
The fantasy (cold, fire, solitude) is right; the prototype tested a thin, frictionless chore loop. The emotional range of "Alone" — hunger, loneliness, helplessness, disappointment, grief, pain — is absent and is the real design problem.

## If Pivoting
Next iteration questions, in order:
1. **Body and ground**: does a rigged, animated survivor walking through deep snow on real terrain (slopes, drifts, lake edge, sinking footprints, breath, crunch audio) feel heavy and physical? (rig spike + terrain/snow spike)
2. **Emotion design**: which show features and which mechanics deliver each named feeling (owner list above)? Needs a design doc before code — `/design-system`-level, not a prototype.
3. **Pressure curve**: shorter, harsher first day where cold bites outside and failure is possible (wind, wet, weak fires, failed strikes).

## Lessons Learned
- Autoplay proved the rules run; it said nothing about feel. Owner play is the only feel signal.
- "Readable from the camera" requires bodies that move; budget the rig/animation work as core, not polish.
- Gentle numbers make a survival loop feel like housework; tension needs real loss and visible struggle.
