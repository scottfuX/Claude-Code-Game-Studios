# Blender background script: flatten a textured GLB into a flat-shaded,
# palette-quantized, vertex-colored GLB. Run:
#   Blender --background --python tools/assets/flatten_glb.py -- \
#     --in RAW.glb --out FLAT.glb --palette tools/assets/palette.json \
#     --colors name1,name2 --height 6.0
#
# Notes for this Blender (5.2.1):
#  - image.pixels returns the raw stored values; for an sRGB PNG that is the
#    sRGB-encoded bytes/255, so we do the sRGB->linear conversion ourselves.
#  - glTF COLOR_0 is linear, so the attribute is written in linear space.
#  - export_vertex_color: MATERIAL|ACTIVE|NAME|NONE (export_colors is gone).
import argparse
import json
import os
import sys

import bpy
from mathutils import Matrix, Vector


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def linear_to_oklab(r, g, b):
    """Oklab (Bjorn Ottosson) from linear sRGB. Perceptual: dark colors stay
    separable, unlike Euclidean distance in linear RGB."""
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_ = l ** (1.0 / 3.0) if l > 0.0 else 0.0
    m_ = m ** (1.0 / 3.0) if m > 0.0 else 0.0
    s_ = s ** (1.0 / 3.0) if s > 0.0 else 0.0
    return (0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
            1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
            0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_)


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", required=True)
    ap.add_argument("--out", dest="out", required=True)
    ap.add_argument("--palette", required=True)
    ap.add_argument("--colors", default=None, help="Comma-separated palette names; default: all.")
    ap.add_argument("--height", type=float, required=True, help="Final height along the up axis.")
    return ap.parse_args(argv)


