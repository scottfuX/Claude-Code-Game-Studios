# PROTOTYPE - NOT FOR PRODUCTION
# Blender background script: rig a flattened survivor GLB and author clips.
#   Blender --background --python prototypes/rig-spike/rig_survivor.py -- \
#     --in survivor_flat.glb --out survivor_rigged.glb [--preview DIR]
#
# Rig spike (design/gdd/character-controller-and-animation.md, Open Questions):
#  1. merges the per-face split vertices flatten_glb.py leaves (3,222 tris →
#     ~1.6k shared verts) so the mesh is one connected shell again;
#  2. builds a 23-bone armature named after Godot's SkeletonProfileHumanoid
#     (no fingers), placed from LANDMARKS fitted once to this mesh (A-pose,
#     facing -Y in Blender / +Z in glTF);
#  3. skins with Blender automatic (bone heat) weights;
#  4. keys idle / walk / chop / strike / shiver procedurally (30 fps) and
#     exports every action as a glTF animation.
# --preview DIR renders ortho front/side workbench stills of a few key poses.
import argparse
import math
import os
import sys

import bmesh
import bpy
from mathutils import Euler, Matrix, Quaternion, Vector

FPS = 30

# Joint positions in metres, Blender space (+X = character's left, -Y =
# forward, +Z = up). Fitted to survivor_flat.glb (1.75 m, A-pose); a
# regenerated mesh needs these re-picked (or a Mixamo-style marker pass).
C = -0.05  # body centre line in Y (backpack hangs behind it)
LANDMARKS = {
    "Root": ((0, C, 0.0), (0, C - 0.15, 0.0)),
    "Hips": ((0, C, 0.66), (0, C, 0.80)),
    "Spine": ((0, C, 0.80), (0, C, 0.94)),
    "Chest": ((0, C, 0.94), (0, C, 1.08)),
    "UpperChest": ((0, C, 1.08), (0, C, 1.24)),
    "Neck": ((0, C, 1.24), (0, C, 1.38)),
    "Head": ((0, C, 1.38), (0, C, 1.72)),
    "LeftShoulder": ((0.04, C, 1.22), (0.17, C, 1.24)),
    "LeftUpperArm": ((0.17, C, 1.24), (0.37, C - 0.02, 1.04)),
    "LeftLowerArm": ((0.37, C - 0.02, 1.04), (0.52, C - 0.04, 0.88)),
    "LeftHand": ((0.52, C - 0.04, 0.88), (0.58, C - 0.05, 0.76)),
    "LeftUpperLeg": ((0.11, C, 0.64), (0.13, C - 0.02, 0.36)),
    "LeftLowerLeg": ((0.13, C - 0.02, 0.36), (0.15, C, 0.10)),
    "LeftFoot": ((0.15, C, 0.10), (0.15, C - 0.16, 0.03)),
    "LeftToes": ((0.15, C - 0.16, 0.03), (0.15, C - 0.24, 0.03)),
}
PARENT = {
    "Hips": "Root", "Spine": "Hips", "Chest": "Spine", "UpperChest": "Chest",
    "Neck": "UpperChest", "Head": "Neck", "LeftShoulder": "UpperChest",
    "LeftUpperArm": "LeftShoulder", "LeftLowerArm": "LeftUpperArm",
    "LeftHand": "LeftLowerArm", "LeftUpperLeg": "Hips",
    "LeftLowerLeg": "LeftUpperLeg", "LeftFoot": "LeftLowerLeg",
    "LeftToes": "LeftFoot",
}
CONNECTED = {"Spine", "Chest", "UpperChest", "Neck", "Head", "LeftUpperArm",
             "LeftLowerArm", "LeftHand", "LeftLowerLeg", "LeftFoot", "LeftToes"}


def mirror(name):
    return "Right" + name[4:] if name.startswith("Left") else name


def all_bones():
    out = {}
    for n, (h, t) in LANDMARKS.items():
        out[n] = (h, t)
        if n.startswith("Left"):
            out[mirror(n)] = ((-h[0], h[1], h[2]), (-t[0], t[1], t[2]))
    return out


def parent_of(n):
    base = "Left" + n[5:] if n.startswith("Right") else n
    p = PARENT.get(base)
    if p is None:
        return None
    return mirror(p) if n.startswith("Right") and p.startswith("Left") else p


