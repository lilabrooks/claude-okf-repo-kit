---
type: Spec
title: Repo kit packaging
description: Source-kit layout and target repo installation contract for the Claude Code OKF kit.
tags: [claude-code, okf, packaging]
timestamp: 2026-07-07T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Purpose

This repo is a source kit for installing a Claude Code OKF workflow into another repository.

The source kit keeps human-readable docs and install artifacts at predictable paths so a user can review, copy, and validate the kit before publishing or installing it.

# Source-kit layout

The source repo keeps these install artifacts:

- `templates/CLAUDE.md`
- `templates/GOAL.md`
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
- `scripts/install-kit`
- `scripts/verify-install`
- `scripts/check-placeholders`
- `scripts/check-md-links.py`
- `.github/workflows/test.yml`
- `.github/dependabot.yml`

The public repo presentation must include a modest README badge set with links for preview status, GitHub Actions tests, Claude Code, OKF, Bash, and specs/ADRs.

The source repo is MIT licensed.

# Target repo destinations

When installed into a target repo, copy files to these destinations:

- `templates/CLAUDE.md` -> `CLAUDE.md`
- `templates/GOAL.md` -> `docs/GOAL.md`
- `settings.json` -> `.claude/settings.json`
- `okf-map.yml` -> `docs/okf-map.yml`
- `scripts/okf` -> `scripts/okf`
- `scripts/check-docs-sync.sh` -> `.claude/hooks/check-docs-sync.sh`
- `scripts/check-okf-version.sh` -> `.claude/hooks/check-okf-version.sh`

# Required target docs

An installed target repo must have:

- `docs/index.md`
- `docs/GOAL.md`
- `docs/log.md`
- `docs/specs/index.md`
- `docs/adr/index.md`
- `docs/okf-map.yml`

Specs and ADRs must use YAML frontmatter with at least `type:`.

`docs/GOAL.md` is the goal-definition file installed from `templates/GOAL.md`. It must capture the repo kind (app, service, or utility), the problem, the target state, verifiable success criteria, and an ordered milestone backlog. The installed `CLAUDE.md` must instruct Claude Code to read it each session and take the first unchecked milestone when asked to continue without a specific task.

# Install docs

`README.md` must include step-by-step instructions for new repos and existing repos.

`README.md` must begin with a clear plain-language section that explains what the kit does before listing install files.

`README.md` must include a table of contents near the top that links to the main usage and verification sections.

Existing-repo instructions must avoid overwriting an existing `CLAUDE.md`, `.claude/settings.json`, `.gitignore`, specs, ADRs, map file, or log files.

Existing-repo instructions must describe same-folder numbered candidates for same-name Markdown/map files.

Existing-repo instructions must describe `.gitignore` appends, not `.gitignore` replacement.

Root `CLAUDE.md` must describe this source repo. Installers and manual install docs must use `templates/CLAUDE.md` for target repos.

`README.md` must clearly distinguish:

- validating this source kit
- automated setup for new and existing repos
- source-only install, verify, and placeholder helper scripts
- manual setup paths
- installing the kit into a new repo
- installing the kit into an existing repo
- installed target-repo ignore rules
- this source repo's own ignore rules
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