def main():
    args = parse_args()
    palette_all = json.load(open(args.palette))
    names = args.colors.split(",") if args.colors else list(palette_all.keys())
    palette = []
    for n in names:
        if n not in palette_all:
            sys.exit(f"flatten_glb: palette has no color '{n}'")
        h = palette_all[n].lstrip("#")
        srgb = tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
        lin = tuple(srgb_to_linear(c) for c in srgb)
        palette.append((n, lin, linear_to_oklab(*lin)))

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args.inp)

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
    me = obj.data

    # --- find the base-color texture image -------------------------------
    img = None
    for mat in bpy.data.materials:
        nt = getattr(mat, "node_tree", None)
        if not nt:
            continue
        for node in nt.nodes:
            if node.bl_idname == "ShaderNodeTexImage" and node.image and node.image.size[0] > 0:
                img = node.image
                break
        if img:
            break
    if img is None:
        imgs = [i for i in bpy.data.images if i.size[0] > 0]
        if not imgs:
            sys.exit("flatten_glb: no texture image found to sample")
        img = imgs[0]
    w, h = img.size
    npx = w * h * 4
    try:
        import numpy as np
        buf = np.empty(npx, dtype=np.float32)
        img.pixels.foreach_get(buf)
    except Exception:
        buf = list(img.pixels)

    def sample_uv(u, v):
        """sRGB-encoded texel at wrapped UV -> linear rgb."""
        x = min(int((u % 1.0) * w), w - 1)
        y = min(int((v % 1.0) * h), h - 1)
        i = (y * w + x) * 4
        return (srgb_to_linear(buf[i]), srgb_to_linear(buf[i + 1]), srgb_to_linear(buf[i + 2]))

    # --- per-face palette quantization ------------------------------------
    if not me.uv_layers:
        sys.exit("flatten_glb: mesh has no UV layer to sample")
    uvl = me.uv_layers.active
    ca = me.color_attributes.new(name="Color", type="FLOAT_COLOR", domain="CORNER")
    zmin0 = min(v.co.z for v in me.vertices)
    zspan = max(v.co.z for v in me.vertices) - zmin0 or 1.0
    counts = {n: 0 for n, _, _ in palette}
    hrange = {n: [1.0, 0.0] for n, _, _ in palette}
    assigned = []  # (name, height_fraction, avg linear rgb) per face, for reporting
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
        name, col, _ = min(palette, key=lambda p: sum((a - b) ** 2 for a, b in zip(lab, p[2])))
        hf = (poly.center.z - zmin0) / zspan
        counts[name] += 1
        hrange[name][0] = min(hrange[name][0], hf)
        hrange[name][1] = max(hrange[name][1], hf)
        assigned.append((name, hf, avg))
        for li in poly.loop_indices:
            ca.data[li].color = (col[0], col[1], col[2], 1.0)

    # --- strip UVs/textures, flat shading, single palette material --------
    for layer in list(me.uv_layers):
        me.uv_layers.remove(layer)
    for poly in me.polygons:
        poly.use_smooth = False
    me.materials.clear()
    mat = bpy.data.materials.new("flat_palette")
    try:
        mat.use_nodes = True
    except Exception:
        pass
    nt = mat.node_tree
    nt.nodes.clear()
    out_node = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    vcol = nt.nodes.new("ShaderNodeVertexColor")
    vcol.layer_name = "Color"
    bsdf.inputs["Roughness"].default_value = 1.0
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.0
    nt.links.new(vcol.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs["BSDF"], out_node.inputs["Surface"])
    me.materials.append(mat)
    for i in list(bpy.data.images):
        bpy.data.images.remove(i)

    # --- uniform scale to --height, origin at bottom-center ---------------
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)
    zmin, zmax = min(zs), max(zs)
    height_in = zmax - zmin
    if height_in <= 0:
        sys.exit("flatten_glb: zero height on up axis")
    s = args.height / height_in
    cx, cy = (xmin + xmax) / 2.0, (ymin + ymax) / 2.0
    me.transform(Matrix.Scale(s, 4) @ Matrix.Translation(Vector((-cx, -cy, -zmin))))

    bpy.ops.export_scene.gltf(
        filepath=args.out,
        export_format="GLB",
        export_yup=True,
        export_apply=True,
        export_image_format="NONE",
        export_materials="EXPORT",
        export_vertex_color="ACTIVE",
        export_animations=False,
        export_skins=False,
        export_cameras=False,
        export_lights=False,
    )

    # --- summary ------------------------------------------------------------
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    size = os.path.getsize(args.out)
    print("=== flatten_glb summary ===")
    print(f"tris: {len(me.polygons)}")
    for nme, cnt in counts.items():
        if cnt:
            lo, hi = hrange[nme]
            above = sum(1 for a in assigned if a[0] == nme and a[1] > 0.25)
            print(f"  {nme}: {cnt} faces, centroid height range {lo:.2f}-{hi:.2f}, "
                  f"{above} above 0.25 ({100.0 * above / len(assigned):.1f}%)")
    print(f"bounds: x[{min(xs):.3f},{max(xs):.3f}] y(horizontal)[{min(ys):.3f},{max(ys):.3f}] "
          f"up[{min(zs):.3f},{max(zs):.3f}]  (up = glTF +Y)")
    print(f"out: {args.out} ({size} bytes)")
    # diagnostic for palette-fit review: darkest-name assignments high on the mesh
    dark_names = [n for n, lin, _ in sorted(palette, key=lambda p: p[2][0])[:1]]
    for dn in dark_names:
        bad = [a for a in assigned if a[0] == dn and a[1] > 0.25]
        if bad:
            def lin_to_srgb_hex(c):
                out = []
                for v in c:
                    s = 12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055
                    out.append(max(0, min(255, round(s * 255))))
                return "#%02X%02X%02X" % tuple(out)
            sample = [f"hf={b[1]:.2f} {lin_to_srgb_hex(b[2])}" for b in bad[::max(1, len(bad) // 8)][:8]]
            print(f"  diagnostic: {dn} faces above 0.25 = {len(bad)}; sampled avg colors: "
                  + ", ".join(sample))


main()