def build_armature():
    arm = bpy.data.armatures.new("SurvivorRig")
    obj = bpy.data.objects.new("Skeleton", arm)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bones = all_bones()
    for n, (h, t) in bones.items():
        b = arm.edit_bones.new(n)
        b.head, b.tail = Vector(h), Vector(t)
    for n in bones:
        p = parent_of(n)
        if p:
            arm.edit_bones[n].parent = arm.edit_bones[p]
            base = "Left" + n[5:] if n.startswith("Right") else n
            arm.edit_bones[n].use_connect = base in CONNECTED
    # Consistent rolls so local axes line up across the mirrored chains.
    for b in arm.edit_bones:
        b.align_roll(Vector((0, -1, 0)))
    for n in ("Root", "LeftToes", "RightToes", "LeftFoot", "RightFoot"):
        arm.edit_bones[n].align_roll(Vector((0, 0, 1)))
    bpy.ops.object.mode_set(mode="OBJECT")
    for b in arm.bones:
        b.use_deform = b.name != "Root"
    return obj


def import_mesh(path):
    bpy.ops.import_scene.gltf(filepath=path)
    mesh = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bm = bmesh.new()
    bm.from_mesh(mesh.data)
    before = len(bm.verts)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bm.to_mesh(mesh.data)
    print(f"merge: {before} -> {len(mesh.data.vertices)} verts, "
          f"{len(mesh.data.polygons)} tris")
    bm.free()
    mesh.name = "Survivor"
    return mesh


def skin(mesh, rig):
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    unweighted = sum(1 for v in mesh.data.vertices
                     if not any(g.weight > 1e-3 for g in v.groups))
    print(f"skin: {len(mesh.vertex_groups)} groups, "
          f"{unweighted} unweighted verts")
    if unweighted:
        # Bone heat leaves tiny floating shards unweighted: give each the
        # nearest bone so nothing stays behind in rest pose.
        bones = all_bones()
        for v in mesh.data.vertices:
            if any(g.weight > 1e-3 for g in v.groups):
                continue
            best = min((n for n in bones if n != "Root"), key=lambda n: (
                (Vector(bones[n][0]) + Vector(bones[n][1])) / 2 - v.co).length)
            mesh.vertex_groups[best].add([v.index], 1.0, "REPLACE")


# ---- animation authoring --------------------------------------------------
# A pose is {bone: (pitch, yaw, roll)} in degrees about armature axes
# (pitch = X: negative swings a limb forward; yaw = Z; roll = Y), applied
# relative to the parent, plus optional "hips_loc" offset and arm aims:
# "aimLeft"/"aimRight" = (upper_dir, lower_dir) in the torso's frame, which
# set the arm chain absolutely (any euler on those bones is added on top).

def euler_q(deg):
    return Euler([math.radians(d) for d in (deg[0], deg[2], deg[1])],
                 "XYZ").to_quaternion()


def to_basis(rig, bone, q):
    rest = rig.data.bones[bone].matrix_local.to_quaternion()
    return rest.inverted() @ q @ rest


def rest_dir(rig, bone):
    b = rig.data.bones[bone]
    return (b.tail_local - b.head_local).normalized()


def aim_rel(rig, pose, side):
    """Parent-relative rotations for one arm from torso-frame directions."""
    up_dir, lo_dir = pose["aim" + side]
    sh = euler_q(pose.get(side + "Shoulder", (0, 0, 0)))
    a_up = rest_dir(rig, side + "UpperArm").rotation_difference(
        Vector(up_dir).normalized())
    a_lo = rest_dir(rig, side + "LowerArm").rotation_difference(
        Vector(lo_dir).normalized())
    return {side + "UpperArm": sh.inverted() @ a_up,
            side + "LowerArm": a_up.inverted() @ a_lo}


def key_pose(rig, frame, pose):
    rel = {}
    for side in ("Left", "Right"):
        if "aim" + side in pose:
            rel.update(aim_rel(rig, pose, side))
    for pb in rig.pose.bones:
        q = rel.get(pb.name, Quaternion()) @ euler_q(
            pose.get(pb.name, (0, 0, 0)))
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = to_basis(rig, pb.name, q)
        pb.keyframe_insert("rotation_quaternion", frame=frame)
    hips = rig.pose.bones["Hips"]
    off = Vector(pose.get("hips_loc", (0, 0, 0)))
    rest = rig.data.bones["Hips"].matrix_local.to_3x3()
    hips.location = rest.inverted() @ off
    hips.keyframe_insert("location", frame=frame)


def sym(left, aim=None, **extra):
    """Mirror a dict of Left* bones to Right* (yaw and roll flip)."""
    out = dict(extra)
    for n, (p, y, r) in left.items():
        out[n] = (p, y, r)
        out[mirror(n)] = (p, -y, -r)
    if aim:
        out["aimLeft"] = aim
        out["aimRight"] = tuple((-v[0], v[1], v[2]) for v in aim)
    return out


