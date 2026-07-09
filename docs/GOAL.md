---
type: Goal
title: Source-kit goal
description: The goal, success criteria, and milestone backlog for the Claude Code OKF repo kit itself.
tags: [goal, milestones, source-kit]
timestamp: 2026-07-07T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Goal

Kind: utility

Problem: Repos driven by Claude Code lose their goal, contracts, and decisions between sessions, and wiring up an OKF-style docs workflow (specs, ADRs, map, hooks, helper) by hand in every repo is error-prone.

Solution: A reviewable source kit that installs a complete Claude Code OKF workflow into new or existing repositories: instruction and goal templates, shared settings with guardrail hooks, a repo-local `scripts/okf` helper, and safe installer scripts.

# Target state

- Install artifacts (`templates/CLAUDE.md`, `templates/GOAL.md`, `settings.json`, `okf-map.yml`, `scripts/okf`, `scripts/check-docs-sync.sh`, `scripts/check-okf-version.sh`) stay reviewable at predictable source paths and copy to the destinations in `docs/specs/repo-kit-packaging.md`.
- `scripts/create-new-repo` and `scripts/update-existing-repo` set up target repos without overwriting existing files, per `docs/specs/installer-scripts.md`.
- The kit validates itself with `make test` (syntax, helper behavior, installer smoke tests) per `docs/specs/validation-workflow.md`.
- This repo is governed by its own OKF bundle under `docs/`, dogfooding the workflow the kit installs.

# Success criteria

- `make test` passes.
- `bash scripts/okf check-stale` reports current mappings.
- Changed behavior is reflected in the mapped spec, ADR, or `docs/log.md`.
- Both installers produce a target repo that passes `scripts/verify-install`.

# Non-goals

- An official or global OKF CLI; `scripts/okf` is a repo-local Bash helper only.
- Enforcing strict OKF document-schema validation in target repos; targets own stricter checks when needed.
- Managing target-repo application code, dependencies, or CI beyond the installed kit files.

# Constraints

- Specs: `docs/specs/repo-kit-packaging.md`, `docs/specs/installer-scripts.md`, `docs/specs/okf-helper-command.md`, `docs/specs/claude-hooks.md`, `docs/specs/validation-workflow.md`.
- ADRs: all accepted ADRs in `docs/adr/`.
- Bash-only tooling; no runtime dependency manifests.

# Milestones

Ordered backlog. Check a milestone off only when its verification passes, and
record progress in `docs/log.md`. Adding or reordering milestones is the
owner's decision.

- [x] OKF knowledge bundle for this repo: specs, ADRs, indexes, log, source map. Verified: `bash scripts/okf check-stale` runs against `docs/okf-map.yml`.
- [x] Repo-local `scripts/okf` helper with `check-stale`, `draft`, `adr-suggest` (ADR 0002). Verified: `make test` helper checks.
- [x] Claude hook guardrails: Stop docs-sync hook and SessionStart version hook (ADR 0003). Verified: `make test`.
- [x] Source-kit validation Makefile with temp-repo smoke tests (ADR 0004). Verified: `make test`.
- [x] Safe installer, verify, and placeholder scripts for new and existing repos (ADR 0005). Verified: `make test` installer smoke tests.
- [x] Goal file template installed to target `docs/GOAL.md` (ADR 0006). Verified: `make test` and `scripts/verify-install`.
- [x] Autonomous iteration contract in the installed template (ADR 0007): owner-filled bootstrap, loop-until-done milestones, proposed-ADR decision policy, and test/security/destructive-action guardrails. Verified: `make test`.
- [x] Session context preloading (ADR 0008): `@` imports of `docs/GOAL.md` and the spec/ADR indexes in the installed template and this repo's `CLAUDE.md`, with smoke coverage. Verified: `make test`.
- [x] Source-kit website (ADR 0009): `site/` on `main` deployed by the GitHub Pages Actions workflow, documenting how Claude Code works with an installed repo. Verified: `make test`; publishing awaits the owner's Pages toggle recorded in README Repository settings.
- [ ] (backlog empty — new milestones are added here by the owner)
