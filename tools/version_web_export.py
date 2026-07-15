#!/usr/bin/env python3
"""Give every Godot web export unique engine and pack filenames.

GitHub Pages and Chromium may cache index.pck independently from index.html. Without
versioned filenames, a fresh shell can boot an older game package. This script renames
the exported runtime files and rewrites Godot's generated configuration accordingly.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(message)


def main() -> None:
    if len(sys.argv) != 3:
        fail("usage: version_web_export.py <build-directory> <build-token>")

    build_dir = Path(sys.argv[1]).resolve()
    token = re.sub(r"[^A-Za-z0-9_-]", "", sys.argv[2])[:16]
    if not token:
        fail("build token is empty after sanitizing")

    html_path = build_dir / "index.html"
    if not html_path.is_file():
        fail(f"missing exported HTML: {html_path}")

    base = f"index.{token}"
    rename_pairs = {
        "index.js": f"{base}.js",
        "index.wasm": f"{base}.wasm",
        "index.pck": f"{base}.pck",
        "index.audio.worklet.js": f"{base}.audio.worklet.js",
    }

    for old_name, new_name in rename_pairs.items():
        old_path = build_dir / old_name
        new_path = build_dir / new_name
        if not old_path.is_file():
            fail(f"missing exported runtime file: {old_path}")
        if new_path.exists():
            new_path.unlink()
        old_path.rename(new_path)

    html = html_path.read_text(encoding="utf-8")
    html = html.replace('src="index.js"', f'src="{base}.js"')
    html = html.replace("__MOONGOONS_BUILD_TOKEN__", token)

    pattern = re.compile(r"const engine = new Engine\((\{[^\n]+\})\);")
    match = pattern.search(html)
    if match is None:
        fail("could not locate Godot engine configuration in exported HTML")

    config = json.loads(match.group(1))
    original_sizes = dict(config.get("fileSizes", {}))
    pck_size = int(original_sizes.get("index.pck", (build_dir / f"{base}.pck").stat().st_size))
    wasm_size = int(original_sizes.get("index.wasm", (build_dir / f"{base}.wasm").stat().st_size))
    config["executable"] = base
    config["mainPack"] = f"{base}.pck"
    config["args"] = ["res://scenes/SyndicateEntry.tscn"]
    config["fileSizes"] = {
        f"{base}.pck": pck_size,
        f"{base}.wasm": wasm_size,
    }
    replacement = f"const engine = new Engine({json.dumps(config, separators=(',', ':'))});"
    html = html[: match.start()] + replacement + html[match.end() :]
    html_path.write_text(html, encoding="utf-8")

    required_files = [
        html_path,
        build_dir / f"{base}.js",
        build_dir / f"{base}.wasm",
        build_dir / f"{base}.pck",
        build_dir / f"{base}.audio.worklet.js",
    ]
    for required in required_files:
        if not required.is_file():
            fail(f"versioned export file was not created: {required}")

    if '"executable":"index"' in html or '"index.pck"' in html or '"index.wasm"' in html:
        fail("export HTML still contains unversioned Godot runtime references")

    print(f"Versioned Godot web export with token {token}")


if __name__ == "__main__":
    main()
