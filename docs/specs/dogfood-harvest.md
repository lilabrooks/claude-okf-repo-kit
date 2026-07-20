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
- `bash scripts/harvest-dogfood index` — rebuild the cross-repo knowledge index and report its entry count.
- `bash scripts/harvest-dogfood query <pattern>` — rebuild the index, then print entries matching the case-insensitive extended-regex pattern; a query with no pattern prints usage and exits nonzero, and a pattern with no matches reports that and exits 1.
- Unknown subcommands print usage and exit nonzero.

Cross-repo index:

- Lives beside the registry (`dogfood-index` in the same directory), machine-local and never committed. It is derived: rebuilt from scratch on every `index` and `query` run, so it cannot go stale and is never edited.
- One tab-separated line per fact — repo name, kind, source path, text — where kind is one of `goal` (Kind/Problem/Solution lines from `docs/GOAL.md`), `milestone` (checkbox lines), `spec` (entries from the spec index at the target's layout home, `docs/specs/index.md` by default), `adr` (per-ADR status — tolerant of frontmatter, `- Status:` bullets, and `# Status` sections — title with a first-heading fallback, and description, from the target's ADR home, skipping the index and numbered candidates; ADR 0018), and `log` (each `docs/log.md` bullet's first line, truncated, tagged with its dated heading).
- Query output groups each hit as a header line (repo, kind, path) and an indented text line — compact enough that a hit costs tens of tokens to read.

Report, per registered repo:

- `kit_version` stamp from the target's `docs/index.md` compared against the kit `VERSION`, with an explicit drift marker.
- Commits since the recorded SHA (`git log --oneline`), and the added `docs/log.md` lines from that range — the docs-sync hook guarantees this carries the narrative. Lines mentioning the kit by name, "upstream", or the word "kit" are repeated under a flagged section. A recorded SHA that no longer resolves falls back to recent history with a warning instead of failing.
- Kit-managed file status for `scripts/okf`, the two hooks, and the six `okf-*` skills: `matches kit` (byte-identical to current kit source), `unedited older kit output` (digest recorded in the target's candidate manifest, so the updater refreshes it in place), `owner-edited or unrecorded` (the updater preserves it and writes a candidate), or `missing` (the updater installs it) — the ADR 0013 classification extended to the ADR 0015 skills.
- The target's proposed-ADR review inbox via its own `bash scripts/okf pending`.
- An uncommitted-changes count when the target's working tree is dirty, and a note when second-agent config (`AGENTS.md`, `.codex/`) is present. The second-agent note is declaration-aware (ADR 0021): it names the hook mirror directories declared in the target map's top-level `mirrors:` list (the safe updater syncs those), or states that no `mirrors:` declaration exists and any hook mirrors stay owner-synced until declared.
- A registered path that no longer exists is reported as skipped, not an error.

The helper is read-only against targets: it must not write to, fetch into, or otherwise modify a registered repo. The registry file is the only thing it writes.

# Verification

- `make smoke-harvest`: against a temp target created by `scripts/create-new-repo` (registry pointed at a temp file via `OKF_DOGFOOD_REGISTRY`), verifies `add` baselines at HEAD, a zero-delta report, a committed change producing the commit line, the new log entry, and the kit-mention flag, owner-edited hook classification, `mark` resetting the delta to zero, and the query path: a term from the committed log entry matches with the repo tag, and a nonsense term exits 1.
- `make syntax` / `make shellcheck` cover the script.
- Manual check: `bash scripts/harvest-dogfood list` then a `report` against the registered real repos.
