#!/usr/bin/env python3
"""Text-to-image via DashScope chat/completions (qwen-image style endpoints).

Requires env: DASHSCOPE_BASE_URL, DASHSCOPE_API_KEY.
Model: --model, else $QWEN_IMAGE_MODEL, else qwen-image-3.0-pro.
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

TIMEOUT_SEC = 180
DEFAULT_MODEL = "qwen-image-3.0-pro"


def fail(msg, code=1):
    print(f"gen_image: error: {msg}", file=sys.stderr)
    sys.exit(code)


def main():
    ap = argparse.ArgumentParser(description="Generate an image from a text prompt (DashScope chat/completions).")
    ap.add_argument("--prompt", required=True, help="Text prompt.")
    ap.add_argument("--out", required=True, help="Output PNG path.")
    ap.add_argument("--model", default=os.environ.get("QWEN_IMAGE_MODEL") or DEFAULT_MODEL)
    ap.add_argument("--dry-run", action="store_true", help="Print URL + body, no network.")
    args = ap.parse_args()

    base = (os.environ.get("DASHSCOPE_BASE_URL") or "").rstrip("/")
    key = os.environ.get("DASHSCOPE_API_KEY") or ""
    if not base or not key:
        fail("DASHSCOPE_BASE_URL and/or DASHSCOPE_API_KEY is not set")
    url = base + "/chat/completions"

    body = {
        "model": args.model,
        "messages": [{"role": "user", "content": [{"type": "text", "text": args.prompt}]}],
    }

    if args.dry_run:
        print(f"POST {url}")
        print("headers: Authorization: Bearer <DASHSCOPE_API_KEY>, Content-Type: application/json")
        print(json.dumps(body, indent=2))
        return

    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT_SEC) as r:
            resp = json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        detail = ""
        try:
            detail = e.read().decode("utf-8")[:500]
        except Exception:
            pass
        fail(f"HTTP {e.code} from {url}: {detail}")
    except Exception as e:
        fail(f"request to {url} failed: {e}")

    resp_path = args.out + ".resp.json"
    try:
        with open(resp_path, "w", encoding="utf-8") as f:
            json.dump(resp, f, indent=2)
    except OSError as e:
        fail(f"cannot write {resp_path}: {e}")

    img_url = None
    try:
        for item in resp["output"]["choices"][0]["message"]["content"]:
            if item.get("type") == "image" and item.get("image"):
                img_url = item["image"]
                break
    except (KeyError, IndexError, TypeError):
        pass
    if not img_url:
        fail(f"no image URL in response (raw response saved to {resp_path})")

    try:
        with urllib.request.urlopen(img_url, timeout=TIMEOUT_SEC) as r:
            data = r.read()
    except Exception as e:
        fail(f"downloading image failed: {e}")

    try:
        with open(args.out, "wb") as f:
            f.write(data)
    except OSError as e:
        fail(f"cannot write {args.out}: {e}")

    print(f"saved {len(data)} bytes -> {args.out}")
    print(f"response JSON -> {resp_path}")


if __name__ == "__main__":
    main()
