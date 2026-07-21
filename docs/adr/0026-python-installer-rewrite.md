---
type: ADR
title: Rewrite kit-side installer tools in Python stdlib
description: Move the source-kit-side installer tools to Python stdlib behind the existing smoke suite, while the target-installed surface (hooks, scripts/okf) stays standalone bash.
tags: [adr, installer, bash, python, maintainability]
timestamp: 2026-07-21T22:45:04Z
status: proposed
---

# Status

Proposed (authored per the decision policy; awaiting owner review). Implementation is deliberately deferred: this ADR sets the boundary and the verification plan now, and work starts when a trigger below fires, not on acceptance.

# Context

The kit is ~2,500 lines of bash across ten scripts, and the failure history is concentrated: three separate pipefail/SIGPIPE bug batches (0.3.6, 0.3.7, and the tripwire's own catches), and a full audit whose three confirmed bugs all lived in bash-specific hazard classes (divergent inline awk copies, quoting, list parsing). `update-existing-repo` is the hot spot — it changed in six of the nine releases through 0.3.8, grew ~150 lines in 0.3.8 alone, and carries the kit's most safety-critical logic (provenance, backups, candidates).

Two facts make a rewrite cheaper than it looks. First, the kit-side tools (`update-existing-repo`, `create-new-repo`, `verify-install`, `install-kit`, `check-placeholders`, `harvest-dogfood`) never land in target repos — only the two hooks and `scripts/okf` are installed — so rewriting them changes nothing about the installed surface or its dependencies. Second, python3 is already a hard dependency of exactly these tools (the settings merge, JSON validation), and the smoke suite is black-box: it exercises the scripts by invocation and asserts on filesystem outcomes and summary text, so it verifies a Python implementation exactly as it verifies the bash one.

The counterweight: the bash updater is currently the best-tested it has ever been, and a rewrite risks regressions precisely where trust matters most. That argues for a defined trigger rather than an immediate start.

# Decision

Rewrite the kit-side tools in Python (stdlib only, single files, no packaging), in this order and only this scope:

1. `update-existing-repo` first — highest change rate, highest hazard density.
2. `verify-install` second.
3. `create-new-repo` third (small, stable).
4. `install-kit`, `check-placeholders`, `harvest-dogfood` optionally, if maintenance pressure appears; they may stay bash indefinitely.

The target-installed surface — `scripts/check-docs-sync.sh`, `scripts/check-okf-version.sh`, and `scripts/okf` — stays standalone bash: hooks are mirrored byte-for-byte into other agents' configs and must run with no companion files, and `scripts/okf` runs inside target repos whose only assumed tools are bash, git, and awk.

Compatibility commitments for each rewritten tool: the completion-summary labels and semantics stay byte-compatible (ADR 0023 and its amendment); the candidate-manifest format is unchanged; the `layout:`/`mirrors:` map grammar is unchanged; CLI (arguments, exit codes) is unchanged.

Verification plan: the existing `make test` smoke suite must pass unmodified against the Python implementation, plus a one-time A/B harness — run the bash and Python versions against the same fixture trees and diff the resulting trees and summaries byte-for-byte — kept until the bash version is deleted.

Implementation triggers (whichever fires first): the next SIGPIPE/quoting-class bug in a kit-side bash tool, or the owner's decision to promote the kit beyond dogfood use.

# Alternatives considered

- Stay bash with more tripwires: the `make scan` pipefail tripwire and the `make parity` gate genuinely shrink the hazard surface, but they detect known hazard classes only — each of the three audit bugs was a class no tripwire anticipated. Rejected as the long-term answer; retained as the interim answer until a trigger fires.
- Rewrite everything including hooks and `scripts/okf`: rejected — mirrored hooks must stand alone (ADR 0021's byte-identical mirror contract), and a Python hook would change the installed dependency story on every SessionStart/Stop.
- A shared sourced bash library for the parsers: rejected — it breaks the standalone-hook contract the same way, and `make parity`'s byte-parity check achieves the single-parser goal without new runtime coupling.

# Consequences

- The pipefail/SIGPIPE hazard class disappears from the rewritten tools; parsing gains real data structures and unit-testability.
- Two implementation languages coexist during the migration; the A/B harness and the unmodified smoke suite carry the equivalence burden.
- The installed surface, its provenance mechanics, and every downstream consumer contract are explicitly unchanged; a target repo cannot observe the rewrite except through identical behavior.
- The `make parity` shared-block check shrinks to the bash scripts that remain; the Python side imports its one parser.

# Rollback / revisit trigger

Rollback: the bash originals stay in git history and, during migration, in the tree until their replacement has passed a full release cycle; reverting a tool is restoring the bash file and re-pointing the Makefile smoke invocations. Revisit if a target-side constraint ever forces python3 off the supported-tools list (would block the kit-side tools too), or if the migration's A/B harness surfaces behavioral divergence that the smoke suite cannot pin — in that case stop, extend the smoke suite first, and only then continue.