def merge(*poses):
    out = {}
    for p in poses:
        for k, v in p.items():
            if k in out and k != "hips_loc" and not k.startswith("aim"):
                out[k] = tuple(a + b for a, b in zip(out[k], v))
            else:
                out[k] = v
    return out


def make_action(rig, name, keys, length, markers=()):
    act = bpy.data.actions.new(name)
    rig.animation_data_create()
    rig.animation_data.action = act
    for f, pose in keys:
        key_pose(rig, f, pose)
    for f, m in markers:
        act.pose_markers.new(m).frame = f
    act.frame_range = (0, length)
    act.use_frame_range = True
    act.use_fake_user = True
    track = rig.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 0, act)
    rig.animation_data.action = None
    return act


# Shared stances (exaggerated: the figure is ~30-70 px tall on screen).
TIRED = sym({"LeftShoulder": (0, -4, 0), "LeftUpperArm": (-6, 0, 8),
             "LeftLowerArm": (-14, 0, 0)},
            Spine=(8, 0, 0), Chest=(6, 0, 0), Neck=(-4, 0, 0), Head=(6, 0, 0))


def clip_idle(rig):
    # 2 s breathing loop: chest rise, shoulders lift, slow weight shift.
    def p(t):
        s = math.sin(t * math.tau)
        return merge(TIRED, sym({"LeftShoulder": (0, 0, -3 * s),
                                 "LeftUpperArm": (0, 0, 2 * s)}),
                     {"Chest": (-3 * s, 0, 0), "Hips": (0, 0, 2 * s),
                      "Head": (2 * s, 0, 0),
                      "hips_loc": (0.012 * s, 0, 0.006 * s)})
    return make_action(rig, "idle",
                       [(f, p(f / 60)) for f in range(0, 61, 10)], 60)


def clip_walk(rig):
    # 1.2 s heavy wade cycle (two steps). Big leg lift, forward lean,
    # deep bob on contact; footfall markers at each contact.
    def p(t):
        a = math.sin(t * math.tau)          # +: left leg forward
        lift_l = max(0.0, math.sin(t * math.tau + math.pi / 2))
        lift_r = max(0.0, -math.sin(t * math.tau + math.pi / 2))
        bob = -0.05 * abs(math.cos(t * math.tau))
        return merge(TIRED, {
            "LeftUpperLeg": (-32 * a - 18 * lift_l, 0, 0),
            "RightUpperLeg": (32 * a - 18 * lift_r, 0, 0),
            "LeftLowerLeg": (60 * lift_l + 6, 0, 0),
            "RightLowerLeg": (60 * lift_r + 6, 0, 0),
            "LeftFoot": (-12 * lift_l, 0, 0),
            "RightFoot": (-12 * lift_r, 0, 0),
            "LeftUpperArm": (30 * a, 0, 0),
            "RightUpperArm": (-30 * a, 0, 0),
            "LeftLowerArm": (-18 - 10 * max(0, -a), 0, 0),
            "RightLowerArm": (-18 - 10 * max(0, a), 0, 0),
            "Spine": (10, 5 * a, 0), "Chest": (4, 6 * a, 0),
            "Hips": (0, -8 * a, 5 * math.cos(t * math.tau)),
            "Head": (-4, -6 * a, 0),
            "hips_loc": (0.03 * math.cos(t * math.tau), 0, bob),
        })
    return make_action(rig, "walk",
                       [(f, p(f / 36)) for f in range(0, 37, 3)], 36,
                       markers=[(9, "footfall_left"), (27, "footfall_right")])


def clip_chop(rig):
    # GDD C7 example timing: intro 0.4 s, effort 1.2 s (loops), outro 0.4 s.
    # Effort: two-handed overhead wind-up then a hard downward swing.
    up = sym({"LeftUpperLeg": (-6, 0, 0), "LeftLowerLeg": (10, 0, 0),
              "LeftShoulder": (0, 0, -10)},
             aim=((0.2, 0.15, 1.0), (-0.45, 0.5, 0.55)),
             Spine=(-6, 0, 0), Chest=(-6, 0, 0), Head=(-10, 0, 0))
    hit = sym({"LeftUpperLeg": (-28, 0, 0), "LeftLowerLeg": (40, 0, 0),
               "LeftFoot": (-10, 0, 0)},
              aim=((0.1, -1.0, -0.3), (-0.25, -0.9, -0.45)),
              Spine=(30, 0, 0), Chest=(18, 0, 0), Head=(10, 0, 0),
              hips_loc=(0, 0.04, -0.12))
    keys = [(0, TIRED), (12, merge(up)),            # intro 0..12
            (24, hit), (30, hit), (48, up),          # effort 12..48
            (60, TIRED)]                             # outro 48..60
    return make_action(rig, "chop", keys, 60,
                       markers=[(12, "effort_start"), (24, "impact"),
                                (48, "effort_end")])


