---
type: ADR
title: Commented @-import shims count as shims
description: Treat a CLAUDE.md that imports AGENTS.md plus short heading-free prose as an import shim, so AGENTS.md-first repos get an AGENTS.2.md candidate instead of a competing CLAUDE.2.md.
tags: [adr, installer, brownfield, agents-md, shim]
timestamp: 2026-07-18T00:00:00Z
status: accepted
---

# Status

Accepted (2026-07-18, at the owner's direction; implementation landed with the proposal per the propose-then-implement policy)

# Context

ADR 0018 made the updater AGENTS.md-first: when `AGENTS.md` is the repo's playbook and `CLAUDE.md` is absent or a pure `@`-import shim, the kit playbook stages as an `AGENTS.md` numbered candidate and the shim is preserved. "Pure" was defined mechanically — every non-blank line starts with `@`.

The python-cli-template repo (a public stack template whose `create-project` runs this kit's updater on generated projects) exposed the gap: its root `CLAUDE.md` is exactly the intended shim — a single `@AGENTS.md` import — preceded by three lines of prose telling human readers to edit `AGENTS.md`, not this file. That documentation defeats the pure-shim test, so the updater staged a `CLAUDE.2.md` that competes with the shim, and the template had to document the merge-back-into-AGENTS.md recovery sequence in its own README. A shim explained in prose is still a shim; the well-documented variant should not get worse treatment than the bare one.

# Decision

`is_import_shim` in `update-existing-repo` accepts two shapes:

1. **Pure shim** (unchanged): only `@`-import lines and blank lines.
2. **Commented shim** (new): contains a line that is exactly `@AGENTS.md`, contains no Markdown heading lines (`^#`), and has at most 10 non-blank lines total.

Everything else — headings, length, or an import set that does not include `@AGENTS.md` — is treated as a real playbook and keeps the `CLAUDE.2.md` candidate path. The bounds are deliberately tight: a heading or an eleventh non-blank line signals resident instructions worth a candidate beside them, and requiring the `@AGENTS.md` import keeps the relaxation scoped to the AGENTS.md-first arrangement ADR 0018 defined.

# Alternatives considered

- Keep the pure-only rule and let AGENTS.md-first repos document the recovery: rejected — it pushes kit-workflow instructions into every downstream README and produces a candidate that competes with the file it duplicates.
- Treat any `CLAUDE.md` containing `@AGENTS.md` as a shim regardless of content: rejected — a real playbook can import `AGENTS.md` alongside its own resident rules; clobber-adjacent misclassification is worse than a redundant candidate.
- A marker comment the kit recognizes (`<!-- okf: shim -->`): rejected — existing shims in the wild (the python-cli-template one included) don't carry it, so it fixes nothing without downstream edits.

# Consequences

- AGENTS.md-first repos whose shim carries explanatory prose get the ADR 0018 behavior: kit playbook as `AGENTS.2.md`, shim untouched.
- A short heading-free `CLAUDE.md` that is genuinely a playbook (unlikely but possible) would be misclassified; the cost is a preserved live file and the kit playbook staged beside `AGENTS.md` instead of beside `CLAUDE.md` — no content is lost.
- Revisit trigger: a dogfood or downstream repo whose real playbook is misclassified as a shim, or a shim convention that exceeds 10 non-blank lines in practice.
