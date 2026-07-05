#!/usr/bin/env python3
"""Check local Markdown links without requiring network access."""

from __future__ import annotations

import re
import sys
from pathlib import Path

LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")


def markdown_files(paths: list[str]) -> list[Path]:
    if not paths:
        paths = ["README.md", "Claude Code OKF Kit Guide.md", "CLAUDE.md", "docs"]

    files: list[Path] = []
    for item in paths:
        path = Path(item)
        if path.is_dir():
            files.extend(sorted(path.rglob("*.md")))
        elif path.suffix == ".md":
            files.append(path)
    return sorted(dict.fromkeys(files))


def strip_title(target: str) -> str:
    target = target.strip()
    if target.startswith("<") and ">" in target:
        return target[1 : target.index(">")]
    if " " in target:
        return target.split(None, 1)[0]
    return target


def iter_links(path: Path):
    in_fence = False
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for match in LINK_RE.finditer(line):
            yield lineno, strip_title(match.group(1))


def should_skip(target: str) -> bool:
    return (
        not target
        or target.startswith("#")
        or target.startswith("?")
        or target.startswith("//")
        or SCHEME_RE.match(target) is not None
    )


def main() -> int:
    root = Path.cwd()
    failures: list[str] = []

    for md in markdown_files(sys.argv[1:]):
        for lineno, target in iter_links(md):
            if should_skip(target):
                continue
            file_part = target.split("#", 1)[0]
            if not file_part:
                continue
            resolved = (root / file_part.lstrip("/")) if file_part.startswith("/") else (md.parent / file_part)
            if not resolved.exists():
                failures.append(f"{md}:{lineno}: missing local link target: {target}")

    if failures:
        print("Broken Markdown links found:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
