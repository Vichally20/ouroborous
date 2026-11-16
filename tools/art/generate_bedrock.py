"""Generate game art from tools/art/manifest.json with Amazon Bedrock (Stability AI).

Characters, creatures, scenes and items use Stability's Style Guide model with
assets/images/vitruvian.jpg as the style reference, so every image shares the
engraved-ink look. Maps use Stable Image Ultra (text only, vellum style).

Setup (once):
    pip install boto3 pillow
    # AWS credentials with bedrock:InvokeModel in us-west-2 (default profile, or --profile)

Examples:
    python tools/art/generate_bedrock.py --priority P0 --dry-run
    python tools/art/generate_bedrock.py --ids cultist_acolyte
    python tools/art/generate_bedrock.py --priority P0 --candidates 2
    python tools/art/generate_bedrock.py --ids flesh_construct --variants   # hurt/attack frames from the saved idle
    python tools/art/generate_bedrock.py --ids cultist_acolyte --force      # replace an existing file

Raw generations are kept in tools/art/out/ (git-ignored) with their seeds in
tools/art/out/log.jsonl, so a good result can be reproduced.
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import random
import sys
import time
from pathlib import Path

try:
    import boto3
    from botocore.config import Config
    from botocore.exceptions import ClientError
except ImportError:  # pragma: no cover
    sys.exit("boto3 is missing: pip install boto3 pillow")
from PIL import Image, ImageEnhance, ImageOps

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "tools" / "art" / "manifest.json"
OUT = ROOT / "tools" / "art" / "out"

STYLE_GUIDE = "us.stability.stable-image-style-guide-v1:0"
ULTRA = "stability.stable-image-ultra-v1:1"
SD35 = "stability.sd3-5-large-v1:0"

ASPECT = {"1024x1536": "2:3", "1024x1792": "9:16", "1792x1024": "16:9", "512x512": "1:1"}
STYLE_REF = {"ink": ROOT / "assets" / "images" / "vitruvian.jpg"}


def b64_image(path: Path, max_side: int = 1024) -> str:
    im = Image.open(path).convert("RGB")
    im.thumbnail((max_side, max_side))
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=90)
    return base64.b64encode(buf.getvalue()).decode()


def invoke(client, model_id: str, body: dict, retries: int = 5) -> tuple[bytes, int | None]:
    for attempt in range(retries):
        try:
            resp = client.invoke_model(
                modelId=model_id,
                contentType="application/json",
                accept="application/json",
                body=json.dumps(body),
            )
            data = json.loads(resp["body"].read())
            reason = (data.get("finish_reasons") or [None])[0]
            if reason:
                raise RuntimeError(f"generation stopped: {reason}")
            seed = (data.get("seeds") or [None])[0]
            return base64.b64decode(data["images"][0]), seed
        except ClientError as e:
            code = e.response.get("Error", {}).get("Code", "")
            if code in ("ThrottlingException", "ServiceUnavailableException", "ModelNotReadyException") and attempt < retries - 1:
                wait = 2 ** attempt + random.random()
                print(f"    {code}, retrying in {wait:.1f}s")
                time.sleep(wait)
                continue
            raise
    raise RuntimeError("unreachable")


TRIM = {"portrait": 0.08, "creature": 0.08, "scene": 0.07, "item": 0.10, "icon": 0.04, "map": 0.0}
GAMMA = {"scene": 1.9, "portrait": 1.15, "creature": 1.15, "item": 1.1, "icon": 1.1, "map": 1.0}


VOID = (5, 5, 5)


def _trim_box(size: tuple[int, int], kind: str) -> tuple[int, int, int, int] | None:
    t = TRIM.get(kind, 0.0)
    if not t:
        return None
    w0, h0 = size
    return (int(w0 * t), int(h0 * t), int(w0 * (1 - t)), int(h0 * (1 - t * 1.4)))


def _fade_edges(im: Image.Image, top: float = 0.22, bottom: float = 0.28) -> Image.Image:
    """Darken the top and bottom bands toward void so UI text can sit there."""
    w, h = im.size
    mask = Image.new("L", (1, h))
    for y in range(h):
        f = y / h
        if f < top:
            v = f / top
        elif f > 1 - bottom:
            v = (1 - f) / bottom
        else:
            v = 1.0
        mask.putpixel((0, y), int(255 * (v ** 1.4)))
    return Image.composite(im, Image.new("RGB", (w, h), VOID), mask.resize((w, h)))


def finish(raw: bytes, asset: dict, cut: bytes | None = None) -> Image.Image:
    """Trim the printed-plate margin, then either colour-finish or invert, and size to the manifest."""
    im = Image.open(io.BytesIO(raw)).convert("RGB")
    # Models like to draw a plate border with a caption under it; cut the outer band (a little more at the bottom).
    box = _trim_box(im.size, asset["kind"])
    if box:
        im = im.crop(box)
    w, h = (int(x) for x in asset["size"].split("x"))

    if PALETTE == "colour" and asset.get("style") == "ink":
        if asset["kind"] == "scene":
            # Keep the hand-colouring, pull it down to a candlelit key so bone UI text stays readable.
            im = ImageEnhance.Color(im).enhance(1.2)
            im = ImageEnhance.Brightness(im).enhance(0.55)
            im = _fade_edges(ImageOps.fit(im, (w, h), Image.LANCZOS, centering=(0.5, 0.45)))
            return im
        if cut is not None:
            # Background removed by Bedrock: place the figure on void black.
            fg = Image.open(io.BytesIO(cut)).convert("RGBA")
            if box:
                fg = fg.crop(_trim_box(fg.size, asset["kind"]))
            ground = Image.new("RGBA", fg.size, VOID + (255,))
            im = Image.alpha_composite(ground, fg).convert("RGB")
        else:
            # Fallback: key out bright, unsaturated paper (keep = not paper).
            _, s, v = im.convert("HSV").split()
            bright = Image.eval(v, lambda x: 255 if x > 225 else 0)
            grey = Image.eval(s, lambda x: 255 if x < 40 else 0)
            paper = Image.composite(grey, Image.new("L", im.size, 0), bright)
            im = Image.composite(Image.new("RGB", im.size, VOID), im, paper)
        return ImageOps.fit(im, (w, h), Image.LANCZOS, centering=(0.5, 0.45))

    if inverted(asset) and asset["kind"] == "scene":
        # Scenes stay positive: black ink on dim umber paper, like a print seen by candlelight.
        # Brightest value is #5A4A3A, so bone UI text keeps ~5:1 contrast on top.
        g = ImageOps.autocontrast(im.convert("L"), cutoff=1)
        im = ImageOps.colorize(g, black="#050505", white="#5A4A3A")
    elif inverted(asset):
        # Black-on-paper -> bone-on-void. Paper becomes pure ground.
        g = ImageOps.invert(im.convert("L"))
        gamma = GAMMA.get(asset["kind"], 1.0)
        lut = []
        for v in range(256):
            x = 0.0 if v < 30 else min(1.0, (v - 30) / 200)
            lut.append(int(255 * x ** gamma))
        im = ImageOps.colorize(g.point(lut), black="#050505", white="#D4CFC7")
    return ImageOps.fit(im, (w, h), Image.LANCZOS, centering=(0.5, 0.45))


def save(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.suffix == ".webp":
        im.save(path, "WEBP", quality=82, method=6)
    elif path.suffix in (".jpg", ".jpeg"):
        im.save(path, "JPEG", quality=88, optimize=True)
    else:
        im.save(path, "PNG", optimize=True)


# Image models draw engravings far better as black ink on white paper. For the "ink" style we
# ask for that, then invert and tint in finish() to get bone-white lines on void black.
PAPER_ENGRAVING = (
    "antique copperplate engraving, black ink line art with dense cross-hatching and stippling on plain white paper, "
    "monochrome, no colour, in the manner of Gustave Dore and the anatomical plates of Vesalius's Fabrica, "
    "dramatic light from the upper left, crisp fine lines, the figure alone with no border"
)
PAPER_NEGATIVE = "colour, painting, watercolour, gradient shading, photograph, 3d render, sepia wash, grey background, plate border, page margin, ruled frame, caption, title, book page, plate number"

# "colour" palette: hand-coloured engravings (watercolour washes over engraved line), like antique tinted plates.
PAPER_ENGRAVING_COLOUR = (
    "antique hand-coloured copperplate engraving, fine black ink cross-hatching with rich translucent watercolour washes "
    "in deep crimson, ochre, verdigris green, lapis blue and burnished gold, vivid but aged pigments, "
    "in the manner of Gustave Dore and eighteenth-century hand-tinted natural history plates, "
    "dramatic light from the upper left, crisp fine lines, the figure alone on plain white paper with no border"
)
PAPER_NEGATIVE_COLOUR = (
    "photograph, 3d render, smooth digital painting, airbrushed, neon, monochrome, black and white, greyscale, "
    "plate border, page margin, ruled frame, caption, title, book page, plate number"
)

PALETTE = "colour"  # set from --palette


def inverted(asset: dict) -> bool:
    return asset.get("style", "ink") == "ink" and PALETTE == "ink"


def build_prompt(asset: dict, manifest: dict, style_first: bool) -> str:
    """Text-only models need the style up front; Style Guide needs the subject up front or it copies the reference."""
    frame = manifest["framing"][asset["kind"]]["text"].replace("pure black background", "plain white paper background")
    frame = frame.replace("near-black", "plain paper")
    if PALETTE == "colour" and asset.get("style") == "ink":
        # Subject first and a short style tail: a long colour preamble drowns the subject.
        if asset["kind"] == "scene":
            frame = "vertical establishing view of the place, deep perspective, no people unless described"
            ground = "full-bleed scene"
        else:
            ground = "isolated on plain white paper, no border"
        return (f"Hand-coloured antique engraving of {asset['subject']}. {frame}. "
                f"Fine black ink cross-hatching with watercolour washes of crimson, ochre, verdigris, lapis blue and gold, "
                f"in the manner of Gustave Dore, {ground}.")
    style = PAPER_ENGRAVING if inverted(asset) else manifest["styles"][asset["style"]]
    subject = asset["subject"].replace("dried-blood crimson", "dark").replace("crimson", "dark")
    if style_first:
        return f"{style}. An engraved illustration of {subject}. {frame}."
    return f"{subject}. {frame}. Rendered as: {style}"


def negative(asset: dict) -> str:
    neg = asset["negative"]
    if asset["kind"] == "map":
        # Asked for "a world map", models draw Earth and letter it.
        neg += (", map of Earth, real-world continents, Americas, Africa, Europe, Asia, Australia, "
                "place names, lettering, cartouche with text, legend, scale bar")
    if PALETTE == "colour" and asset.get("style") == "ink":
        neg = neg.replace("full colour, saturated colours, ", "")
        return f"{neg}, {PAPER_NEGATIVE_COLOUR}"
    return f"{neg}, {PAPER_NEGATIVE}" if inverted(asset) else neg


REMOVE_BG = "us.stability.stable-image-remove-background-v1:0"


def needs_cut(asset: dict) -> bool:
    return PALETTE == "colour" and asset.get("style") == "ink" and asset["kind"] in ("portrait", "creature", "item", "icon")


def cut_out(client, raw: bytes) -> bytes:
    data, _ = invoke(client, REMOVE_BG, {"image": base64.b64encode(raw).decode(), "output_format": "png"})
    return data


def base_body(asset: dict, seed: int, manifest: dict, fidelity: float, model_choice: str,
              init_image: Path | None = None, strength: float = 0.7) -> tuple[str, dict]:
    aspect = ASPECT[asset["size"]]
    if init_image is not None:
        # Repaint an existing image in the house style but keep its layout (maps: markers stay on land).
        return SD35, {
            "prompt": build_prompt(asset, manifest, style_first=True),
            "negative_prompt": negative(asset),
            "mode": "image-to-image",
            "image": b64_image(init_image),
            "strength": strength,
            "seed": seed,
            "output_format": "png",
        }
    ref = STYLE_REF.get(asset.get("style", "ink")) if model_choice == "style-guide" else None
    if ref is not None:
        return STYLE_GUIDE, {
            "image": b64_image(ref),
            "prompt": build_prompt(asset, manifest, style_first=False),
            "negative_prompt": negative(asset) + ", skeleton anatomy chart, ecorche figure, circle diagram",
            "aspect_ratio": aspect,
            "fidelity": fidelity,
            "seed": seed,
            "output_format": "png",
        }
    body = {
        "prompt": build_prompt(asset, manifest, style_first=True),
        "negative_prompt": negative(asset),
        "aspect_ratio": aspect,
        "seed": seed,
        "output_format": "png",
    }
    if model_choice == "sd35":
        body["mode"] = "text-to-image"
        return SD35, body
    return ULTRA, body


def log(entry: dict) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / "log.jsonl", "a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--priority", choices=["P0", "P1", "P2"], help="generate every asset at this priority")
    ap.add_argument("--ids", nargs="+", help="generate these manifest ids")
    ap.add_argument("--candidates", type=int, default=1, help="images per asset; the first is installed, the rest kept in tools/art/out")
    ap.add_argument("--variants", action="store_true", help="make hurt/attack frames from the installed idle image (SD3.5 image-to-image)")
    ap.add_argument("--force", action="store_true", help="overwrite files that already exist")
    ap.add_argument("--dry-run", action="store_true", help="list what would be generated and stop")
    ap.add_argument("--refinish", action="store_true",
                    help="no model calls: re-run post-processing on the most recent raw image for each asset (or --seed)")
    ap.add_argument("--seed", type=int, help="with --refinish and one --ids: use the raw image with this seed")
    ap.add_argument("--model", choices=["ultra", "sd35", "style-guide"], default="ultra",
                    help="ultra (default) and sd35 draw ink-on-paper, then the script inverts it; style-guide uses vitruvian.jpg as a reference but tends to paint")
    ap.add_argument("--fidelity", type=float, default=0.2,
                    help="how strongly the style reference is followed (0-1); above ~0.3 it starts copying the reference's subject")
    ap.add_argument("--region", default="us-west-2")
    ap.add_argument("--profile")
    ap.add_argument("--from-image", help="repaint this image (SD3.5 image-to-image) instead of generating from text; keeps its layout")
    ap.add_argument("--strength", type=float, default=0.7, help="with --from-image: 0 keeps the source, 1 ignores it")
    ap.add_argument("--palette", choices=["colour", "ink"], default="colour",
                    help="colour (default): hand-coloured engravings, figures cut out onto black; ink: bone-on-black monochrome")
    args = ap.parse_args()
    if not args.priority and not args.ids:
        ap.error("pass --priority or --ids")
    global PALETTE
    PALETTE = args.palette

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    assets = [a for a in manifest["assets"] if a.get("prompt")]
    if args.ids:
        unknown = set(args.ids) - {a["id"] for a in assets}
        if unknown:
            sys.exit(f"unknown or non-generated ids: {', '.join(sorted(unknown))}")
        assets = [a for a in assets if a["id"] in args.ids]
    if args.priority:
        assets = [a for a in assets if a["priority"] == args.priority]

    if args.refinish:
        latest, palette_of = {}, {}
        if (OUT / "log.jsonl").exists():
            for line in (OUT / "log.jsonl").read_text(encoding="utf-8").splitlines():
                e = json.loads(line)
                if e.get("kind") == "base":
                    latest[e["id"]] = e["seed"]
                    palette_of[e["seed"]] = e.get("palette", "ink")  # entries before --palette existed were ink
        for a in assets:
            seed = args.seed if args.seed else latest.get(a["id"])
            raw = OUT / a["id"] / f"{a['id']}_{seed}.png"
            if not seed or not raw.exists():
                print(f"  skip {a['id']}: no raw image")
                continue
            PALETTE = palette_of.get(seed, args.palette)
            cut_file = OUT / a["id"] / f"{a['id']}_{seed}_cut.png"
            cut = cut_file.read_bytes() if cut_file.exists() else None
            save(finish(raw.read_bytes(), a, cut), ROOT / a["file"])
            print(f"  refinished {a['file']} from seed {seed} ({PALETTE})")
        return

    jobs = []
    for a in assets:
        target = ROOT / a["file"]
        if args.variants:
            for v in a.get("variants", []):
                name = v.split(":")[0]
                vt = target.with_name(f"{target.stem}_{name}{target.suffix}")
                if args.force or not vt.exists():
                    jobs.append(("variant", a, vt, v))
        elif args.force or not target.exists():
            jobs.append(("base", a, target, None))

    calls = len(jobs) * (args.candidates if not args.variants else 1)
    print(f"{len(jobs)} file(s), {calls} model call(s), region {args.region}")
    for kind, a, target, v in jobs:
        print(f"  {kind:7} {a['id']:24} -> {target.relative_to(ROOT).as_posix()}")
    if args.dry_run or not jobs:
        return

    session = boto3.Session(profile_name=args.profile, region_name=args.region)
    client = session.client("bedrock-runtime", config=Config(read_timeout=300, retries={"max_attempts": 1}))

    failures = []
    for kind, a, target, v in jobs:
        print(f"\n{a['id']} ({kind})")
        try:
            if kind == "variant":
                idle = ROOT / a["file"]
                if not idle.exists():
                    raise RuntimeError(f"generate the idle first: {a['file']}")
                desc = v.split(":", 1)[1].split("(")[0].strip()
                seed = random.randrange(1, 4_294_967_294)
                body = {
                    "prompt": f"{manifest['styles'][a['style']]}. {desc}. Same creature, same design, same lighting.",
                    "negative_prompt": a["negative"],
                    "mode": "image-to-image",
                    "image": b64_image(idle),
                    "strength": 0.55,
                    "seed": seed,
                    "output_format": "png",
                }
                raw, seed = invoke(client, SD35, body)
                (OUT / a["id"]).mkdir(parents=True, exist_ok=True)
                (OUT / a["id"] / f"{target.stem}_{seed}.png").write_bytes(raw)
                save(finish(raw, a), target)
                log({"id": a["id"], "kind": kind, "model": SD35, "seed": seed, "file": a["file"], "variant": v})
                print(f"    saved {target.relative_to(ROOT).as_posix()} (seed {seed})")
                continue

            for i in range(args.candidates):
                seed = random.randrange(1, 4_294_967_294)
                init = Path(args.from_image).resolve() if args.from_image else None
                model, body = base_body(a, seed, manifest, args.fidelity, args.model, init, args.strength)
                raw, seed = invoke(client, model, body)
                (OUT / a["id"]).mkdir(parents=True, exist_ok=True)
                (OUT / a["id"] / f"{a['id']}_{seed}.png").write_bytes(raw)
                cut = None
                if needs_cut(a):
                    cut = cut_out(client, raw)
                    (OUT / a["id"] / f"{a['id']}_{seed}_cut.png").write_bytes(cut)
                log({"id": a["id"], "kind": kind, "model": model, "seed": seed, "file": a["file"], "palette": PALETTE})
                if i == 0:
                    save(finish(raw, a, cut), target)
                    print(f"    saved {target.relative_to(ROOT).as_posix()} (seed {seed})")
                else:
                    print(f"    candidate kept in tools/art/out/{a['id']}/ (seed {seed})")
        except Exception as e:  # keep going; report at the end
            print(f"    FAILED: {e}")
            failures.append((a["id"], str(e)))

    if failures:
        print(f"\n{len(failures)} failed:")
        for i, e in failures:
            print(f"  {i}: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
