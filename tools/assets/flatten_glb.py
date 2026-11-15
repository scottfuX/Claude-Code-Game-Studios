# Blender background script: flatten a textured GLB into a stylized GLB.
#   Blender --background --python tools/assets/flatten_glb.py -- \
#     --in RAW.glb --out FLAT.glb --palette tools/assets/palette.json \
#     --colors name1,name2 --height 6.0 [--mode face|texture]
#     [--asset-config assets.json --asset NAME]
#
# Modes:
#  face (default): per-face nearest palette colour (weighted Oklab,
#    --lightness-weight default 0.5) written to a CORNER color attribute;
#    optional label smoothing over edge adjacency (--smooth passes, default 2:
#    a face takes the area-weighted majority label of its edge-neighbours when
#    that majority holds >=60% of the neighbour area); UVs/textures/images
#    stripped; vertex-color material.
#  texture: downsample the base-colour texture to <=512px, quantize
#    every pixel to the nearest allowed palette colour in weighted Oklab
#    (--lightness-weight, default 0.5, de-emphasises baked shading), despeckle
#    with a 3x3 majority filter (--despeckle passes, default 1), pack the
#    result as the GLB's only texture. One Principled material, roughness 1,
#    metallic 0. No vertex colours. Prints a UV-island-coverage histogram.
#
# --asset-config/--asset: read colors, height, lightness_weight and smooth
#    from an entry of {"assets": [{"name": ...}]}; explicit CLI flags win.
#
# Notes for this Blender (5.2.1):
#  - image.pixels returns the raw stored values; for an sRGB PNG that is the
#    sRGB-encoded bytes/255, so we do the sRGB->linear conversion ourselves.
#  - glTF COLOR_0 is linear, so face mode writes linear values to the attribute.
#  - glTF exporter: export_vertex_color in MATERIAL|ACTIVE|NAME|NONE
#    (export_colors is gone); export_image_format NONE|AUTO.
import argparse
import json
import math
import os
import struct
import sys
import tempfile
import zlib

import bpy
from mathutils import Matrix, Vector

import numpy as np


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def linear_to_oklab(r, g, b):
    """Oklab (Bjorn Ottosson) from linear sRGB."""
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_ = l ** (1.0 / 3.0) if l > 0.0 else 0.0
    m_ = m ** (1.0 / 3.0) if m > 0.0 else 0.0
    s_ = s ** (1.0 / 3.0) if s > 0.0 else 0.0
    return (0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
            1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
            0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_)


def linear_to_oklab_arr(arr):
    """Vectorized Oklab for an (...,3) float array of linear sRGB."""
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_ = np.cbrt(np.maximum(l, 0.0))
    m_ = np.cbrt(np.maximum(m, 0.0))
    s_ = np.cbrt(np.maximum(s, 0.0))
    return np.stack([
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_], axis=-1)


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", required=True)
    ap.add_argument("--out", dest="out", required=True)
    ap.add_argument("--palette", required=True)
    ap.add_argument("--colors", default=None, help="Comma-separated palette names; default: all (or --asset-config).")
    ap.add_argument("--height", type=float, default=None,
                    help="Final height along the up axis (required unless --asset-config provides it).")
    ap.add_argument("--asset-config", default=None,
                    help="JSON with an 'assets' list; supplies colors/height/lightness_weight/smooth.")
    ap.add_argument("--asset", default=None, help="Asset name inside --asset-config.")
    ap.add_argument("--mode", default="face", choices=["texture", "face"])
    ap.add_argument("--lightness-weight", type=float, default=None,
                    help="Oklab L-distance weight (default 0.5; lower ignores baked shading).")
    ap.add_argument("--smooth", type=int, default=None,
                    help="Face-label smoothing passes over edge adjacency (default 2; 0 disables).")
    ap.add_argument("--despeckle", type=int, default=1, help="3x3 majority-filter passes (texture mode).")
    ap.add_argument("--tex-size", type=int, default=512, help="Max texture side after downsampling.")
    ap.add_argument("--max-tris", type=int, default=None,
                    help="Decimate (COLLAPSE) before colouring when tris exceed N.")
    return ap.parse_args(argv)


