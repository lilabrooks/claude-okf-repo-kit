---
type: Spec
title: Dogfood harvest helper
description: Registry and delta-report contract for tracking installed dogfood repos from the source kit.
tags: [spec, dogfooding, maintenance]
timestamp: 2026-07-11T22:00:37Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Purpose

`scripts/harvest-dogfood` is a source-only maintainer tool. It reports what changed in registered installed repos since the last harvest so kit updates can start from a delta instead of re-exploring target codebases (ADR 0014). It is never installed into target repos.

# Contract

Registry:

- Lives at `.okf-kit-backups/dogfood-registry` in the kit working copy; `OKF_DOGFOOD_REGISTRY` overrides the path (tests use this).
- One line per repo: name, absolute path, last-harvest commit SHA, last-seen `kit_version` stamp, tab-separated. Blank lines and `#` comments are ignored.
- Machine-local and git-ignored; it must never be committed, because it holds local machine paths the stale-reference scan forbids in tracked files.

Commands:

- `bash scripts/harvest-dogfood` (or `report`) — print a report for every registered repo.
- `bash scripts/harvest-dogfood add <path> [name]` — register a repo at its current HEAD; the name defaults to the directory basename. Rejected inputs: a missing directory, a directory that is not a git repo with at least one commit, and a name already registered — each fails with a clear message and a nonzero exit.
- `bash scripts/harvest-dogfood mark [name ...]` — record the current HEAD and stamp for the named repos (all repos when no names are given), after the owner has reviewed a report.
- `bash scripts/harvest-dogfood list` — show the registry with short SHAs and stamps.
- Unknown subcommands print usage and exit nonzero.

Report, per registered repo:

- `kit_version` stamp from the target's `docs/index.md` compared against the kit `VERSION`, with an explicit drift marker.
- Commits since the recorded SHA (`git log --oneline`), and the added `docs/log.md` lines from that range — the docs-sync hook guarantees this carries the narrative. Lines mentioning the kit by name, "upstream", or the word "kit" are repeated under a flagged section. A recorded SHA that no longer resolves falls back to recent history with a warning instead of failing.
- Kit-managed script status for `scripts/okf` and the two hooks: `matches kit` (byte-identical to current kit source), `unedited older kit output` (digest recorded in the target's candidate manifest, so the updater refreshes it in place), or `owner-edited or unrecorded` (the updater preserves it and writes a candidate) — the ADR 0013 classification.
- The target's proposed-ADR review inbox via its own `bash scripts/okf pending`.
- An uncommitted-changes count when the target's working tree is dirty, and a note when second-agent config (`AGENTS.md`, `.codex/`) is present.
- A registered path that no longer exists is reported as skipped, not an error.

The helper is read-only against targets: it must not write to, fetch into, or otherwise modify a registered repo. The registry file is the only thing it writes.

# Verification

- `make smoke-harvest`: against a temp target created by `scripts/create-new-repo` (registry pointed at a temp file via `OKF_DOGFOOD_REGISTRY`), verifies `add` baselines at HEAD, a zero-delta report, a committed change producing the commit line, the new log entry, and the kit-mention flag, owner-edited hook classification, and `mark` resetting the delta to zero.
- `make syntax` / `make shellcheck` cover the script.
- Manual check: `bash scripts/harvest-dogfood list` then a `report` against the registered real repos.
