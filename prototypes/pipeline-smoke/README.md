# pipeline-smoke

Concept image -> Hunyuan3D mesh -> palette-flattened GLB -> Godot render proof.
Paid steps are the two `gen_*` calls; everything else is free/local.
All commands run from the repo root.

```bash
# 1. Concept image (qwen-image, ~50s). Add --dry-run to preview the request.
python3 tools/assets/gen_image.py \
  --prompt "A single stylized low-poly snow-covered pine tree, 3D game asset, flat shading, faceted geometric shapes, three stacked chunky cone tiers of dark blue-green foliage with a thick white snow cap on each tier, short dark navy trunk, minimalist, muted cold color palette, isolated on a plain light gray background, centered, the whole object visible, three-quarter view from slightly above, soft even lighting, no ground plane, no cast shadow, no text" \
  --out prototypes/pipeline-smoke/out/pine_concept.png

# 1b. Downscale under the 4.5 MB upload limit (macOS built-in).
sips -Z 1024 prototypes/pipeline-smoke/out/pine_concept.png \
  --out prototypes/pipeline-smoke/out/pine_concept_1024.png

# 2. Mesh (Hunyuan3D LowPoly, ~5.5 min). --job-id resumes a submitted job.
python3 tools/assets/gen_mesh.py \
  --image prototypes/pipeline-smoke/out/pine_concept_1024.png \
  --out prototypes/pipeline-smoke/out/pine_raw.glb
# free re-download of an existing job:
python3 tools/assets/gen_mesh.py --job-id 1513548274199470080 --out /tmp/pine.glb

# 3. Flatten to palette (Blender 5.2, seconds).
/Applications/Blender.app/Contents/MacOS/Blender --background \
  --python tools/assets/flatten_glb.py -- \
  --in prototypes/pipeline-smoke/out/pine_raw.glb \
  --out prototypes/pipeline-smoke/godot/assets/pine_snowy.glb \
  --palette tools/assets/palette.json \
  --colors snow_light,pine_dark,trunk_navy --height 6.0
python3 tools/assets/inspect_glb.py prototypes/pipeline-smoke/godot/assets/pine_snowy.glb

# 4. Import + look.
/Applications/Godot.app/Contents/MacOS/Godot --headless \
  --path prototypes/pipeline-smoke/godot --import
/Applications/Godot.app/Contents/MacOS/Godot \
  --path prototypes/pipeline-smoke/godot --windowed --resolution 1280x720

# 5. Unattended capture -> out/smoke_wide.png + out/smoke_closeup.png, then quits.
/Applications/Godot.app/Contents/MacOS/Godot \
  --path prototypes/pipeline-smoke/godot --windowed --resolution 1280x720 -- --capture
```

`gen_mesh.py` refuses images over 4.5 MB (hence 1b). COLOR_0 is linear;
`flat_palette.tres` maps it to albedo.