def apply_asset_config(args):
    """Fill unset options from an assets.json entry; CLI flags win."""
    if args.asset and not args.asset_config:
        sys.exit("flatten_glb: --asset requires --asset-config")
    if args.asset_config:
        cfg = json.load(open(args.asset_config))
        ent = next((a for a in cfg.get("assets", []) if a.get("name") == args.asset), None)
        if ent is None:
            sys.exit(f"flatten_glb: no asset '{args.asset}' in {args.asset_config}")
        if args.colors is None and ent.get("colors"):
            args.colors = ",".join(ent["colors"])
        if args.height is None:
            args.height = ent.get("height")
        if args.lightness_weight is None:
            args.lightness_weight = ent.get("lightness_weight")
        if args.smooth is None:
            args.smooth = ent.get("smooth")
        if args.max_tris is None:
            args.max_tris = ent.get("max_tris")
        args.rules = ent.get("rules", [])
    if args.height is None:
        sys.exit("flatten_glb: --height required (or provided by --asset-config)")
    if args.lightness_weight is None:
        args.lightness_weight = 0.5
    if args.smooth is None:
        args.smooth = 2
    if not hasattr(args, "rules"):
        args.rules = []


def import_and_join(inp):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=inp)
    mesh_objs = [o for o in bpy.data.objects if o.type == "MESH"]
    if not mesh_objs:
        sys.exit("flatten_glb: no mesh objects after import")
    for o in bpy.data.objects:
        if o.type != "MESH":
            bpy.data.objects.remove(o)
    bpy.ops.object.select_all(action="DESELECT")
    for o in mesh_objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = mesh_objs[0]
    if len(mesh_objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj


def find_texture_image():
    for mat in bpy.data.materials:
        nt = getattr(mat, "node_tree", None)
        if not nt:
            continue
        for node in nt.nodes:
            if node.bl_idname == "ShaderNodeTexImage" and node.image and node.image.size[0] > 0:
                return node.image
    imgs = [i for i in bpy.data.images if i.size[0] > 0]
    if not imgs:
        sys.exit("flatten_glb: no texture image found")
    return imgs[0]


def image_pixels(img):
    buf = np.empty(img.size[0] * img.size[1] * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    return buf


def png_bytes(w, h, rgb):
    """Minimal PNG encoder: w,h ints, rgb = h*w*3 bytes."""
    def chunk(t, d):
        c = t + d
        return struct.pack(">I", len(d)) + c + struct.pack(">I", zlib.crc32(c))
    raw = b"".join(b"\x00" + rgb[y * w * 3:(y + 1) * w * 3] for y in range(h))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 6))
            + chunk(b"IEND", b""))


def quantize_image(img, palette_srgb, palette_lab, max_side, w_l, despeckle):
    """Downsample+quantize the source image to palette indices; returns
    (index grid, sRGB byte grid, new w, new h)."""
    w, h = img.size
    scale = min(1.0, max_side / max(w, h))
    nw = max(1, int(round(w * scale)))
    nh = max(1, int(round(h * scale)))
    arr = image_pixels(img).reshape(h, w, 4)[:, :, :3]
    lin = np.where(arr <= 0.04045, arr / 12.92, ((arr + 0.055) / 1.055) ** 2.4)
    if w % nw == 0 and h % nh == 0:
        fx, fy = w // nw, h // nh
        small = lin.reshape(nh, fy, nw, fx, 3).mean(axis=(1, 3))
    else:
        # non-integer factor: nearest-centre downsample (quantization hides it)
        ys = (np.arange(nh) * h / nh).astype(int)
        xs = (np.arange(nw) * w / nw).astype(int)
        small = lin[np.ix_(ys, xs)]
    lab = linear_to_oklab_arr(small)
    diff = lab[:, :, None, :] - palette_lab[None, None, :, :]
    d2 = (w_l * diff[..., 0]) ** 2 + diff[..., 1] ** 2 + diff[..., 2] ** 2
    idx = d2.argmin(axis=2)

    K = len(palette_lab)
    eye = np.eye(K, dtype=np.float32)
    for _ in range(max(0, despeckle)):
        pad = np.pad(idx, 1, mode="edge")
        votes = np.zeros(idx.shape + (K,), dtype=np.float32)
        for dy in range(3):
            for dx in range(3):
                votes += eye[pad[dy:dy + nh, dx:dx + nw]]
        votes += 0.5 * eye[idx]          # tie-break: keep current
        idx = votes.argmax(axis=2)

    rgb = palette_srgb[idx].astype(np.uint8)   # (nh,nw,3) display bytes
    return idx, rgb, nw, nh


