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
- `VERSION`
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

The source repo publishes its release version in a root `VERSION` file (semver, one line) on `main`. It is source-only — never copied to targets — and must be bumped when installed behavior changes, because installed repos compare their stamped `kit_version` against it at session start (ADR 0010).

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

The bundle root `docs/index.md` declares `okf_version`, and installer-written starter indexes also declare `kit_version` — the kit release that produced the install, read from the source `VERSION` file (ADR 0010) — and link the goal, the spec and ADR indexes, the log, and the source map.

`docs/GOAL.md` is the goal-definition file installed from `templates/GOAL.md`. It must capture the repo kind (app, service, or utility), the problem, the target state, verifiable success criteria, and an ordered milestone backlog. Its success-criteria hints must include input tolerance (realistic input variants work, wrong input gets a clear error), its milestone preamble must require user-facing milestone verifications to name at least one rejected or edge input, and the milestone list must end with a suggested README-quickstart milestone (verification: the quickstart reproduces on a clean checkout) the owner may keep, adjust, or delete. The installed `CLAUDE.md` must instruct Claude Code to read it each session and take the first unchecked milestone when asked to continue without a specific task.

The installed `CLAUDE.md` must preload session context with `@` imports of `docs/GOAL.md`, `docs/specs/index.md`, and `docs/adr/index.md`, and must not import larger or unbounded files such as `docs/log.md` or full specs (ADR 0008).

The installed `CLAUDE.md` must also carry the autonomous iteration contract (ADR 0007):

- fill placeholder content in `docs/GOAL.md` or `CLAUDE.md` with the owner before the first milestone task, through a structured goal interview: what is being built and for whom, the concrete done state, the example interactions users will actually give the primary interface (including at least one messy or wrong one, phrased per repo kind — typed/pasted input for an app, command lines for a utility, requests for a service), the mechanical verification (with the convention that a new repo's first milestone establishes canonical test and run commands), non-goals, which stack choices are fixed versus decided later through proposed ADRs, and the first shippable slice — each question illustrated with a worked example, pushing back on answers that cannot be checked mechanically, proposing answers from an existing codebase where possible, drafting the milestone backlog to end with the README-quickstart milestone by default, and never overwriting goal content the owner wrote by hand
- continue milestone by milestone until the backlog is done, a reserved decision comes up, or the owner stops the loop, and report the goal met when all milestones and success criteria pass instead of inventing scope
- run an acceptance pass before reporting the goal met: exercise the deliverable through its primary interface as a first-time user would — clean checkout, README quickstart, the goal's example interactions plus obvious variants and wrong inputs — fixing in-scope breakage, logging what was exercised, and carrying out-of-scope findings into the candidate-milestone proposals
- resume interrupted work: at session start, uncommitted working-tree changes are in-flight work to reconcile against the first unchecked milestone and the newest `docs/log.md` entry, then finish or back out — not a clean slate
- record decision-shaped changes as `status: proposed` ADRs and implement against them, while goal changes and accepted-ADR supersession stay with the owner
- carry the ADR review mechanics: the owner finds pending decisions by scanning for `status: proposed` or running `bash scripts/okf pending`; accepting flips the status and binds future work; rejecting reverts the work per the ADR's rollback trigger; the owner may direct Claude Code to make the status edit and any reversal
- when the goal is met, list any ADRs still `status: proposed` in the goal-met report, and propose candidate next milestones sourced from `docs/log.md` known items, ADR revisit triggers, acceptance-pass findings, and extensions within the stated non-goals — flagging options that need a non-goal revision separately — and add nothing to `docs/GOAL.md` without the owner's confirmation
- hold standing guardrails: verification must pass before a milestone is checked off; failing tests must never be deleted, skipped, or weakened to force green; secrets must never enter tracked files and env/credential files must be confirmed git-ignored; environment variables are documented in a committed `.env.example` with placeholder values only; security-sensitive changes go through `adr-suggest` and get a proposed ADR when flagged; new runtime dependencies need a proposed ADR; force pushes, data deletion or migration, out-of-scope file deletion, publishing, deploying, releasing, and external side-effecting calls need the owner's explicit go-ahead

The installed `CLAUDE.md` must also carry the kit version policy (ADR 0010): when the SessionStart hook reports `kit_version` drift, tell the owner and recommend re-running `scripts/update-existing-repo` from an up-to-date kit clone, noting that the updater never overwrites and that reviewing numbered candidates is the owner's decision.

# Install docs

`README.md` must include step-by-step instructions for new repos and existing repos.

`README.md` must begin with a clear plain-language section that explains what the kit does before listing install files.

`README.md` must include a table of contents near the top that links to the main usage and verification sections.

`README.md` must describe the goal-iteration loop and its standing guardrails.

`README.md` must describe upgrading an installed repo: the session-start kit-version drift note, re-running `scripts/update-existing-repo` from an up-to-date kit clone, and reviewing the numbered candidates and backups it produces (ADR 0010).

`README.md` and the guide must state the enforcement caveat plainly: the kit's mechanical enforcement is the docs-sync hooks plus the env-file read denial (ADR 0011); every other guardrail — tests, wider security rules, destructive-action gates — is instruction-level in the installed `CLAUDE.md`, and repos that need guaranteed gates add them in their own CI and branch protection (ADR 0007).

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
