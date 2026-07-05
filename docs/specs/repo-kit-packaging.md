---
type: Spec
title: Repo kit packaging
description: Source-kit layout and target repo installation contract for the Claude Code OKF kit.
tags: [claude-code, okf, packaging]
timestamp: 2026-07-05T00:00:00Z
---

# Purpose

This repo is a source kit for installing a Claude Code OKF workflow into another repository.

The source kit keeps human-readable docs and install artifacts at predictable paths so a user can review, copy, and validate the kit before publishing or installing it.

# Source-kit layout

The source repo keeps these install artifacts:

- `templates/CLAUDE.md`
- `settings.json`
- `okf-map.yml`
- `scripts/okf`
- `scripts/check-docs-sync.sh`
- `scripts/check-okf-version.sh`

The source repo also keeps local validation and project knowledge:

- `CLAUDE.md`
- `Makefile`
- `README.md`
- `LICENSE`
- `Claude Code OKF Kit Guide.md`
- `docs/`
- `scripts/create-new-repo`
- `scripts/update-existing-repo`
- `scripts/check-md-links.py`
- `.github/workflows/test.yml`

The public repo presentation must include a modest README badge set for status, tests, Claude Code, OKF, Bash, specs/ADRs, and license.

The source repo is MIT licensed.

# Target repo destinations

When installed into a target repo, copy files to these destinations:

- `templates/CLAUDE.md` -> `CLAUDE.md`
- `settings.json` -> `.claude/settings.json`
- `okf-map.yml` -> `docs/okf-map.yml`
- `scripts/okf` -> `scripts/okf`
- `scripts/check-docs-sync.sh` -> `.claude/hooks/check-docs-sync.sh`
- `scripts/check-okf-version.sh` -> `.claude/hooks/check-okf-version.sh`

# Required target docs

An installed target repo must have:

- `docs/index.md`
- `docs/log.md`
- `docs/specs/index.md`
- `docs/adr/index.md`
- `docs/okf-map.yml`

Specs and ADRs must use YAML frontmatter with at least `type:`.

# Install docs

`README.md` must include step-by-step instructions for new repos and existing repos.

Existing-repo instructions must avoid overwriting an existing `CLAUDE.md`, `.claude/settings.json`, `.gitignore`, specs, ADRs, map file, or log files.

Existing-repo instructions must describe same-folder numbered candidates for same-name Markdown/map files.

Existing-repo instructions must describe `.gitignore` appends, not `.gitignore` replacement.

Root `CLAUDE.md` must describe this source repo. Installers and manual install docs must use `templates/CLAUDE.md` for target repos.

`README.md` must clearly distinguish:

- validating this source kit
- automated setup for new and existing repos
- installing the kit into a new repo
- installing the kit into an existing repo
- verifying an installed target repo

Target-repo verification instructions must include syntax checks for copied scripts, JSON validation for `.claude/settings.json`, and helper checks for `scripts/okf`.

Target-repo verification instructions must include an ignored-file check for local Claude files and `.okf-kit-backups/`.

# Ignore policy

The source kit ignores local machine state:

- `.DS_Store`
- `.obsidian/`
- `.claude/settings.local.json`
- `CLAUDE.local.md`
- `.okf-kit-backups/`
- `.env`
- `.env.*`
- `*.log`
- `__pycache__/`
- `*.py[cod]`

The source kit must not ignore `.env.example`.
