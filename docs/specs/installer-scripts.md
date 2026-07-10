---
type: Spec
title: Installer scripts
description: Safe automation for creating new repos and updating existing repos with this kit.
tags: [installer, bash, safety]
timestamp: 2026-07-08T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Purpose

The source kit includes installer scripts so users do not have to manually copy every file.

The scripts must preserve the same install contract documented in `README.md`.

The scripts are not a replacement for the `CLAUDE.md` bootstrap instructions. They are the preferred setup path before a Claude Code session starts. The bootstrap instructions remain the in-session fallback when a repo does not yet have the expected docs tree.

Installer completion output must point to the in-session goal interview as the recommended path for filling `CLAUDE.md` and `docs/GOAL.md`, with manual editing as the alternative.

Installers must copy source `templates/CLAUDE.md` to target `CLAUDE.md`. They must not copy source root `CLAUDE.md`, which is project-specific to this kit repo.

Installers must copy source `templates/GOAL.md` to target `docs/GOAL.md` so every installed repo starts with a goal template Claude Code can iterate toward.

# New repo installer

`bash scripts/create-new-repo /path/to/new-repo` creates a new target repo with the kit installed.

The target may be missing or empty. It may contain an existing `.git/` directory.

The script must refuse to run against a non-empty target with files other than `.git/`.

The script must print a clear completion summary that lists created, updated, and skipped files, then names the verification checks it ran.

It must create:

- `.claude/settings.json`
- `.claude/hooks/check-docs-sync.sh`
- `.claude/hooks/check-okf-version.sh`
- `scripts/okf`
- `docs/index.md`
- `docs/log.md`
- `docs/specs/index.md`
- `docs/specs/_drafts/`
- `docs/adr/index.md`
- `docs/okf-map.yml`
- `docs/GOAL.md`
- `CLAUDE.md`

It must add these ignores:

- `.claude/settings.local.json`
- `CLAUDE.local.md`
- `.okf-kit-backups/`
- `.DS_Store` (macOS Finder artifacts; harmless elsewhere)
- `.env`
- `.env.*`
- `!.env.example` (keeps the sample env file trackable)

# Existing repo installer

`bash scripts/update-existing-repo /path/to/existing-repo` updates an existing repo without destructive overwrites.

It must:

- require the target directory to exist
- create `.okf-kit-backups/<timestamp>/`
- back up files before replacing kit-managed scripts
- merge `.claude/settings.json` hooks and `permissions` rules (union by exact rule) while preserving existing settings
- append the required `.gitignore` entries (the same seven the new-repo installer adds) while preserving existing entries
- leave existing Markdown files untouched and write same-folder numbered candidates when names collide
- leave an existing `CLAUDE.md` untouched and write a candidate such as `CLAUDE.2.md`
- leave an existing `docs/okf-map.yml` untouched and write a candidate such as `docs/okf-map.2.yml`
- leave an existing `docs/GOAL.md` untouched and write a candidate such as `docs/GOAL.2.md`; create `docs/GOAL.md` from `templates/GOAL.md` when it is missing
- skip writing a numbered candidate when the existing file already matches the kit content byte for byte
- create missing docs indexes and log files without overwriting existing docs
- print a clear completion summary that lists created, updated, skipped, backed-up, and review-needed files, then names the verification checks it ran

Starter `docs/index.md` content written by either installer must link `GOAL.md`, `specs/index.md`, `adr/index.md`, `log.md`, and `okf-map.yml`, and must declare `okf_version` plus the installing kit's `kit_version` read from the source `VERSION` file (ADR 0010). The existing-repo installer carries the same content in the numbered candidate it writes when a `docs/index.md` already exists.

# Wrapper and verification helpers

`bash scripts/install-kit /path/to/target-repo` must choose the safe setup path:

- missing, empty, or `.git/`-only target -> `scripts/create-new-repo`
- existing target with files -> `scripts/update-existing-repo`

The wrapper must print the selected mode and delegated command before running it.

`bash scripts/verify-install /path/to/target-repo` must check installed files, settings JSON, hook commands, the env-file read deny rules, shell syntax, required `.gitignore` entries (including the env-file set), and basic `scripts/okf` execution. It must warn — not fail — when `docs/index.md` lacks a `kit_version` stamp or when `.env.example` is ignored, and it must not judge project-specific content.

`bash scripts/check-placeholders /path/to/target-repo` must report remaining template placeholders in `CLAUDE.md` and `docs/GOAL.md`, and missing active mappings in `docs/okf-map.yml`. It must not modify files.

# Validation

Both installers must run syntax checks for installed scripts and JSON validation for settings.

The Makefile smoke tests must exercise both installers and the source-only install, verify, and placeholder helpers.
