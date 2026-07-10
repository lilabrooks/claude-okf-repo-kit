---
type: Spec
title: Validation workflow
description: Makefile validation contract for the source kit.
tags: [makefile, validation, smoke-tests]
timestamp: 2026-07-08T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Purpose

The source kit includes a `Makefile` to validate the kit before publishing or installing it.

The Makefile is for this repo only. It does not need to be copied into target repos.

# Primary command

`make test` must run all available validation checks.

`README.md` must name `make test` as the source-kit verification command.

# Required checks

The validation workflow must include:

- shell syntax checks for scripts
- shell syntax checks for installer scripts
- a semver format check for the root `VERSION` file
- optional ShellCheck linting when ShellCheck is installed
- Markdown local link checks
- JSON validation for `settings.json`
- stale-reference scanning for old names and local machine paths; the scan must run with ripgrep when installed, fall back to `grep -rnEI` otherwise, and fail rather than report success when the scanner itself cannot run
- source-kit smoke checks
- OKF source-kit stale mapping and ADR suggestion checks
- new-repo install simulation
- existing-repo install simulation
- existing-repo idempotency simulation
- install/verify/placeholder helper smoke checks
- hook behavior checks
- `scripts/okf` command smoke checks
- GitHub Actions validation that runs `make test` on push and pull request
- Dependabot configuration at `.github/dependabot.yml` that keeps GitHub Actions workflow action versions current on a weekly schedule

# Smoke test expectations

New-repo install simulation must verify the target install layout and basic helper execution.

New-repo install simulation must exercise `scripts/create-new-repo`.

New-repo install simulation must verify target `CLAUDE.md` comes from `templates/CLAUDE.md`, not source root `CLAUDE.md`.

New-repo install simulation must verify the installed `CLAUDE.md` carries the preloaded-context imports for `docs/GOAL.md`, `docs/specs/index.md`, and `docs/adr/index.md` (ADR 0008).

New-repo install simulation must verify the starter `docs/index.md` declares `kit_version` and links the log and source map, that the env-file ignore entries (`.env`, `.env.*`, `!.env.example`) were appended (ADR 0010), and that the installed settings carry the env-file read deny rules (ADR 0011).

Existing-repo install simulation must exercise `scripts/update-existing-repo`.

Existing-repo install simulation must verify the kit preserves an existing `CLAUDE.md`, preserves existing docs, preserves existing `.gitignore` entries, preserves existing settings entries (including the target's own permission rules), merges hook settings and the kit's permission deny rules, appends required ignore entries including the env-file set, backs up replaced kit-managed scripts, and writes numbered candidates for same-name Markdown/map files (the `docs/index.md` candidate carrying the `kit_version` stamp).

Existing-repo install simulation must verify same-name Markdown and map conflicts produce same-folder numbered candidates.

Existing-repo install simulation must verify any `CLAUDE.md` merge candidate comes from `templates/CLAUDE.md`, not source root `CLAUDE.md`.

Existing-repo install simulation must verify the update script prints a clear summary with created, updated, and review-needed sections.

Existing-repo idempotency simulation must verify repeated updates do not duplicate `.gitignore` entries, settings hooks, permission deny rules, or identical numbered candidates.


Install helper smoke tests must verify:

- `scripts/install-kit` chooses new-repo mode for missing or empty targets
- `scripts/install-kit` chooses existing-repo mode for non-empty targets
- `scripts/verify-install` passes after installation
- `scripts/check-placeholders` reports template placeholders after installation
- `scripts/check-placeholders` passes after placeholders and active mappings are filled

Hook smoke tests must cover:

- implementation changes with no docs update block
- mapped implementation changes with unrelated docs still block
- mapped implementation changes with mapped docs pass
- README-only edits pass

OKF helper smoke tests must verify draft generation, ADR suggestion behavior, the non-blocking unmapped-file note from `check-stale`, ADR and spec scaffolding (numbering, `status: proposed`, index entries), and the `pending` listing including its missing-status flag.

This kit validates OKF helper behavior and source-to-doc freshness. Target repos that need stricter OKF frontmatter or link rules should add a repo-local docs validator to their own quality gate.

Markdown link checks must ignore fenced code blocks and external URLs.

# Target repo verification

Installed target repos must be verifiable without the source Makefile.

Target verification docs must include:

- `python3 -m json.tool .claude/settings.json`
- `bash -n scripts/okf`
- `bash -n .claude/hooks/check-docs-sync.sh`
- `bash -n .claude/hooks/check-okf-version.sh`
- `bash scripts/okf check-stale`
- `bash scripts/okf adr-suggest`
