---
type: Spec
title: Repo kit packaging
description: Source-kit layout and target repo installation contract for the Claude Code OKF kit.
tags: [claude-code, okf, packaging]
generated: { by: claude-code/opus-4.8, at: 2026-07-08T00:00:00Z }
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
- `templates/skills/okf-goal-interview/SKILL.md`
- `templates/skills/okf-acceptance-pass/SKILL.md`
- `templates/skills/okf-adr-review/SKILL.md`
- `templates/skills/okf-kit-upgrade/SKILL.md`
- `templates/skills/okf-adopt/SKILL.md`
- `templates/skills/okf-second-agent/SKILL.md`
- `templates/AGENTS.md` (opt-in: rendered by the `okf-second-agent` skill during a port, never written by the installers)
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
- `scripts/check-parity.py` (sync gate for the specs' must-not-drift rules: shared parser blocks, exclusion-list union, skill roster, summary labels; validation-workflow spec)
- `scripts/harvest-dogfood` (maintainer tool; its registry is machine-local and git-ignored, per ADR 0014)
- `.github/workflows/test.yml`
- `.github/workflows/pages.yml`
- `.github/dependabot.yml`
- `site/`

The public repo presentation must include a modest README badge set with links for preview status, GitHub Actions tests, Claude Code, OKF, Bash, and specs/ADRs.

The source repo publishes a website from `site/` — static HTML, CSS, and JS with self-hosted fonts and no build step — deployed to GitHub Pages by `.github/workflows/pages.yml` per ADR 0009. `site/` is a multi-page site built on the vendored Compact Theme (`compact-theme.css` + `compact-theme.js`, with light/dark modes and a header toggle, ADR 0017): an `index.html` explainer, a `how-it-works/` installed-behavior walkthrough, a `dogfood/` findings page, legacy redirect stubs, a `404.html`, and `fonts/`. Its purpose is to explain why the kit exists, what it installs, the adoption paths, and the dogfood evidence; the `how-it-works/` page carries the detailed account of how Claude Code works with an installed repo (session context, goal interview, iteration loop, decision policy, guardrails with the enforcement caveat, interrupted-session resume). The README remains the exhaustive file-and-behavior reference the site links to, and the site must stay consistent with the installed template behavior.

Per ADR 0016, `site/` is the single governed source and is also mirrored to the owner's apex user-site (the `lilabrooks.github.io` repo) through a git submodule, so both `https://lilabrooks.github.io/` and `https://lilabrooks.github.io/claude-okf-repo-kit/` render the same files. Because of that, every asset, navigation, and redirect path in `site/` must be relative (not root-relative), and stylesheet `url()` font references relative, so the identical HTML renders at both the apex base and the project base; absolute `canonical`, Open Graph, and schema.org URLs point at the apex. It is source-only: installers never copy `site/` into target repos.

The source repo publishes its release version in a root `VERSION` file (semver, one line) on `main`. It is source-only — never copied to targets — and must be bumped when installed behavior changes, because installed repos compare their stamped `kit_version` against it at session start (ADR 0010).

A `VERSION` bump signals that installed behavior changed, which is exactly when the website can go stale. Any release that bumps `VERSION` must therefore include a review of `site/`: re-read each site claim against the change and update the copy where behavior moved, keeping the editorial voice and honesty framing per the site-content spec. This review step is the real assurance that the site tracks the kit; the `site/index.html` entries in `docs/okf-map.yml` (mapped alongside `templates/CLAUDE.md` and `templates/skills/**`) are only a soft `check-stale` reminder. After updating `site/`, publish per ADR 0016: the project-base Pages redeploys on push, then bump the apex submodule in the `lilabrooks.github.io` repo.

The source repo is proprietary: `LICENSE` reserves all rights, with the source repo's own work under "All Rights Reserved" and carve-outs preserving the third-party licenses of the vendored `site/` assets (Compact Theme under BSD 2-Clause, IBM Plex fonts under the SIL Open Font License).

# Target repo destinations

When installed into a target repo, copy files to these destinations:

- `templates/CLAUDE.md` -> `CLAUDE.md`
- `templates/GOAL.md` -> `docs/GOAL.md`
- `templates/skills/okf-*/SKILL.md` -> `.claude/skills/okf-*/SKILL.md`
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

Specs and ADRs must use YAML frontmatter with at least `type:`. Pre-existing brownfield files are tolerated without it: kit tooling also reads `- Status:` bullets and `# Status` sections, and falls back to the first heading for titles, with frontmatter preferred for new files (ADR 0018).

The spec and ADR indexes live at the layout-configured homes when the target's `docs/okf-map.yml` carries a `layout:` block (`specs_dir`, `adr_dir`, `stamp_file`; ADR 0018); the paths above are the canonical defaults. Mapped governing docs may also be machine-readable contracts (JSON Schemas, OpenAPI, proto) living outside `docs/`.

The bundle root `docs/index.md` declares `okf_version`, and installer-written starter indexes also declare `kit_version` — the kit release that produced the install, read from the source `VERSION` file (ADR 0010) — and link the goal, the spec and ADR indexes, the log, and the source map.

`docs/GOAL.md` is the goal-definition file installed from `templates/GOAL.md`. It must capture the repo kind (app, service, or utility), the problem, the target state, verifiable success criteria, and an ordered milestone backlog. Its success-criteria hints must include input tolerance (realistic input variants work, wrong input gets a clear error), its milestone preamble must require user-facing milestone verifications to name at least one rejected or edge input, and the milestone list must end with a suggested README-quickstart milestone (verification: the quickstart reproduces on a clean checkout) the owner may keep, adjust, or delete. The installed `CLAUDE.md` must instruct Claude Code to read it each session and take the first unchecked milestone when asked to continue without a specific task.

The installed `CLAUDE.md` must preload session context with `@` imports of `docs/GOAL.md`, `docs/specs/index.md`, and `docs/adr/index.md` — the index imports rewritten to the layout homes when the updater detected a non-canonical arrangement (ADR 0018) — and must not import larger or unbounded files such as `docs/log.md` or full specs (ADR 0008).

The expanded procedures for the six episodic workflows — goal interview, acceptance pass, ADR review, kit upgrade, adoption pass, second-agent port — are delivered as installed skills at `.claude/skills/okf-*/SKILL.md` (ADRs 0015, 0020, 0024). The `okf-second-agent` skill must carry the second-agent port (ADR 0024): owner scoping, the playbook port, hook mirroring with the `mirrors:` declaration so the safe updater syncs the copies, owner-managed skill adaptation, the repo-side parity guard, and the commit-and-log step. The playbook-port step must direct the agent to render the kit's curated `templates/AGENTS.md` and carry the owner's filled sections (Master objective, Verification commands) across from the live `CLAUDE.md`, rather than hand-translating the Claude playbook — a find-and-replace port is what produces a file claiming Codex resolves `@` imports, naming kit files that do not exist, and writing `.Codex` for `.codex`. `templates/AGENTS.md` is source-only and opt-in: the installers never write it, and it carries the non-porting mechanics ready-made (session-start reads in place of `@` imports, the Codex config surfaces, the honest policy-only env-file wording, and the self-describing port paragraph), keeping the same bracketed owner sections as `templates/CLAUDE.md`. It must stay structurally paired with `templates/CLAUDE.md` (same section headings, the context section being the one deliberate rename) and free of those three defect classes; `make parity` enforces all of it. The `okf-adopt` skill must carry the brownfield adoption pass (ADR 0020): inventory the repo’s knowledge without moving files, adapt-in-place as the default with migration to canonical only at owner direction (repairing the cross-links, IDs, and CI rules a migration breaks), map population so `check-stale` becomes the authority, draft-based backfill promoted per the target repo’s own conventions and validators, end-to-end validation, and a dated `docs/log.md` record — proposing ADRs for decision-shaped findings instead of deciding them. The installed `CLAUDE.md` keeps a binding compressed form of each that names its skill and stands alone when the skill fails to load; guardrails and loop semantics never move into skills. The contract items below may therefore be satisfied by the resident compressed form, with the named skill carrying the expansion.

The installed `CLAUDE.md` must also carry the autonomous iteration contract (ADR 0007):

- fill placeholder content in `docs/GOAL.md` or `CLAUDE.md` with the owner before the first milestone task, through a structured goal interview: what is being built and for whom, the concrete done state, the example interactions users will actually give the primary interface (including at least one messy or wrong one, phrased per repo kind — typed/pasted input for an app, command lines for a utility, requests for a service), the mechanical verification (with the convention that a new repo's first milestone establishes canonical test and run commands), non-goals, which stack choices are fixed versus decided later through proposed ADRs, and the first shippable slice — the worked examples for each question carried by the `okf-goal-interview` skill, pushing back on answers that cannot be checked mechanically, confirming that any tool a verification step names beyond the repo's own stack is installed (or marking that step owner-gated so the loop expects the pause), proposing answers from an existing codebase where possible, drafting the milestone backlog to end with the README-quickstart milestone by default, and never overwriting goal content the owner wrote by hand
- continue milestone by milestone until the backlog is done, a reserved decision comes up, or the owner stops the loop, and report the goal met when all milestones and success criteria pass instead of inventing scope
- run an acceptance pass before reporting the goal met: exercise the deliverable through its primary interface as a first-time user would — clean checkout, README quickstart, the goal's example interactions plus obvious variants and wrong inputs — fixing in-scope breakage, logging what was exercised, and carrying out-of-scope findings into the candidate-milestone proposals
- resume interrupted work: at session start, uncommitted working-tree changes are in-flight work to reconcile against the first unchecked milestone and the newest `docs/log.md` entry, then finish or back out — not a clean slate
- record decision-shaped changes as `status: proposed` ADRs and implement against them, while goal changes and accepted-ADR supersession stay with the owner
- carry the ADR review mechanics: the owner finds pending decisions by scanning for `status: proposed` or running `bash scripts/okf pending`; accepting flips the status and binds future work; rejecting reverts the work per the ADR's rollback trigger; the owner may direct Claude Code to make the status edit and any reversal
- when the goal is met, list any ADRs still `status: proposed` in the goal-met report, and propose candidate next milestones sourced from `docs/log.md` known items, ADR revisit triggers, acceptance-pass findings, standard repo hygiene the repo still lacks (a license, CI running the verification commands and the stale-map check, dependency-update automation, README badges), and extensions within the stated non-goals — flagging options that need a non-goal revision separately — and add nothing to `docs/GOAL.md` without the owner's confirmation
- hold standing guardrails: verification must pass before a milestone is checked off; failing tests must never be deleted, skipped, or weakened to force green; secrets must never enter tracked files and env/credential files must be confirmed git-ignored; environment variables are documented in a committed `.env.example` with placeholder values only; security-sensitive changes go through `adr-suggest` and get a proposed ADR when flagged; new runtime dependencies need a proposed ADR; force pushes, data deletion or migration, out-of-scope file deletion, publishing, deploying, releasing, and external side-effecting calls need the owner's explicit go-ahead

The installed `CLAUDE.md` must also carry the kit version policy (ADR 0010): when the SessionStart hook reports `kit_version` drift, tell the owner and recommend re-running `scripts/update-existing-repo` from an up-to-date kit clone, noting the updater's non-destructive behavior — kit-managed scripts refresh in place only when provably unedited kit output, everything else lands as numbered candidates (ADRs 0012, 0013) — and that reviewing candidates is the owner's decision.

# Install docs

`README.md` must include step-by-step instructions for new repos and existing repos.

`README.md` must begin with a clear plain-language section that explains what the kit does before listing install files.

`README.md` must include a table of contents near the top that links to the main usage and verification sections.

`README.md` must describe the goal-iteration loop and its standing guardrails.

`README.md` must describe upgrading an installed repo: the session-start kit-version drift note, re-running `scripts/update-existing-repo` from an up-to-date kit clone, and reviewing the numbered candidates and backups it produces (ADR 0010).

`README.md` and the guide must state the enforcement caveat plainly: the kit's mechanical enforcement is the docs-sync hooks plus the env-file read denial (ADR 0011); every other guardrail — tests, wider security rules, destructive-action gates — is instruction-level in the installed `CLAUDE.md`, and repos that need guaranteed gates add them in their own CI and branch protection (ADR 0007).

Existing-repo instructions must avoid overwriting an existing `CLAUDE.md`, `.claude/settings.json`, `.gitignore`, specs, ADRs, map file, or log files.

Existing-repo instructions must describe same-folder numbered candidates for same-name Markdown/map files, and the stale-candidate refresh: the updater refreshes candidates it can prove it wrote (digest manifest under `.okf-kit-backups/`) and never touches owner-edited ones (ADR 0012).

Existing-repo instructions must describe the kit-managed script provenance behavior: scripts refresh in place (after a backup) only when the manifest proves the current content is unedited kit output; owner-edited scripts are preserved with the kit version staged as a numbered candidate for review (ADR 0013).

`README.md` must describe the optional second-agent usage: the goal loop stays with Claude Code; a second agent's committed config (such as `AGENTS.md` and `.codex/`) is tolerated by the shipped hooks as agent config; ported playbooks need explicit session-start reads instead of `@` imports and must state that the env-file read denial is Claude Code-only; hook mirrors declared in the map's `mirrors:` list are synced by the safe updater through the provenance path (ADR 0021), while undeclared mirrors and mirrored skills stay the owner's to keep in sync — `verify-install` and the SessionStart hook flag byte-identical undeclared hook copies with an advisory recommending the declaration (ADR 0024), and the installed `okf-second-agent` skill carries the full port procedure — and a repo that maintains mirrors is still advised to guard the byte-identical invariant with a check in its own test or validation gate (skipped when the second stack is absent), which now serves as belt-and-suspenders for hand edits and undeclared mirrors rather than the only guard.

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
