---
type: ADR
title: One shared layout path-safety primitive
description: Carry layout path validation as an OKF-SHARED block beside the existing layout parser, with a conformance corpus as the authority once a tool migrates to Python.
tags: [adr, security, layout, parity, installer]
generated: { by: process:okf-scaffold, at: 2026-07-26T03:06:13Z }
status: proposed
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Status

Proposed (authored per the decision policy; awaiting owner review).

# Context

`update-existing-repo` validates `layout:` values before its first write:
absolute paths, `..`, empty and `.` segments, control characters, and any value
resolving outside the target are refused, and the backup directory is not
created until the preflight passes. The installed helper has no such check.
With `adr_dir: ../outside` in a target map, `bash scripts/okf new-adr` writes
the ADR and its index entry outside the repository root. That is the open half
of `KIT-P0-1`.

The obvious repair — copy the updater's inline validation into `scripts/okf` —
is unavailable. Two accepted constraints rule it out:

- ADR 0026 keeps the target-installed surface (`scripts/okf` and both hooks)
  standalone Bash with no companion files, because installed tools run in
  target repos whose only assumed tools are bash, git, and awk. `make parity`
  asserts that surface never mentions `python3`. The updater's validation is
  inline Python heredocs and cannot move as-is.
- The integration roadmap's `K1.5` requires one path-safety primitive with no
  second copy of the validator. Two independent implementations of the same
  refusal rules are exactly what it forbids, because they drift.

So the question is not whether to validate in the installed helper. It is where
the single authoritative definition lives when one consumer must stay Bash and
another is scheduled to become Python under ADR 0026.

The kit has already solved this shape once. `OKF-SHARED` marked blocks carry
the `layout-awk` layout parser byte-identically across `scripts/okf`,
`update-existing-repo`, `verify-install`, `check-okf-version.sh`, and
`harvest-dogfood`, with `scripts/check-parity.py` failing the build on any
divergence. Layout *parsing* already crosses the installed and source boundary
as one definition. Only layout *validation* does not.

# Decision

Add a `layout-guard` `OKF-SHARED` block beside the existing `layout-awk` block.

- The guard is Bash and awk only, with no python3 and no companion file, so it
  is legal in the installed surface under ADR 0026.
- It carries the refusal rules the updater already enforces: reject absolute
  paths, empty, `.` and `..` segments, control characters, and any value whose
  resolution leaves the target root. Refusal is a hard failure before any read
  or write of the affected path.
- Every kit-side tool that consumes a `layout:` value invokes the guard
  immediately after the `layout-awk` parser returns it, before acting on the
  value. That includes `scripts/okf`, closing the open half of `KIT-P0-1`.
- `layout-guard` is registered in `SHARED_BLOCKS` in `scripts/check-parity.py`,
  so `make parity` fails on any byte divergence between copies, and on a script
  that carries a `layout-awk` block without the guard.
- A shared conformance corpus records every refusal and acceptance case with
  its expected outcome. The corpus, not any one copy of the code, is the
  authority on behavior.

When ADR 0026 migrates a tool to Python, that tool drops the Bash block and its
Python implementation must pass the same conformance corpus. The corpus is what
survives the language boundary; byte-identical source is only how the Bash-side
tools satisfy it. A migrated tool that cannot pass the corpus blocks its own
migration.

`scripts/okf` is an installed artifact, so the change alters installed
behavior: a target whose map was edited after install will start refusing
values it previously followed. That requires a `VERSION` bump under ADR 0010
and a `site/` review under ADR 0016.

# Alternatives considered

- **Copy the updater's validation into `scripts/okf`.** Rejected: it is Python,
  which `make parity` forbids in the installed surface, and a second copy is
  what `K1.5` exists to prevent.
- **Have `scripts/okf` shell out to a kit-side validator.** Rejected: installed
  tools run inside target repos where no kit checkout exists. The installed
  surface must work standalone.
- **Ship a new installed `scripts/okf-lib.sh` companion.** Rejected: it adds an
  installed artifact against the goal's non-goal on growing that surface, and
  ADR 0026 requires the hooks and helper to run with no companion files.
- **Let `scripts/okf` call python3 directly.** Rejected: contradicts ADR 0026
  and fails the parity gate, and python3 is not an assumed target tool.
- **Validate only in the updater and document the helper's limit.** Rejected:
  it leaves a known write-outside-root defect open in an installed artifact,
  and the target owner is the party least able to see it.
- **Make the conformance corpus the only shared artifact, with independent
  implementations from the start.** Rejected for now: it permits two Bash
  implementations to drift between corpus runs, and the existing marked-block
  mechanism already gives byte-level enforcement at no extra cost. The corpus
  becomes the sole authority only where a language boundary forces it.

# Consequences

- Closes the remaining half of `KIT-P0-1`. Installed helpers refuse unsafe
  layout values before reading or writing.
- Satisfies `K1.4` and `K1.5` without inventing a mechanism: the guard uses the
  same marked-block and parity machinery already carrying the layout parser.
- The updater's inline Python validation is replaced by the shared guard, so
  the refusal rules have one authored source instead of two.
- ADR 0026's migration path stays open. A rewritten tool swaps the Bash block
  for a Python implementation and proves equivalence against the corpus.
- Requires a `VERSION` bump and a `site/` review, because installed behavior
  changes.
- Adds a parity rule that must be kept in sync: any new script reading a
  `layout:` value must carry both blocks or the gate fails.
- A target repo relying on an out-of-root `layout:` value will break on
  upgrade. That is intended; such a value was never supported and the updater
  already refuses it.

# Rollback / revisit trigger

Revisit if the conformance corpus proves unable to express a refusal rule that
only one language can enforce, or if a target ecosystem appears where the awk
the guard needs is unavailable. Rollback is removing the `layout-guard` block
from `SHARED_BLOCKS` and the consuming scripts, which reopens `KIT-P0-1` and
therefore requires a replacement containment decision in the same change, not
a bare revert.
