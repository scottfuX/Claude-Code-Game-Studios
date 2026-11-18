# rig-spike

**PROTOTYPE — NOT FOR PRODUCTION.** Technical spike for
`design/gdd/character-controller-and-animation.md`: can the existing
look-dev survivor (`prototypes/firebeforedark-concept/assets/survivor_flat.glb`)
be rigged and animated automatically, and does it read in Godot 4.7?

## Verdict

**Doable without an animator for the pipeline; clip quality is the real cost.**

| Check | Result |
|---|---|
| Auto rig (Blender 5.2, script only) | 23 bones (GDD ≤30), mesh unchanged at 3,222 tris, 0 unweighted verts |
| Godot import | Skeleton3D + 5 clips import clean; `SkeletonProfileHumanoid` 23/56 matched (missing eyes, jaw, fingers — mesh has none) |
| Clips | `idle`, `walk`, `chop` (0.4 / 1.2 / 0.4 s intro/effort/outro), `strike`, `shiver` — procedural keyframes, placeholder feel |
| Layering | `AnimationTree` Blend2 filtered to spine/arms/head: walk legs + shiver upper body works |
| Events | footfall method track (`left`/`right`) fires every step → hook for Terrain `{position, foot, sink_m}` |
| Attachment | axe on `BoneAttachment3D` `RightHand` follows the chop |
| Far camera (50 m, 30° fov) | survivor ≈ 30 px tall at 720p; chop/strike silhouettes still distinguishable |

Risks: no finger bones (grips are fixed attachments); glTF keeps the 4
strongest weights per vertex; hand-scripted keys look stiff — final clips
should come from Mixamo/Cascadeur retargeted onto this skeleton, or a person.

## Rebuild the rig

```bash
blender -b -P tools/assets/rig_survivor.py -- \
  --in prototypes/firebeforedark-concept/assets/survivor_flat.glb \
  --out prototypes/rig-spike/godot/assets/survivor_rigged.glb
```

## Run

```bash
godot --path prototypes/rig-spike/godot                  # close camera
godot --path prototypes/rig-spike/godot -- --view game   # 50° / 22 m
godot --path prototypes/rig-spike/godot -- --view far    # 50° / 50 m
```

Evidence frames: `evidence/close.png`, `evidence/game.png`, `evidence/far.png`.
