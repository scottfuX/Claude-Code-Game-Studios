#!/usr/bin/env python3
"""Minimal GLB inspector (stdlib only): attributes, bounds, colors, textures."""
import json
import struct
import sys

CT = {5120: ('b', 1), 5121: ('B', 1), 5122: ('h', 2), 5123: ('H', 2), 5125: ('I', 4), 5126: ('f', 4)}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def load(path):
    d = open(path, "rb").read()
    magic, _ver, length = struct.unpack("<III", d[:12])
    assert magic == 0x46546C67, "not a GLB"
    off, gltf, binc = 12, None, b""
    while off < length:
        clen, ctype = struct.unpack("<II", d[off:off + 8]); off += 8
        chunk = d[off:off + clen]; off += clen
        if ctype == 0x4E4F534A:
            gltf = json.loads(chunk)
        elif ctype == 0x004E4942:
            binc = chunk
    return gltf, binc, len(d)


def read_accessor(gltf, binc, idx):
    a = gltf["accessors"][idx]
    bv = gltf["bufferViews"][a["bufferView"]]
    fmt, sz = CT[a["componentType"]]
    n = NC[a["type"]]
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = bv.get("byteStride") or sz * n
    out = []
    for i in range(a["count"]):
        o = start + i * stride
        out.append(struct.unpack_from("<" + fmt * n, binc, o))
    return out


def main(path):
    gltf, binc, total = load(path)
    print(f"file: {path} ({total} bytes)")
    print(f"images: {len(gltf.get('images', []))}  textures: {len(gltf.get('textures', []))}  "
          f"materials: {len(gltf.get('materials', []))}  meshes: {len(gltf.get('meshes', []))}")
    for m in gltf.get("materials", []):
        pbr = m.get("pbrMetallicRoughness", {})
        print(f"  material '{m.get('name')}': baseColorTexture={'baseColorTexture' in pbr} "
              f"KHR_vertex={m.get('extensions', {}).keys() and list(m['extensions'])}")
    for mi, m in enumerate(gltf.get("meshes", [])):
        for pi, p in enumerate(m["primitives"]):
            attrs = p["attributes"]
            tris = gltf["accessors"][p["indices"]]["count"] // 3 if "indices" in p else "?"
            print(f"mesh{mi} prim{pi}: attrs={list(attrs)} indices_tris={tris} material={p.get('material')}")
            pos = read_accessor(gltf, binc, attrs["POSITION"])
            for ax, name in enumerate("XYZ"):
                vals = [v[ax] for v in pos]
                print(f"  POSITION.{name}: [{min(vals):.4f}, {max(vals):.4f}]")
            if "COLOR_0" in attrs:
                acc = gltf["accessors"][attrs["COLOR_0"]]
                cols = read_accessor(gltf, binc, attrs["COLOR_0"])
                uniq = {}
                for c in cols:
                    key = tuple(round(v, 4) for v in c)
                    uniq[key] = uniq.get(key, 0) + 1
                print(f"  COLOR_0: componentType={acc['componentType']} type={acc['type']} "
                      f"count={acc['count']} unique={len(uniq)}")
                for k, v in sorted(uniq.items(), key=lambda kv: -kv[1]):
                    print(f"    {k} x{v}")


if __name__ == "__main__":
    main(sys.argv[1])
