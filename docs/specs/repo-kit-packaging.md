---
type: Spec
title: Repo kit packaging
description: Source-kit layout and target repo installation contract for the Claude Code OKF kit.
tags: [claude-code, okf, packaging]
timestamp: 2026-07-08T00:00:00Z
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
- `.github/workflows/pages.yml`
- `.github/dependabot.yml`
- `site/`

The public repo presentation must include a modest README badge set with links for preview status, GitHub Actions tests, Claude Code, OKF, Bash, and specs/ADRs.

The source repo publishes a website from `site/` — static, self-contained HTML with no build step — deployed to GitHub Pages by `.github/workflows/pages.yml` per ADR 0009. The site must describe how Claude Code works with an installed repo (session context, goal interview, iteration loop, decision policy, guardrails with the enforcement caveat, interruption resume) and must stay consistent with the installed template behavior. It is source-only: installers never copy it into target repos.

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

The installed `CLAUDE.md` must preload session context with `@` imports of `docs/GOAL.md`, `docs/specs/index.md`, and `docs/adr/index.md`, and must not import larger or unbounded files such as `docs/log.md` or full specs (ADR 0008).

The installed `CLAUDE.md` must also carry the autonomous iteration contract (ADR 0007):

- fill placeholder content in `docs/GOAL.md` or `CLAUDE.md` with the owner before the first milestone task, through a structured goal interview: what is being built and for whom, the concrete done state, the mechanical verification, non-goals, which stack choices are fixed versus decided later through proposed ADRs, and the first shippable slice — each question illustrated with a worked example, pushing back on answers that cannot be checked mechanically, proposing answers from an existing codebase where possible, and never overwriting goal content the owner wrote by hand
- continue milestone by milestone until the backlog is done, a reserved decision comes up, or the owner stops the loop, and report the goal met when all milestones and success criteria pass instead of inventing scope
- resume interrupted work: at session start, uncommitted working-tree changes are in-flight work to reconcile against the first unchecked milestone and the newest `docs/log.md` entry, then finish or back out — not a clean slate
- record decision-shaped changes as `status: proposed` ADRs and implement against them, while goal changes and accepted-ADR supersession stay with the owner
- hold standing guardrails: verification must pass before a milestone is checked off; failing tests must never be deleted, skipped, or weakened to force green; secrets must never enter tracked files and env/credential files must be confirmed git-ignored; security-sensitive changes go through `adr-suggest` and get a proposed ADR when flagged; new runtime dependencies need a proposed ADR; force pushes, data deletion or migration, out-of-scope file deletion, publishing, deploying, releasing, and external side-effecting calls need the owner's explicit go-ahead

# Install docs

`README.md` must include step-by-step instructions for new repos and existing repos.

`README.md` must begin with a clear plain-language section that explains what the kit does before listing install files.

`README.md` must include a table of contents near the top that links to the main usage and verification sections.

`README.md` must describe the goal-iteration loop and its standing guardrails.

`README.md` and the guide must state the enforcement caveat plainly: the docs-sync hooks are the kit's only mechanical enforcement; the test, security, and destructive-action guardrails are instruction-level in the installed `CLAUDE.md`, and repos that need guaranteed gates add them in their own CI and branch protection (ADR 0007).

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
- this source repo's own GitHub-side settings (Dependabot, security features, and the GitHub Pages source) that are not reproducible from a clone, with restore commands

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