def uv_island_mask(me, uvl, nw, nh):
    """Rasterize UV triangles into an (nh,nw) bool mask: True = texel used."""
    mask = np.zeros((nh, nw), dtype=bool)

    def raster(pts):
        xs = [p[0] * nw for p in pts]
        ys = [p[1] * nh for p in pts]
        x0 = max(0, int(min(xs)))
        x1 = min(nw - 1, int(max(xs)) + 1)
        y0 = max(0, int(min(ys)))
        y1 = min(nh - 1, int(max(ys)) + 1)
        (ax, ay), (bx, by), (cx, cy) = (xs[0], ys[0]), (xs[1], ys[1]), (xs[2], ys[2])
        d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(d) < 1e-12:
            return
        for py in range(y0, y1 + 1):
            for px in range(x0, x1 + 1):
                fx, fy = px + 0.5, py + 0.5
                w0 = ((by - cy) * (fx - cx) + (cx - bx) * (fy - cy)) / d
                w1 = ((cy - ay) * (fx - cx) + (ax - cx) * (fy - cy)) / d
                w2 = 1.0 - w0 - w1
                if w0 >= -1e-6 and w1 >= -1e-6 and w2 >= -1e-6:
                    mask[py, px] = True

    for poly in me.polygons:
        uvs = [(uvl.data[li].uv.x % 1.0, uvl.data[li].uv.y % 1.0) for li in poly.loop_indices]
        for t in range(len(uvs) - 2):
            raster([uvs[0], uvs[t + 1], uvs[t + 2]])
    return mask


def smooth_face_labels(me, labels, npasses):
    """Relabel a face to the area-weighted majority label of its edge-neighbour
    faces when that majority holds >=60% of the neighbour area. Returns the list
    of per-pass changed-face counts."""
    neigh = [[] for _ in me.polygons]
    edges = {}
    for i, poly in enumerate(me.polygons):
        for ek in poly.edge_keys:
            edges.setdefault(ek, []).append(i)
    for ps in edges.values():
        for a in ps:
            for b in ps:
                if a != b:
                    neigh[a].append(b)
    areas = [p.area for p in me.polygons]
    changes = []
    for _ in range(max(0, npasses)):
        new = list(labels)
        nch = 0
        for i in range(len(me.polygons)):
            if not neigh[i]:
                continue
            votes = {}
            tot = 0.0
            for j in neigh[i]:
                votes[labels[j]] = votes.get(labels[j], 0.0) + areas[j]
                tot += areas[j]
            best, barea = max(votes.items(), key=lambda kv: kv[1])
            if best != labels[i] and tot > 0.0 and barea / tot >= 0.6:
                new[i] = best
                nch += 1
        labels[:] = new
        changes.append(nch)
    return changes


def rebuild_material(me, kind, tex_image=None, attr_name=None):
    me.materials.clear()
    mat = bpy.data.materials.new("flat_palette" if kind == "face" else "palette_tex")
    try:
        mat.use_nodes = True
    except Exception:
        pass
    nt = mat.node_tree
    nt.nodes.clear()
    out_node = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 1.0
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = 0.0
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.0
    if kind == "face":
        vcol = nt.nodes.new("ShaderNodeVertexColor")
        vcol.layer_name = attr_name
        nt.links.new(vcol.outputs["Color"], bsdf.inputs["Base Color"])
    else:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = tex_image
        tex.interpolation = "Closest"
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out_node.inputs["Surface"])
    me.materials.append(mat)


def fit_to_height(me, height):
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    xmin, xmax, ymin, ymax, zmin, zmax = min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)
    if zmax - zmin <= 0:
        sys.exit("flatten_glb: zero height on up axis")
    s = height / (zmax - zmin)
    cx, cy = (xmin + xmax) / 2.0, (ymin + ymax) / 2.0
    me.transform(Matrix.Scale(s, 4) @ Matrix.Translation(Vector((-cx, -cy, -zmin))))


