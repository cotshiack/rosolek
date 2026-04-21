#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Rosolek" / "Rosolek" / "Assets.xcassets"
HOME_SETS = [
    "HomeHeroCustomBroth.imageset",
    "HomeRecipePoultry.imageset",
    "HomeRecipePoultryBeef.imageset",
    "HomeChefRamen.imageset",
    "HomeChefDemiGlace.imageset",
]


def fail(msg: str) -> None:
    print(f"❌ {msg}")
    sys.exit(1)


def main() -> int:
    if not ASSETS.exists():
        fail(f"Assets folder not found: {ASSETS}")

    for imageset in HOME_SETS:
        folder = ASSETS / imageset
        contents = folder / "Contents.json"

        if not folder.exists():
            fail(f"Missing imageset: {imageset}")
        if not contents.exists():
            fail(f"Missing Contents.json: {contents}")

        data = json.loads(contents.read_text(encoding="utf-8"))
        images = data.get("images", [])
        filenames = [img.get("filename") for img in images if img.get("filename")]

        if len(filenames) != 3:
            fail(f"{imageset}: expected 3 filename entries (1x/2x/3x), got {len(filenames)}")

        unique_names = set(filenames)
        if len(unique_names) != 1:
            fail(f"{imageset}: expected same filename for all scales, got {sorted(unique_names)}")

        file_name = next(iter(unique_names))
        if not file_name.endswith(".png"):
            fail(f"{imageset}: filename must be .png, got {file_name}")

        image_file = folder / file_name
        if not image_file.exists():
            fail(f"{imageset}: referenced file does not exist: {file_name}")

        stem = image_file.stem
        jpg_variant = folder / f"{stem}.jpg"
        jpeg_variant = folder / f"{stem}.jpeg"
        if jpg_variant.exists() or jpeg_variant.exists():
            fail(f"{imageset}: found conflicting jpg/jpeg variant for {stem}")

    print("✅ Home asset validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
