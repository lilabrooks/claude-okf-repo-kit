#!/usr/bin/env python3
"""Parity gate for the source kit: mechanical checks for the sync rules the
specs pin as "must not drift". Run by `make parity`; stdlib only.

Checks:
1. OKF-SHARED blocks (the layout and mirrors awk parsers) are byte-identical
   across every script that carries them, present exactly where expected, and
   never present anywhere the expected-set below does not list.
2. The Stop hook's non-implementation exclusion list equals the union of
   scripts/okf's is_workflow_file and is_meta_file sets (the no-drift rule in
   the claude-hooks and okf-helper-command specs).
3. The skill roster (templates/skills/okf-*/) appears everywhere the docs and
   installers claim it: the README install-artifacts table row, both
   installers (create-new-repo twice: copy plus manifest seed), verify-install,
   and the installer-scripts spec. The Guide lists procedures descriptively,
   not by directory name, so it is deliberately not gated.
4. The installer summary labels pinned by ADR 0023 appear, in the pinned
   order, in the scripts that print them, and every label appears in the
   installer-scripts spec and in ADR 0023.
5. The target-installed surface stays standalone bash (ADR 0026): the two
   hooks and scripts/okf keep bash shebangs and never invoke python3 — the
   mirror contract requires files that work alone in another agent's config.
6. Kit Python floor conventions (ADR 0026 amendment): every scripts/*.py
   file carries `from __future__ import annotations`, which keeps modern
   type annotations legal on the 3.9 floor; the floor itself is enforced by
   the CI floor pass that reruns the suite under Python 3.9.

The audit that motivated this gate found drift exactly where prose was the
only guard (a README table row, an exclusion list two specs said must not
drift) while every smoke-asserted surface was correct. This file converts
those prose rules into build failures.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SHARED_BLOCKS = {
    "layout-awk": [
        "scripts/okf",
        "scripts/check-okf-version.sh",
        "scripts/verify-install",
        "scripts/update-existing-repo",
        "scripts/harvest-dogfood",
    ],
    "mirrors-awk": [
        "scripts/check-okf-version.sh",
        "scripts/verify-install",
        "scripts/update-existing-repo",
        "scripts/harvest-dogfood",
    ],
}

UPDATER_LABELS = [
    "Created:",
    "Updated:",
    "Skipped:",
    "Backed up:",
    "Needs review:",
    "Advisories:",
    "Verification run:",
]
CREATOR_LABELS = ["Created:", "Updated:", "Skipped:", "Verification run:"]

failures: list[str] = []


def fail(message: str) -> None:
    failures.append(message)


def ok(message: str) -> None:
    print(f"  ok: {message}")


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def extract_block(text: str, name: str, rel: str) -> str | None:
    begin = f"# OKF-SHARED-BEGIN {name}"
    end = f"# OKF-SHARED-END {name}"
    starts = [m.start() for m in re.finditer(re.escape(begin), text)]
    if not starts:
        return None
    if len(starts) > 1:
        fail(f"{rel}: multiple OKF-SHARED-BEGIN {name} markers")
        return None
    stop = text.find(end, starts[0])
    if stop == -1:
        fail(f"{rel}: OKF-SHARED-BEGIN {name} has no matching END marker")
        return None
    return text[starts[0] : stop + len(end)]


def check_shared_blocks() -> None:
    all_scripts = sorted(
        p.relative_to(ROOT).as_posix()
        for p in (ROOT / "scripts").iterdir()
        if p.is_file()
    )
    for name, expected in SHARED_BLOCKS.items():
        canonical: str | None = None
        canonical_rel: str | None = None
        for rel in expected:
            block = extract_block(read(rel), name, rel)
            if block is None:
                fail(f"{rel}: missing shared block {name}")
                continue
            if canonical is None:
                canonical, canonical_rel = block, rel
            elif block != canonical:
                fail(
                    f"{rel}: shared block {name} diverges from {canonical_rel}"
                    " (byte-identical copies required)"
                )
        for rel in all_scripts:
            if rel in expected:
                continue
            if f"# OKF-SHARED-BEGIN {name}" in read(rel):
                fail(
                    f"{rel}: carries shared block {name} but is not in the"
                    " checker's expected set; add it to SHARED_BLOCKS"
                )
        ok(f"shared block {name} byte-identical across {len(expected)} scripts")


def case_tokens(text: str, funcname: str) -> list[str]:
    match = re.search(rf"{funcname}\(\)\s*\{{(.*?)\n\}}", text, re.S)
    if not match:
        fail(f"scripts/okf: cannot find function {funcname}")
        return []
    tokens: list[str] = []
    for branch in re.finditer(r"^\s*([^)\n]+)\)\s+return 0 ;;", match.group(1), re.M):
        tokens.extend(t.strip() for t in branch.group(1).split("|"))
    return [t for t in tokens if "$" not in t and t]


def normalize_okf_token(token: str) -> tuple[str, str]:
    if token.endswith("/*"):
        return ("dir", token[:-2])
    return ("file", token)


def normalize_hook_alt(alt: str) -> tuple[str, str]:
    alt = alt.replace("\\.", ".")
    if alt.endswith("/"):
        return ("dir", alt[:-1])
    if alt.endswith("$"):
        return ("file", alt[:-1])
    return ("file", alt)


def check_exclusion_union() -> None:
    okf_text = read("scripts/okf")
    hook_text = read("scripts/check-docs-sync.sh")

    okf_set = {
        normalize_okf_token(t)
        for t in case_tokens(okf_text, "is_workflow_file")
        + case_tokens(okf_text, "is_meta_file")
    }

    pattern = re.search(r"grep -vE '\^\((.*)\)' \\", hook_text)
    if not pattern:
        fail("scripts/check-docs-sync.sh: cannot find the grep -vE exclusion pattern")
        return
    hook_set = {normalize_hook_alt(a) for a in pattern.group(1).split("|")}

    if okf_set != hook_set:
        for entry in sorted(okf_set - hook_set):
            fail(f"exclusion drift: {entry} in scripts/okf but not check-docs-sync.sh")
        for entry in sorted(hook_set - okf_set):
            fail(f"exclusion drift: {entry} in check-docs-sync.sh but not scripts/okf")
        return
    ok(f"exclusion lists match ({len(okf_set)} entries)")


def check_skill_roster() -> None:
    skills = sorted(
        p.name
        for p in (ROOT / "templates" / "skills").iterdir()
        if p.is_dir() and p.name.startswith("okf-")
    )
    if not skills:
        fail("templates/skills: no okf-* skill directories found")
        return

    readme = read("README.md")
    table_rows = [
        line
        for line in readme.splitlines()
        if line.startswith("| `templates/skills/okf-*/SKILL.md`")
    ]
    if len(table_rows) != 1:
        fail("README.md: expected exactly one install-artifacts table row for templates/skills/okf-*/SKILL.md")
        table_rows = [""]

    surfaces = {
        "scripts/create-new-repo": 2,  # copy_created plus seed_manifest
        "scripts/update-existing-repo": 1,
        "scripts/verify-install": 1,
        "docs/specs/installer-scripts.md": 1,
    }
    for skill in skills:
        if skill not in table_rows[0]:
            fail(f"README.md install-artifacts table row does not name {skill}")
        for rel, minimum in surfaces.items():
            count = read(rel).count(skill)
            if count < minimum:
                fail(
                    f"{rel}: names {skill} {count} time(s); expected at least"
                    f" {minimum}"
                )
    ok(f"skill roster ({len(skills)} skills) named on every claimed surface")


def check_summary_labels() -> None:
    updater = read("scripts/update-existing-repo")
    creator = read("scripts/create-new-repo")
    spec = read("docs/specs/installer-scripts.md")
    adr = read("docs/adr/0023-installer-summary-contract.md")

    def label_position(text: str, label: str, rel: str) -> int:
        for needle in (f"print_list '{label}'", f"printf '\\n{label}\\n'"):
            index = text.find(needle)
            if index != -1:
                return index
        fail(f"{rel}: does not print pinned summary label {label}")
        return -1

    for rel, text, labels in (
        ("scripts/update-existing-repo", updater, UPDATER_LABELS),
        ("scripts/create-new-repo", creator, CREATOR_LABELS),
    ):
        positions = [label_position(text, label, rel) for label in labels]
        if -1 not in positions and positions != sorted(positions):
            fail(f"{rel}: summary labels print out of the pinned order")

    for label in UPDATER_LABELS:
        if label not in spec:
            fail(f"docs/specs/installer-scripts.md: missing pinned label {label}")
        if label not in adr:
            fail(f"docs/adr/0023: missing pinned label {label}")
    ok("summary labels present and ordered on every pinned surface")


INSTALLED_SURFACE = [
    "scripts/check-docs-sync.sh",
    "scripts/check-okf-version.sh",
    "scripts/okf",
]


def check_bash_boundary() -> None:
    for rel in INSTALLED_SURFACE:
        text = read(rel)
        if not text.startswith("#!/usr/bin/env bash"):
            fail(f"{rel}: installed-surface file must keep its bash shebang (ADR 0026)")
        if "python3" in text:
            fail(
                f"{rel}: installed-surface file invokes or mentions python3 —"
                " the mirror contract requires standalone bash (ADR 0026)"
            )
    ok(f"installed surface ({len(INSTALLED_SURFACE)} files) stays standalone bash")


def check_python_floor_conventions() -> None:
    python_files = sorted(
        p.relative_to(ROOT).as_posix()
        for p in (ROOT / "scripts").iterdir()
        if p.is_file() and p.suffix == ".py"
    )
    for rel in python_files:
        if "from __future__ import annotations" not in read(rel):
            fail(
                f"{rel}: missing `from __future__ import annotations` — required"
                " so annotations stay legal on the Python 3.9 floor (ADR 0026)"
            )
    ok(f"python floor conventions hold across {len(python_files)} kit Python files")


def main() -> int:
    print("kit parity gate:")
    check_shared_blocks()
    check_exclusion_union()
    check_skill_roster()
    check_summary_labels()
    check_bash_boundary()
    check_python_floor_conventions()
    if failures:
        print("\nparity failures:")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print("parity ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
