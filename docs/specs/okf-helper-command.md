---
type: Spec
title: OKF helper command
description: Expected behavior for the repo-local scripts/okf helper.
tags: [okf, bash, cli]
timestamp: 2026-07-05T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Purpose

`scripts/okf` is a repo-local Bash helper included with this kit.

It is not an official OKF CLI, not a global command, and not a prompt.

# Commands

`bash scripts/okf check-stale` checks whether changed source files have a changed mapped spec or ADR.

`bash scripts/okf draft [paths...]` writes fact-based spec drafts under `docs/specs/_drafts/`.

`bash scripts/okf adr-suggest` prints ADR candidates for decision-shaped changes.

# Map discovery

After installation, the helper reads `docs/okf-map.yml`.

In this source-kit repo, it may also read root `okf-map.yml` as the install template when `docs/okf-map.yml` is absent.

# Stale mapping behavior

`check-stale` uses repo-relative changed files from Git.

For each changed source file mapped in `docs/okf-map.yml`, the check passes when at least one mapped spec or ADR changed.

A changed `docs/log.md` also passes as the documented rationale path when no spec or ADR edit is warranted.

The check ignores workflow files such as `docs/`, `.claude/`, `CLAUDE.md`, `CLAUDE.local.md`, and `scripts/okf`.

# Draft behavior

`draft` must write to `docs/specs/_drafts/`.

Drafts are review-only scaffolding. They must not be treated as accepted specs until a human or agent rewrites and promotes them into `docs/specs/`.

Drafts may include observable facts such as file counts, language extensions, public surface clues, tests found, and mapped docs.

# ADR suggestion behavior

`adr-suggest` must stay conservative.

It may suggest ADRs for dependency, persistence, cache, queue, worker, scheduler, auth, security, privacy, API, deployment, or ownership-boundary changes.

It should stay quiet for local refactors, formatting, test-only changes, and bug fixes that do not create a standing decision.
