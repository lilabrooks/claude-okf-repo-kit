---
type: Goal
title: Source-kit goal
description: The goal, success criteria, and milestone backlog for the Claude Code OKF repo kit itself.
tags: [goal, milestones, source-kit]
generated: { by: claude-code/opus-4.8, at: 2026-07-07T00:00:00Z }
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
- The existing-repo updater rejects hostile layout paths before creating a backup or writing inside or outside the target.

# Non-goals

- An official or global OKF CLI; `scripts/okf` is a repo-local Bash helper only.
- Enforcing strict OKF document-schema validation in target repos; targets own stricter checks when needed.
- Managing target-repo application code, dependencies, or CI beyond the installed kit files.

# Constraints

- Specs: `docs/specs/repo-kit-packaging.md`, `docs/specs/installer-scripts.md`, `docs/specs/okf-helper-command.md`, `docs/specs/claude-hooks.md`, `docs/specs/validation-workflow.md`, `docs/specs/dogfood-harvest.md`.
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
- [x] First-iteration capture upgrades from the repo-pulse dogfood run (ADR 0010): goal-interview example-interactions question and canonical-command convention, pre-goal-met acceptance pass with pending-ADR listing, env-file/README/bootstrap conventions in templates and installers, `okf new-adr`/`new-spec`/`pending` scaffolding, `check-stale` unmapped-file note, and a kit `VERSION` stamp with SessionStart drift reporting. Verified: `make test`.
- [x] Env-file read denial in shipped settings (ADR 0011): `permissions.deny` Read rules for `.env` files in `settings.json`, permissions merged by the existing-repo installer, `verify-install` and smoke coverage, and the enforcement caveat updated to name both mechanical gates. Verified: `make test`.
- [x] Stale-candidate refresh in the updater (ADR 0012): digest manifest under `.okf-kit-backups/`, in-place refresh of provably kit-written candidates with owner-edited ones untouched, smoke-tested across simulated kit releases. Verified: `make test`.
- [x] Dogfood-driven 0.1.2 hardening from the repo-pulse and skywatch outcomes (ADR 0013): shipped-hook union (stop-loop guard, end-anchored and agent-config exclusions, portable root resolution and playbook wording), SessionStart ADR review inbox, kit-managed script provenance in both installers (manifest seeding, preserve-or-refresh updater), interview tool-availability rule, goal-met repo-hygiene candidates, starter-map granularity hint, and the optional second-agent recipe in the README. Verified: `make test`.
- [x] Dogfood harvest tooling (ADR 0014): source-only `scripts/harvest-dogfood` with a machine-local registry under `.okf-kit-backups/`, delta reports (commits, new log entries with kit-mention flags, script provenance, ADR inbox, version stamp, agent-config surfaces), read-only against targets, with spec, smoke coverage, and README note. Verified: `make test` and a live report against the registered repos.
- [x] Workflow skills and cross-repo query, kit 0.1.3 (ADR 0015): the four `okf-*` skills installed to `.claude/skills/` carrying the expanded interview/acceptance/ADR-review/upgrade procedures with the template dieted to binding one-liners, skills ride the provenance manifest through both installers and `verify-install`; plus `harvest-dogfood index`/`query` for derived cross-repo knowledge lookups. Verified: `make test` and a live query against the registered repos.
- [x] Composition hardening from the python-cli-template stack template, kit 0.3.3 (ADRs 0022, 0023): commented `@`-import shim tolerance in the updater, installer summary labels pinned as a stable output contract with smoke assertions on both installers, unresolved-candidate reporting in the SessionStart hook and `verify-install`, special-character target-path smoke coverage, and the `.env` loading caveat in the installed template's env guardrail. Verified: `make test`.
- [x] Kit-managed second-agent mirror sync, kit 0.3.4 (ADR 0021 accepted): `mirrors:` declaration in the target map, updater sync of declared hook mirrors through the ADR 0013 provenance path, `verify-install` parity warnings, mappings-parser hardening against top-level list leakage, and the `okf-kit-upgrade` step reframed from manual re-sync to mirror check. Verified: `make test`.
- [x] Second-agent port skill and undeclared-mirror advisories, kit 0.3.5 (ADR 0024 accepted): the `okf-second-agent` skill carrying the canonical port procedure wired through both installers and the nine-entry manifest, warn-only undeclared-mirror advisories in `verify-install` and the SessionStart hook (ADR 0021 amendment), a SessionStart map-coverage note for mapping-less maps, and a declaration-aware harvest second-agent note. Verified: `make test`.
- [x] Import-before-heading shim classification, kit 0.3.6 (ADR 0025 accepted): `is_import_shim` disqualifies on a heading only when the `@AGENTS.md` import sits under it, budget raised to 15 non-blank lines, third brownfield smoke edge for the spec-drift shim shape, ADR 0022 amendment. Verified: `make test`.
- [x] Fleet-run harvest batch, kit 0.3.7: filled-goal heading tolerance with smoke coverage, the pipefail hazard-class scan in `make scan` (which caught two further live sites in `install-kit` and `harvest-dogfood`), and skill enrichment — template-delta candidate review in `okf-kit-upgrade`, the canonical AGENTS-side port paragraph in `okf-second-agent`, diff-scoped gate validation in `okf-adopt`. Verified: `make test`.
- [x] Updater review aids and pairing advisories from the spec-agent-cli 0.3.0→0.3.7 upgrade, kit 0.3.8: an `Advisories:` summary section (appended under ADR 0023's allowance) carrying the undeclared-mirror advisory with the ready-to-name `mirrors:` declaration (detected against pre-refresh originals), second-agent skill-pairing gaps after releases that add skills, and the playbook template-delta review aid recovered from the kit clone's git history; plus populated-map template-candidate suppression (ADR 0018 spirit). Verified: `make test`.
- [x] Full-kit audit fixes with dual-agent parity, kit 0.3.9: `.agents/` and `Codex.local.md` join the agent-config exclusions in both the Stop hook and `check-stale` (closing the false block the `okf-second-agent` skill's claim promised away), the updater honors `layout: stamp_file` for restamping (one stamp, one authority — no parallel `docs/index.md`), `mirrors:` entries normalize trailing slashes identically across all four parsers, the SessionStart hook escapes its JSON payload, `okf draft` falls back to plain grep without ripgrep, case-insensitive body-status detection, ADR 0023 amended to state the new-label allowance precisely, and README/map-header doc sync (six skills, Advisories, glob semantics). Verified: `make test` plus live scratch-repo repros of all fixed bugs. Deliberately deferred, logged as known-minor: non-contiguous candidate numbering duplicate-content edge, and the coarse any-log-change stale escape hatch.
- [x] Structural-risk gates, kit 0.3.10: the layout and mirrors parsers consolidated into `OKF-SHARED` marked constants (byte-identical across five scripts) with `make parity` enforcing the match; the parity gate also asserts the hook/helper exclusion-list union, the skill roster on every claimed surface (README table row now names the six skills literally), and the ADR 0023 summary labels in pinned order — converting every "must not drift" spec sentence into a build failure. ADR 0026 (Python-stdlib rewrite of the never-installed kit-side tools, trigger-gated; hooks and `scripts/okf` stay standalone bash; accepted 2026-07-21). Verified: `make test` plus negative tests proving the gate fails on divergence, missing blocks, and exclusion drift.
- [x] Upgrade-friction fixes from the live fleet runs, kit 0.3.11: declared mirrors gain a second proof of provenance so a hand-adopted mirror stops re-staging the same no-op candidate every release (ADR 0013 amended), and a kit-derived, fully-filled playbook gets the kit-only template delta instead of the whole bracketed template (ADR 0018's reasoning extended), with the placeholder list shared byte-identical with `check-placeholders` under `make parity`. Verified: `make test` plus an A/B repro against the pre-fix updater.
- [x] Reject unsafe existing-repo layout paths before the updater's first write, with traversal, absolute-path, and symlink-escape fixtures for every layout key. Verified: `make smoke-paths` and `make test`; this is partial remediation only while the installed helper remains unsafe.
- [ ] (backlog empty — new milestones are added here by the owner)