def clip_strike(rig):
    # Crouch over the fire site and rake the ferro rod: intro 0.4 s,
    # effort 0.4 s (loops, one strike), outro 0.4 s.
    crouch = sym({"LeftUpperLeg": (-75, 8, 0), "LeftLowerLeg": (110, 0, 0),
                  "LeftFoot": (-30, 0, 0)},
                 aim=((0.3, -0.55, -0.8), (-0.35, -0.85, 0.1)),
                 Spine=(30, 0, 0), Chest=(18, 0, 0), Head=(16, 0, 0),
                 hips_loc=(0, 0.10, -0.32))
    rake = merge(crouch, {"aimRight": ((-0.2, -0.75, -0.65),
                                       (0.25, -0.6, -0.75)),
                          "RightHand": (25, 0, 0), "Chest": (6, 0, 0)})
    keys = [(0, TIRED), (12, crouch), (16, rake), (24, crouch), (36, TIRED)]
    return make_action(rig, "strike", keys, 36,
                       markers=[(12, "effort_start"), (16, "spark"),
                                (24, "effort_end")])


def clip_shiver(rig):
    # Overlay: hug the chest, shoulders up, fast tremble (0.66 s loop).
    hug = sym({"LeftShoulder": (0, 0, -12)},
              aim=((0.3, -0.45, -0.85), (-0.9, -0.35, 0.3)),
              Spine=(12, 0, 0), Chest=(10, 0, 0), Neck=(10, 0, 0),
              Head=(10, 0, 0))
    hug["aimRight"] = ((-0.3, -0.5, -0.8), (0.9, -0.45, 0.2))
    keys = []
    for i, f in enumerate(range(0, 21, 2)):
        s = 1 if i % 2 == 0 else -1
        if f == 20:
            s = 1
        jit = sym({"LeftShoulder": (0, 0, -3 * s), "LeftUpperArm": (0, 3 * s, 0)},
                  Chest=(0, 3 * s, 0), Head=(0, -3 * s, 2 * s))
        keys.append((f, merge(hug, jit)))
    return make_action(rig, "shiver", keys, 20)


CLIPS = [clip_idle, clip_walk, clip_chop, clip_strike, clip_shiver]


def preview(rig, out_dir, mesh):
    os.makedirs(out_dir, exist_ok=True)
    scn = bpy.context.scene
    scn.render.engine = "BLENDER_WORKBENCH"
    scn.display.shading.color_type = "VERTEX"
    scn.render.resolution_x = scn.render.resolution_y = 400
    cam = bpy.data.cameras.new("cam")
    cam.type, cam.ortho_scale = "ORTHO", 2.4
    co = bpy.data.objects.new("cam", cam)
    scn.collection.objects.link(co)
    scn.camera = co
    views = {"front": ((0, -6, 0.9), (math.pi / 2, 0, 0)),
             "side": ((-6, 0, 0.9), (math.pi / 2, 0, -math.pi / 2))}
    shots = [("rest", None, 0), ("walk", "walk", 0), ("walk", "walk", 9),
             ("chop", "chop", 12), ("chop", "chop", 24),
             ("strike", "strike", 16), ("shiver", "shiver", 0)]
    for t in rig.animation_data.nla_tracks:
        t.mute = True
    for label, act, f in shots:
        rig.animation_data.action = bpy.data.actions[act] if act else None
        if not act:
            for pb in rig.pose.bones:
                pb.matrix_basis = Matrix()
        scn.frame_set(f)
        for v, (loc, rot) in views.items():
            co.location, co.rotation_euler = loc, rot
            scn.render.filepath = os.path.join(out_dir, f"{label}_{f:02d}_{v}.png")
            bpy.ops.render.render(write_still=True)
    rig.animation_data.action = None
    for t in rig.animation_data.nla_tracks:
        t.mute = False


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="src", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--preview")
    a = ap.parse_args(argv)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scn = bpy.context.scene
    scn.render.fps = FPS
    mesh = import_mesh(a.src)
    rig = build_armature()
    skin(mesh, rig)
    for clip in CLIPS:
        act = clip(rig)
        print(f"clip: {act.name} {int(act.frame_range[1])} frames")
    if a.preview:
        preview(rig, a.preview, mesh)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=a.out, export_format="GLB", use_selection=False,
        export_animations=True, export_animation_mode="ACTIONS",
        export_force_sampling=True, export_frame_range=False,
        export_vertex_color="ACTIVE", export_all_vertex_colors=True)
    print(f"bones: {len(rig.data.bones)}  wrote {a.out}")


main()
