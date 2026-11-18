# firebeforedark-concept

**PROTOTYPE — NOT FOR PRODUCTION.** Throwaway feel test, its own Godot 4.7
project (Forward+). Question under test: *is "gather wood and light a fire
before dark, or freeze" tense and readable from the high far camera for
~10 minutes?*

All gameplay code lives in `main.gd` (single file, hardcoded values, no
architecture). Art is reused look-dev output: `assets/*_flat.glb` are copies of
`prototypes/lookdev/godot/assets/*_flat.glb`; day/dusk lighting values are
copied into the `DAY`/`DUSK` const tables.

## Run

On a fresh clone, import the assets once first — `.godot/` is not committed,
and running without it fails to preload the `.glb` files (grey window,
`Parse Error: Could not preload resource file`):

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path prototypes/firebeforedark-concept --import
```

Then run:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path prototypes/firebeforedark-concept
```

## Controls

All input goes through InputMap actions created at runtime in `_make_actions()`
— no hardcoded keys in logic.

| Action | Keyboard/mouse | Gamepad |
|---|---|---|
| Move | WASD | left stick |
| Run | Shift | A / cross |
| Interact (tap/hold) | E | X / square |
| Place fire site | F | Y / triangle |
| Rotate camera 45° | Q / E* | LB / RB |
| Zoom | wheel | right stick Y |
| Restart after death/win | R | start |

* Q / R rotate the camera 45°; E is only ever the interact key.

## Loop

Gather sticks (E tap on piles) and tinder (hold E 2 s on a bare tree, ≤2/tree),
chop bare trees (hold E 4 s → stump, +3 logs, once per tree), press F on snow
≥3 m from the shelter to place a fire site: hold E to clear snow, E to lay
1 tinder + 3 sticks, then mash E for ferro-rod strikes (35%/strike → embers).
Feed embers ≥2 sticks within 20 s → burning. Fuel in seconds: stick +40,
log +150, cap 400. Fire radiates warmth (2–5 m, scales with fuel). Body temp
drains 0.30 °C/min by day, 0.80 °C/min after 18:00, ×1.3 while running;
<35 °C hypothermia vignette + slow, ≤32 °C death (冻死了). Clock starts 15:00,
1 game hour = 2 real min; survive to 06:00 (撑过了第一夜).

## Autoplay verification

```bash
# happy path — bot gathers, chops, builds, lights, tends fire all night.
# Runs at Engine.time_scale=8 (~4 real min), captures evidence/, must reach 06:00.
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --autoplay

# no-fire control — bot idles, must die of cold (~2 game hours after dark),
# captures only evidence/death.png.
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --autoplay-nofire

# project opens cleanly
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
```

Latest verified runs: autoplay SURVIVED to 06:00 (temp 37.0, fuel 287 s
remaining); autoplay-nofire DIED at 20:00 game time (temp 32.0, 4.0 real-min
equivalent after 18:00 dark). Evidence in `evidence/`: `start.png`,
`gathering.png`, `chopping.png`, `ignition.png`, `dusk_fire.png`,
`night_fire.png`, `death.png`. `evidence/` is `.gdignore`d so captures don't
get imported as assets.

## Tunables

Top of `main.gd`, the `const` block after the preloads: movement/camera
(`WALK_SPEED`, `RUN_SPEED`, `CAM_PITCH`, `CAM_DIST`), clock (`GH_SECONDS`,
`START_HOUR`, `WIN_HOUR`), temperature (`DRAIN_DAY`, `DRAIN_NIGHT`,
`DRAIN_RUN_MULT`, `WARM_REGEN`, `HYPO_T`, `DEATH_T`), inventory caps, fire
economy (`EMBER_LIFE`, `FUEL_STICK`, `FUEL_LOG`, `FUEL_CAP`, `STRIKE_CHANCE`),
and the `DAY`/`DUSK` lighting tables.
