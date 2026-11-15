# lookdev

Per-face palette flattening (`flatten_glb.py --mode face`, the default) on the
four generated meshes, plus a Godot camp vignette for look judgement.
Texture mode (`--mode texture`) is kept for comparison; its outputs are
`*_tex.glb` / `*_tex.png`. All commands from the repo root; no paid API calls.

```bash
# 1. Flatten each raw mesh (face mode + smoothing; colors/height/lw/smooth
#    come from prototypes/lookdev/assets.json via --asset-config/--asset;
#    explicit CLI flags win over the config entry)
B=/Applications/Blender.app/Contents/MacOS/Blender
for a in pine bare_tree shelter campfire rock; do
  $B --background --python tools/assets/flatten_glb.py -- \
    --in prototypes/lookdev/out/${a}_raw.glb --out prototypes/lookdev/out/${a}_flat.glb \
    --palette tools/assets/palette.json \
    --asset-config prototypes/lookdev/assets.json --asset $a
done
# survivor: trunk_navy dropped from colors so the parka can't go navy
$B --background --python tools/assets/flatten_glb.py -- \
  --in prototypes/lookdev/out/survivor_raw.glb --out prototypes/lookdev/out/survivor_flat.glb \
  --palette tools/assets/palette.json \
  --colors roof_slate,wood_brown,warm_orange,skin_warm \
  --lightness-weight 1.0 --smooth 2 --height 1.75

# 1b. Texture-mode variant for comparison (palette-quantized 512px texture)
$B --background --python tools/assets/flatten_glb.py -- \
  --in prototypes/lookdev/out/pine_raw.glb --out prototypes/lookdev/out/pine_tex.glb \
  --palette tools/assets/palette.json --colors snow_light,pine_dark \
  --height 6.0 --mode texture

# 1c. Mesh generation (PAID Hunyuan3D API, ~25 credits/job — used once for
#     campfire + rock; do not re-run casually)
python3 tools/assets/gen_mesh.py --image prototypes/lookdev/out/campfire_concept_1024.png \
  --out prototypes/lookdev/out/campfire_raw.glb
python3 tools/assets/gen_mesh.py --image prototypes/lookdev/out/rock_concept_1024.png \
  --out prototypes/lookdev/out/rock_raw.glb

# 2. Inspect any output GLB (face mode: 0 images + COLOR_0; texture: 1 PNG)
python3 tools/assets/inspect_glb.py prototypes/lookdev/out/pine_flat.glb

# 3. Import + run the camp scene
G=/Applications/Godot.app/Contents/MacOS/Godot
$G --headless --path prototypes/lookdev/godot --import
$G --path prototypes/lookdev/godot --windowed --resolution 1280x720

# 4. Unattended captures -> prototypes/lookdev/evidence/*.png, then quits.
#    Day preset: camp_wide + 5 close-ups. Dusk preset: camp_wide_dusk +
#    campfire_close_dusk (low warm-pink sun, dark blue ambient, fire lit).
$G --path prototypes/lookdev/godot --windowed --resolution 1280x720 -- --capture
$G --path prototypes/lookdev/godot --windowed --resolution 1280x720 -- --capture --preset dusk
```

Flags: `--mode face|texture` (default face), `--lightness-weight` (default
0.5; lower ignores baked shading), `--smooth` (face-label smoothing passes
over edge adjacency, >=60% area majority required; default 2, 0 disables),
`--despeckle` / `--tex-size` (texture mode only), `--asset-config`/`--asset`,
`--max-tris N` (Decimate COLLAPSE before colouring when tris > N).
Asset-config entries may also carry `max_tris` and `rules` — a list of
`{"color": <palette name>, "where": {height_min, height_max, radial_min,
radial_max, normal_y_min}}` applied after quantization+smoothing (rules win);
heights are 0–1 of final bbox, radial is 0–1 of max horizontal extent.
