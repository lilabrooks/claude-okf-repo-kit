---
type: Spec
title: Installer scripts
description: Safe automation for creating new repos and updating existing repos with this kit.
tags: [installer, bash, safety]
timestamp: 2026-07-05T00:00:00Z
---

# Purpose

The source kit includes installer scripts so users do not have to manually copy every file.

The scripts must preserve the same install contract documented in `README.md`.

The scripts are not a replacement for the `CLAUDE.md` bootstrap instructions. They are the preferred setup path before a Claude Code session starts. The bootstrap instructions remain the in-session fallback when a repo does not yet have the expected docs tree.

Installers must copy source `templates/CLAUDE.md` to target `CLAUDE.md`. They must not copy source root `CLAUDE.md`, which is project-specific to this kit repo.

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
- `CLAUDE.md`

It must add these ignores:

- `.claude/settings.local.json`
- `CLAUDE.local.md`
- `.okf-kit-backups/`

# Existing repo installer

`bash scripts/update-existing-repo /path/to/existing-repo` updates an existing repo without destructive overwrites.

It must:

- require the target directory to exist
- create `.okf-kit-backups/<timestamp>/`
- back up files before replacing kit-managed scripts
- merge `.claude/settings.json` hooks while preserving existing settings
- append required `.gitignore` entries while preserving existing entries
- leave existing Markdown files untouched and write same-folder numbered candidates when names collide
- leave an existing `CLAUDE.md` untouched and write a candidate such as `CLAUDE.2.md`
- leave an existing `docs/okf-map.yml` untouched and write a candidate such as `docs/okf-map.2.yml`
- create missing docs indexes and log files without overwriting existing docs
- print a clear completion summary that lists created, updated, skipped, backed-up, and review-needed files, then names the verification checks it ran

# Validation

Both installers must run syntax checks for installed scripts and JSON validation for settings.

The Makefile smoke tests must exercise both installers.
