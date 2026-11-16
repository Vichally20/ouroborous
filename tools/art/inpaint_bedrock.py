"""Repaint rectangular regions of an image with Amazon Bedrock (Stability inpaint).

Typical use: wipe generated-text cartouches and stray lettering off a map.
Use --erase (Stability Erase Object) for text on plain backgrounds like open sea;
use --prompt (Stability Inpaint) when the region needs new content, e.g. a cartouche
that should become countryside.

    python tools/art/inpaint_bedrock.py assets/images/maps/bowerstone.webp \
        --box 1375,800,1792,1010 --box 0,15,290,95 \
        --prompt "hand-coloured antique map: green fields, trees and river water, fine ink hatching"

Boxes are x0,y0,x1,y1 in the image's own pixels. The original is backed up to
tools/art/out/backups/ before the file is overwritten. Needs boto3 + pillow and
AWS credentials with bedrock:InvokeModel in us-west-2.
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import shutil
import sys
import time
from pathlib import Path

try:
    import boto3
except ImportError:  # pragma: no cover
    sys.exit("boto3 is missing: pip install boto3 pillow")
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
BACKUPS = ROOT / "tools" / "art" / "out" / "backups"
INPAINT = "us.stability.stable-image-inpaint-v1:0"
ERASE = "us.stability.stable-image-erase-object-v1:0"
NEGATIVE = "text, letters, words, writing, captions, labels, numbers, cartouche, scroll banner, signature, watermark"


def b64(im: Image.Image, fmt: str = "PNG") -> str:
    buf = io.BytesIO()
    im.save(buf, fmt)
    return base64.b64encode(buf.getvalue()).decode()


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image", help="image to repair, relative to the repo or absolute")
    ap.add_argument("--box", action="append", required=True, help="x0,y0,x1,y1 region to repaint (repeatable)")
    ap.add_argument("--prompt", help="what should fill the boxes (inpaint mode)")
    ap.add_argument("--erase", action="store_true",
                    help="use Erase Object instead: fills the boxes from their surroundings, no prompt. "
                         "Best for text on plain backgrounds such as open sea")
    ap.add_argument("--grow", type=int, default=12, help="feather the mask edge by this many pixels")
    ap.add_argument("--region", default="us-west-2")
    ap.add_argument("--profile")
    args = ap.parse_args()

    path = Path(args.image)
    if not path.is_absolute():
        path = ROOT / path
    src = Image.open(path).convert("RGB")

    mask = Image.new("L", src.size, 0)
    draw = ImageDraw.Draw(mask)
    for box in args.box:
        x0, y0, x1, y1 = (int(v) for v in box.split(","))
        draw.rectangle([x0, y0, x1, y1], fill=255)
    if args.grow:
        mask = mask.filter(ImageFilter.GaussianBlur(args.grow / 2))

    if args.erase:
        model, body = ERASE, {"image": b64(src), "mask": b64(mask), "grow_mask": min(args.grow, 20), "output_format": "png"}
    else:
        if not args.prompt:
            ap.error("--prompt is required unless --erase is used")
        model, body = INPAINT, {
            "image": b64(src),
            "mask": b64(mask),
            "prompt": args.prompt,
            "negative_prompt": NEGATIVE,
            "grow_mask": min(args.grow, 20),
            "output_format": "png",
        }
    client = boto3.Session(profile_name=args.profile, region_name=args.region).client("bedrock-runtime")
    resp = client.invoke_model(modelId=model, contentType="application/json", accept="application/json", body=json.dumps(body))
    data = json.loads(resp["body"].read())
    reason = (data.get("finish_reasons") or [None])[0]
    if reason:
        sys.exit(f"generation stopped: {reason}")
    out = Image.open(io.BytesIO(base64.b64decode(data["images"][0]))).convert("RGB")
    if out.size != src.size:
        out = out.resize(src.size, Image.LANCZOS)

    BACKUPS.mkdir(parents=True, exist_ok=True)
    backup = BACKUPS / f"{path.stem}_{int(time.time())}{path.suffix}"
    shutil.copy2(path, backup)
    if path.suffix == ".webp":
        out.save(path, "WEBP", quality=82, method=6)
    else:
        out.save(path)
    print(f"repainted {len(args.box)} region(s) in {path.relative_to(ROOT).as_posix()} (backup: {backup.relative_to(ROOT).as_posix()})")


if __name__ == "__main__":
    main()
