---
type: Playbook
title: Claude Code OKF kit repo instructions
description: Project-specific objective, grounding rules, and workflow for maintaining this source kit.
tags: [claude-code, okf, agent-instructions, adr, specs]
timestamp: 2026-07-08T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Master objective

Current state: This repo is a source kit for installing a Claude Code OKF workflow into other repositories. It contains install artifacts, safe installer scripts, validation targets, and its own OKF knowledge bundle.

Target state: The source kit remains easy to review, safe to install into new or existing repos, and governed by its own specs and ADRs under `docs/`.

Constraints: Follow `docs/specs/repo-kit-packaging.md`, `docs/specs/installer-scripts.md`, `docs/specs/okf-helper-command.md`, `docs/specs/claude-hooks.md`, `docs/specs/validation-workflow.md`, and `docs/specs/dogfood-harvest.md`. Follow ADRs in `docs/adr/`. Root `templates/CLAUDE.md` is the install template for target repos; root `CLAUDE.md` is only for this source repo.

Done when: `make test` passes, `bash scripts/okf check-stale` reports current mappings, and any changed behavior is reflected in the mapped spec, ADR, or `docs/log.md`.

# Preloaded context

These imports resolve when Claude Code loads this file, so the goal and the knowledge indexes are in context at session start without a read step:

@docs/GOAL.md
@docs/specs/index.md
@docs/adr/index.md

# Goal iteration

`docs/GOAL.md` carries this repo's detailed goal: problem, target state, success criteria, non-goals, and the milestone backlog. The Master objective above is its one-screen summary; keep the two consistent, with `docs/GOAL.md` carrying the detail.

- `docs/GOAL.md` is preloaded by the import above. Re-read it during a session only after it changes.
- When asked to continue or iterate without a specific task, take the first unchecked milestone and run it through the task workflow below.
- Resuming after an interruption: at session start, if the working tree holds uncommitted changes, treat them as in-flight work from a cut-off session. Reconcile them against the first unchecked milestone and the newest `docs/log.md` entry, then finish that work or back it out before taking new work.
- Check a milestone off only when its stated verification passes, then add a dated `docs/log.md` entry.
- Changing `docs/GOAL.md` (scope, success criteria, milestone order) is the owner's decision.

# Source-kit layout

Install artifacts:

- `templates/CLAUDE.md` — template copied to target repo `CLAUDE.md`.
- `templates/GOAL.md` — goal template copied to target repo `docs/GOAL.md`.
- `templates/skills/okf-*/SKILL.md` — workflow skills copied to target repo `.claude/skills/okf-*/SKILL.md` (ADR 0015).
- `settings.json` — copied to target repo `.claude/settings.json`.
- `okf-map.yml` — copied to target repo `docs/okf-map.yml`.
- `scripts/okf` — copied to target repo `scripts/okf`.
- `scripts/check-docs-sync.sh` — copied to target repo `.claude/hooks/check-docs-sync.sh`.
- `scripts/check-okf-version.sh` — copied to target repo `.claude/hooks/check-okf-version.sh`.

Source-only files:

- `CLAUDE.md` — this repo's project instructions.
- `README.md` and `Claude Code OKF Kit Guide.md` — user-facing docs.
- `docs/` — this repo's OKF goal, specs, ADRs, log, and source map. `docs/GOAL.md` is this repo's own goal file, distinct from the `templates/GOAL.md` install artifact.
- `Makefile` — source-kit validation.
- `VERSION` — the kit release version; installers stamp it into targets as `kit_version`, and it must be bumped when installed behavior changes (ADR 0010).
- `scripts/create-new-repo` and `scripts/update-existing-repo` — source-only installer scripts.
- `scripts/harvest-dogfood` — source-only maintainer tool reporting deltas from registered installed repos; its registry is machine-local under the git-ignored `.okf-kit-backups/` (ADR 0014).

# Grounding rules

- The spec and ADR indexes are preloaded by the imports above. Before changing files, read the mapped governing docs in `docs/okf-map.yml` for the files being touched.
- When code and docs disagree, flag the mismatch. Do not silently pick a side.
- If a change conflicts with an accepted ADR, stop and ask before editing. Superseding an ADR requires a new ADR.
- Keep the root install template and this repo's project instructions distinct. Do not put project-specific source-kit goals into `templates/CLAUDE.md`.
- Keep `README.md`, `Claude Code OKF Kit Guide.md`, specs, ADRs, scripts, and Makefile behavior in sync.

# Workflow for each task

1. Impact analysis: name the specs and ADRs that govern the files being changed.
2. Implement the smallest change that satisfies the request.
3. Update mapped specs, ADRs, indexes, and `docs/log.md` when behavior, install shape, verification, or decisions change.
4. Run `bash scripts/okf check-stale`.
5. Run `bash scripts/okf adr-suggest` for dependency, persistence, cache/queue/worker, auth/security/privacy, API, deployment, installer, validation, or ownership-boundary changes.
6. Run `make test`.

# Verification commands

- Full validation: `make test`
- Docs-only fast gate (ADR status flips, log-only edits): `make check-docs`
- OKF stale map: `bash scripts/okf check-stale`
- Helper command sanity: `bash scripts/okf adr-suggest`

# Ignore policy

Keep these ignored:

```gitignore
.DS_Store
.obsidian/
.claude/settings.local.json
CLAUDE.local.md
.okf-kit-backups/
.env
.env.*
!.env.example
*.log
__pycache__/
*.py[cod]
```
