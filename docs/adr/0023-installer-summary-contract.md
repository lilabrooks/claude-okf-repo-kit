---
type: ADR
title: Installer completion summary as a stable interface
description: Pin the installers' completion-summary section labels as a stable output contract, because downstream stack templates relay and test against them.
tags: [adr, installer, output-contract, stack-templates]
timestamp: 2026-07-18T00:00:00Z
status: accepted
---

# Status

Accepted (2026-07-18, at the owner's direction; implementation landed with the proposal per the propose-then-implement policy)

# Context

The installer specs required "a clear completion summary" but left its shape as prose. That was fine while humans were the only readers. The python-cli-template repo changed that: its `create-project` runs this kit's `update-existing-repo` on generated projects, prints the summary to its users, points its next-steps text at the **Needs review** list, and guards the whole relay with a fake-kit CI test. The summary labels are now an interface another repository's tests depend on, and nothing on the kit side records that commitment — a casual wording tweak would break the downstream contract silently.

# Decision

The completion-summary section labels are a stable output contract, pinned in the installer-scripts spec and asserted by `make test` smoke checks:

- `create-new-repo`: `Created:`, `Updated:`, `Skipped:`, then `Verification run:`.
- `update-existing-repo`: `Created:`, `Updated:`, `Skipped:`, `Backed up:`, `Needs review:`, then `Verification run:`.

Every label prints on every run (`none` under an empty section), numbered review candidates appear under `Needs review:`, and changing a label or dropping a section is a breaking change to the kit's public surface — it requires a new ADR and a kit `VERSION` bump with downstream notice, not a wording edit. Adding new labels after the existing ones is allowed.

# Alternatives considered

- A machine-readable summary flag (`--json`): rejected for now — the observed consumer wants human-readable text to relay verbatim; a second output mode is more surface with no current demand. Revisit if a consumer starts parsing item lists rather than labels.
- Declare the output free-form and make downstream repos match loosely: rejected — the downstream test exists either way; pretending the interface isn't one just moves the breakage to someone else's CI.

# Consequences

- The summary labels join the kit's public surface: spec-pinned, smoke-asserted, versioned.
- Wording inside list items stays free to evolve; only the section labels and their presence are pinned.
- Revisit trigger: a downstream consumer needing structured (parseable) summaries, or a second consumer testing against item-level wording.