def main():
    args = parse_args()
    apply_asset_config(args)
    palette_all = json.load(open(args.palette))
    names = args.colors.split(",") if args.colors else list(palette_all.keys())
    palette = []          # (name, linear rgb, oklab, srgb bytes)
    for n in names:
        if n not in palette_all:
            sys.exit(f"flatten_glb: palette has no color '{n}'")
        h = palette_all[n].lstrip("#")
        srgb = tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
        lin = tuple(srgb_to_linear(c) for c in srgb)
        palette.append((n, lin, linear_to_oklab(*lin), tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))))

    obj = import_and_join(args.inp)
    me = obj.data
    if args.max_tris and len(me.polygons) > args.max_tris:
        before = len(me.polygons)
        mod = obj.modifiers.new("decimate", "DECIMATE")
        mod.decimate_type = "COLLAPSE"
        mod.ratio = args.max_tris / before
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
        print(f"decimate: {before} -> {len(me.polygons)} tris (target {args.max_tris})")
    img = find_texture_image()
    w0, h0 = img.size
    uvl = me.uv_layers.active if me.uv_layers else None

    counts, hrange, assigned = {}, {}, []
    new_img, nw, nh = None, 0, 0

    if args.mode == "face":
        if uvl is None:
            sys.exit("flatten_glb: mesh has no UV layer to sample")
        buf = image_pixels(img)

        def sample_uv(u, v):
            x = min(int((u % 1.0) * w0), w0 - 1)
            y = min(int((v % 1.0) * h0), h0 - 1)
            i = (y * w0 + x) * 4
            return (srgb_to_linear(buf[i]), srgb_to_linear(buf[i + 1]), srgb_to_linear(buf[i + 2]))

        ca = me.color_attributes.new(name="Color", type="FLOAT_COLOR", domain="CORNER")
        zmin0 = min(v.co.z for v in me.vertices)
        zspan = max(v.co.z for v in me.vertices) - zmin0 or 1.0
        wl = args.lightness_weight
        labels, avgs, hfs = [], [], []
        for poly in me.polygons:
            uvs = [uvl.data[li].uv for li in poly.loop_indices]
            acc = [0.0, 0.0, 0.0]
            cu = sum(u.x for u in uvs) / len(uvs)
            cv = sum(u.y for u in uvs) / len(uvs)
            samples = list(uvs) + [Vector((cu, cv))]
            for u in samples:
                r, g, b = sample_uv(u.x, u.y)
                acc[0] += r; acc[1] += g; acc[2] += b
            n = len(samples)
            avg = (acc[0] / n, acc[1] / n, acc[2] / n)
            lab = linear_to_oklab(*avg)
            name = min(palette, key=lambda p: (
                (wl * (lab[0] - p[2][0])) ** 2
                + (lab[1] - p[2][1]) ** 2
                + (lab[2] - p[2][2]) ** 2))[0]
            labels.append(name)
            avgs.append(avg)
            hfs.append((poly.center.z - zmin0) / zspan)
        smooth_changes = smooth_face_labels(me, labels, args.smooth)
        pal_by_name = {p[0]: p for p in palette}
        rule_changes = []
        if args.rules:
            for rn in palette_all:
                if rn not in pal_by_name:
                    h = palette_all[rn].lstrip("#")
                    srgb = tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
                    lin = tuple(srgb_to_linear(c) for c in srgb)
                    pal_by_name[rn] = (rn, lin, linear_to_oklab(*lin), None)
            xs0 = [v.co.x for v in me.vertices]
            ys0 = [v.co.y for v in me.vertices]
            ax = (min(xs0) + max(xs0)) / 2.0
            ay = (min(ys0) + max(ys0)) / 2.0
            rmax = max(math.hypot(v.co.x - ax, v.co.y - ay) for v in me.vertices) or 1.0
            for rule in args.rules:
                rname = rule.get("color")
                where = rule.get("where", {})
                if rname not in pal_by_name:
                    sys.exit(f"flatten_glb: rule color '{rname}' not in palette")
                changed = 0
                for i, poly in enumerate(me.polygons):
                    c = poly.center
                    rad = math.hypot(c.x - ax, c.y - ay) / rmax
                    hf_i, ny = hfs[i], poly.normal.z
                    if ("height_min" in where and hf_i < where["height_min"]) or \
                       ("height_max" in where and hf_i > where["height_max"]) or \
                       ("radial_min" in where and rad < where["radial_min"]) or \
                       ("radial_max" in where and rad > where["radial_max"]) or \
                       ("normal_y_min" in where and ny < where["normal_y_min"]):
                        continue
                    if labels[i] != rname:
                        labels[i] = rname
                        changed += 1
                rule_changes.append((rname, where, changed))
        counts = {n: 0 for n, _, _, _ in palette}
        hrange = {n: [1.0, 0.0] for n, _, _, _ in palette}
        for i, poly in enumerate(me.polygons):
            name, hf, avg = labels[i], hfs[i], avgs[i]
            col = pal_by_name[name][1]
            counts[name] = counts.get(name, 0) + 1
            lo_hi = hrange.setdefault(name, [1.0, 0.0])
            lo_hi[0] = min(lo_hi[0], hf)
            lo_hi[1] = max(lo_hi[1], hf)
            assigned.append((name, hf, avg))
            for li in poly.loop_indices:
                ca.data[li].color = (col[0], col[1], col[2], 1.0)
        for layer in list(me.uv_layers):
            me.uv_layers.remove(layer)
        rebuild_material(me, "face", attr_name="Color")
        for i in list(bpy.data.images):
            bpy.data.images.remove(i)
    else:
        if uvl is None:
            sys.exit("flatten_glb: mesh has no UV layer (texture mode needs UVs)")
        psrgb = np.array([p[3] for p in palette], dtype=np.uint8)
        plab = np.array([p[2] for p in palette], dtype=np.float32)
        idx, rgb, nw, nh = quantize_image(img, psrgb, plab, args.tex_size,
                                          args.lightness_weight, args.despeckle)
        mask = uv_island_mask(me, uvl, nw, nh)
        covered = int(mask.sum())
        hist = {n: int(((idx == k) & mask).sum()) for k, (n, _, _, _) in enumerate(palette)}
        fd, tmp = tempfile.mkstemp(suffix=".png", prefix="palette_tex_")
        os.close(fd)
        with open(tmp, "wb") as f:
            f.write(png_bytes(nw, nh, rgb.tobytes()))
        new_img = bpy.data.images.load(tmp)
        new_img.name = "palette_tex"
        new_img.pack()
        os.remove(tmp)
        rebuild_material(me, "texture", tex_image=new_img)
        for i in list(bpy.data.images):
            if i != new_img:
                bpy.data.images.remove(i)

    for poly in me.polygons:
        poly.use_smooth = False
    fit_to_height(me, args.height)

    kw = dict(filepath=args.out, export_format="GLB", export_yup=True,
              export_apply=True, export_animations=False, export_skins=False,
              export_cameras=False, export_lights=False)
    if args.mode == "face":
        kw.update(export_image_format="NONE", export_materials="EXPORT",
                  export_vertex_color="ACTIVE")
    else:
        kw.update(export_image_format="AUTO", export_materials="EXPORT",
                  export_vertex_color="NONE", export_texcoords=True)
    bpy.ops.export_scene.gltf(**kw)

    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    size = os.path.getsize(args.out)
    print("=== flatten_glb summary ===")
    print(f"mode: {args.mode}")
    print(f"tris: {len(me.polygons)}")
    if args.mode == "face":
        print(f"lightness_weight={args.lightness_weight}, smooth={args.smooth} "
              f"(changed per pass: {', '.join(str(c) for c in smooth_changes)})")
        for rname, where, ch in rule_changes:
            print(f"  rule -> {rname} {where}: {ch} faces changed")
        for nme, cnt in counts.items():
            if cnt:
                lo, hi = hrange[nme]
                above = sum(1 for a in assigned if a[0] == nme and a[1] > 0.25)
                print(f"  {nme}: {cnt} faces ({100.0 * cnt / len(me.polygons):.1f}%), "
                      f"centroid height range {lo:.2f}-{hi:.2f}, "
                      f"{above} above 0.25 ({100.0 * above / len(assigned):.1f}%)")
    else:
        print(f"texture: {w0}x{h0} -> {nw}x{nh}px, despeckle={args.despeckle}, "
              f"lightness_weight={args.lightness_weight}")
        print(f"UV-covered texels: {covered} / {nw * nh} ({100.0 * covered / (nw * nh):.1f}%)")
        for nme, _, _, _ in palette:
            c = hist[nme]
            print(f"  {nme}: {c} px ({100.0 * c / max(1, covered):.1f}% of covered)")
    print(f"bounds: x[{min(xs):.3f},{max(xs):.3f}] y(horizontal)[{min(ys):.3f},{max(ys):.3f}] "
          f"up[{min(zs):.3f},{max(zs):.3f}]  (up = glTF +Y)")
    print(f"out: {args.out} ({size} bytes)")
    if args.mode == "face":
        dark = [n for n, lin, _, _ in sorted(palette, key=lambda p: p[2][0])[:1]]
        for dn in dark:
            bad = [a for a in assigned if a[0] == dn and a[1] > 0.25]
            if bad:
                def lin_to_srgb_hex(c):
                    out = []
                    for v in c:
                        s = 12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055
                        out.append(max(0, min(255, round(s * 255))))
                    return "#%02X%02X%02X" % tuple(out)
                sample = [f"hf={b[1]:.2f} {lin_to_srgb_hex(b[2])}"
                          for b in bad[::max(1, len(bad) // 8)][:8]]
                print(f"  diagnostic: {dn} faces above 0.25 = {len(bad)}; sampled avg colors: "
                      + ", ".join(sample))


main()
