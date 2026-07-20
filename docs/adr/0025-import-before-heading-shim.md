---
type: ADR
title: Import-before-heading shim classification
description: A heading disqualifies a CLAUDE.md shim only when the @AGENTS.md import sits under it, and the shim budget grows to 15 non-blank lines, so shims carrying the preloaded-context block classify correctly.
tags: [adr, brownfield, shim, installer]
timestamp: 2026-07-20T02:25:28Z
status: accepted
---

# Status

Accepted (2026-07-19)

# Context

ADR 0022 taught `is_import_shim` to accept a commented shim: an exact `@AGENTS.md` import plus short explanatory prose, with two disqualifiers — any heading, or more than 10 non-blank lines. The 0.3.5 upgrade of the live spec-drift repo (github.com/lilabrooks/spec-drift) hit a shim shape those bounds reject: redirect prose, the `@AGENTS.md` import, and then the kit's own preloaded-context block — a `# Preloaded context` heading, two lines of explanation, and the three `@docs` imports — 12 non-blank lines in all. Functionally it is a pure redirect (its prose says "Edit AGENTS.md, not this file"), and the heading exists only because the file carries the same preloaded-context section the kit's installed playbook uses. The classifier called it a real playbook, so the updater staged a competing `CLAUDE.2.md` instead of the `AGENTS.2.md` an AGENTS.md-first repo should get. The finding is recorded in that repo's 2026-07-19 `docs/log.md` entry.

# Decision

Refine the commented-shim test in `is_import_shim` (the `CLAUDE.2.md`-vs-`AGENTS.2.md` staging decision is otherwise unchanged):

- A heading disqualifies only when the exact `@AGENTS.md` import appears **after** the first heading. A real playbook imports `AGENTS.md` beneath its own headings — ADR 0022's tested counter-edge stays a real playbook — while a shim states its redirect first and may then carry the preloaded-context block under a heading.
- The non-blank line budget rises from 10 to 15, fitting the observed shim shape: redirect prose plus the kit's preloaded-context section.

# Alternatives considered

- **Drop the heading test entirely and rely on the line budget.** Rejected: it flips ADR 0022's tested counter-edge — a short real playbook that imports `AGENTS.md` under a heading would classify as a shim, and its owner would stop receiving playbook candidates on the `CLAUDE.md` side they actually maintain.
- **Whitelist the specific `# Preloaded context` heading text.** Rejected as brittle: the heading is owner prose, not kit output; a synonym ("Session imports") would defeat it, and the import-position rule captures the actual structural difference.
- **Leave the classifier alone and document the workaround (owner declines the `CLAUDE.2.md` by hand).** Rejected: the misclassification recurs on every future upgrade of every repo with this shim shape, and the kit's division of labor puts mechanical classification in code.

# Consequences

- AGENTS.md-first repos whose shim carries the preloaded-context block get the correct `AGENTS.2.md` staging; the misclassification cost was never data loss (the shim is left untouched either way), only which side received the review candidate.
- The classifier grows a small risk in the other direction: a real playbook that opens with a bare `@AGENTS.md` line before its first heading and stays within 15 non-blank lines would classify as a shim. Its `CLAUDE.md` is still never overwritten; the kit playbook candidate lands beside `AGENTS.md` instead. No dogfood repo has this shape.
- ADR 0022's decision text gains an amendment pointing here; the installer spec's shim definition and the brownfield smoke coverage carry the third edge (import-before-heading shim → `AGENTS.2.md`).

# Rollback / revisit trigger

Revisit if a real playbook is observed misclassified as a shim under the new rule (import first, under 15 lines) — tightening would mean requiring the redirect prose before the import or lowering the budget. Rollback means restoring the heading-free test and 10-line budget from ADR 0022 and removing the third smoke edge; repos like spec-drift then return to declining a competing `CLAUDE.2.md` by hand each upgrade.
