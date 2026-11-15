#!/usr/bin/env python3
"""Image-to-3D via the Hunyuan3D server (/v1/ai3d/submit + /v1/ai3d/query).

Requires env: HY3D_SERVER, HY3D_API_KEY. Model: $HUNYUAN3D_MODEL else "3.0".
Submit body: {"Model", "ImageBase64", "GenerateType", "PolygonType":"triangle"}
(+ "FaceCount" only when --face-count is given and type != LowPoly).

Immediately after submit, writes <out>.job.json with the JobId so a paid job is
never lost if polling crashes. --job-id resumes an existing job at polling.
"""
import argparse
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request

MAX_IMAGE_BYTES = int(4.5 * 1024 * 1024)
POLL_SEC = 10


def fail(msg, code=1):
    print(f"gen_mesh: error: {msg}", file=sys.stderr)
    sys.exit(code)


def post_json(url, body, key, timeout=120):
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={"Authorization": key, "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        detail = ""
        try:
            detail = e.read().decode("utf-8")[:500]
        except Exception:
            pass
        fail(f"HTTP {e.code} from {url}: {detail}")
    except Exception as e:
        fail(f"request to {url} failed: {e}")


def download(url, path, timeout=300):
    try:
        with urllib.request.urlopen(url, timeout=timeout) as r:
            data = r.read()
    except Exception as e:
        fail(f"download failed ({url[:80]}...): {e}")
    try:
        with open(path, "wb") as f:
            f.write(data)
    except OSError as e:
        fail(f"cannot write {path}: {e}")
    return len(data)


def main():
    ap = argparse.ArgumentParser(description="Submit/poll a Hunyuan3D image-to-3D job.")
    ap.add_argument("--image", help="Input image path (required unless --job-id).")
    ap.add_argument("--out", required=True, help="Output GLB path.")
    ap.add_argument("--generate-type", default="LowPoly", choices=["LowPoly", "Normal", "Geometry"])
    ap.add_argument("--face-count", type=int, default=None)
    ap.add_argument("--job-id", default=None, help="Resume an existing job (skips submit).")
    ap.add_argument("--timeout-sec", type=int, default=900)
    ap.add_argument("--dry-run", action="store_true", help="Print URL + body, no network.")
    args = ap.parse_args()

    server = (os.environ.get("HY3D_SERVER") or "").rstrip("/")
    key = os.environ.get("HY3D_API_KEY") or ""
    if not server or not key:
        fail("HY3D_SERVER and/or HY3D_API_KEY is not set")
    model = os.environ.get("HUNYUAN3D_MODEL") or "3.0"
    submit_url = server + "/v1/ai3d/submit"
    query_url = server + "/v1/ai3d/query"

    if not args.job_id:
        if not args.image:
            fail("--image is required unless --job-id is given")
        try:
            img_bytes = open(args.image, "rb").read()
        except OSError as e:
            fail(f"cannot read {args.image}: {e}")
        if len(img_bytes) > MAX_IMAGE_BYTES:
            fail(f"image is {len(img_bytes)} bytes, over the {MAX_IMAGE_BYTES}-byte limit; downscale it first")
        b64 = base64.b64encode(img_bytes).decode("ascii")

        body = {
            "Model": model,
            "ImageBase64": b64,
            "GenerateType": args.generate_type,
            "PolygonType": "triangle",
        }
        if args.face_count is not None and args.generate_type != "LowPoly":
            body["FaceCount"] = args.face_count

        if args.dry_run:
            shown = dict(body)
            shown["ImageBase64"] = f"<{len(b64)} base64 chars>"
            print(f"POST {submit_url}")
            print("headers: Authorization: <HY3D_API_KEY>, Content-Type: application/json")
            print(json.dumps(shown, indent=2))
            print(f"(would then poll POST {query_url} with {{\"JobId\": ...}} every {POLL_SEC}s up to {args.timeout_sec}s)")
            return

        resp = post_json(submit_url, body, key)
        job_id = (resp.get("Response") or {}).get("JobId")
        if not job_id:
            fail(f"submit response has no Response.JobId: {json.dumps(resp)[:500]}")
        job_path = args.out + ".job.json"
        try:
            with open(job_path, "w", encoding="utf-8") as f:
                json.dump({"JobId": job_id, "RequestId": (resp.get("Response") or {}).get("RequestId")}, f, indent=2)
        except OSError as e:
            fail(f"cannot write {job_path}: {e}")
        print(f"submitted JobId={job_id} -> {job_path}")
    else:
        if args.dry_run:
            print(f"POST {query_url}")
            print("headers: Authorization: <HY3D_API_KEY>, Content-Type: application/json")
            print(json.dumps({"JobId": args.job_id}, indent=2))
            return
        job_id = args.job_id
        job_path = args.out + ".job.json"
        try:
            with open(job_path, "w", encoding="utf-8") as f:
                json.dump({"JobId": job_id}, f, indent=2)
        except OSError as e:
            fail(f"cannot write {job_path}: {e}")
        print(f"resuming JobId={job_id} (submit skipped)")

    start = time.time()
    while True:
        elapsed = time.time() - start
        if elapsed > args.timeout_sec:
            fail(f"timed out after {args.timeout_sec}s polling JobId={job_id} (job file: {args.out}.job.json)", code=3)
        resp = post_json(query_url, {"JobId": job_id}, key)
        r = resp.get("Response") or {}
        status = r.get("Status", "?")
        print(f"[{int(elapsed):4d}s] Status={status}")
        if status == "DONE":
            break
        if status == "FAIL":
            fail(f"job failed: {r.get('ErrorMessage') or '(no ErrorMessage)'}", code=2)
        time.sleep(POLL_SEC)

    credits = r.get("ResultCreditConsumed")
    files = r.get("ResultFile3Ds") or []
    glb = next((f for f in files if f.get("Type") == "GLB"), None) or next((f for f in files if f.get("Url")), None)
    if not glb:
        fail(f"DONE but no downloadable file in ResultFile3Ds: {json.dumps(files)[:500]}")
    n = download(glb["Url"], args.out)
    print(f"saved {n} bytes -> {args.out}")
    preview = glb.get("PreviewImageUrl") or next((f.get("PreviewImageUrl") for f in files if f.get("PreviewImageUrl")), None)
    if preview:
        n = download(preview, args.out + ".preview.png")
        print(f"saved {n} bytes -> {args.out}.preview.png")
    if credits is not None:
        print(f"credits consumed: {credits}")


if __name__ == "__main__":
    main()
