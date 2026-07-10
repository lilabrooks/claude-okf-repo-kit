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

`bash scripts/okf draft [paths...]` writes fact-based spec drafts under `docs/specs/_drafts/`. It is aimed at existing codebases with undocumented modules; greenfield repos usually write specs as modules land.

`bash scripts/okf adr-suggest` prints ADR candidates for decision-shaped changes, each with a matching `new-adr` scaffold command.

`bash scripts/okf new-adr <slug> [title...]` scaffolds the next-numbered ADR with `status: proposed` and indexes it.

`bash scripts/okf new-spec <slug> [title...]` scaffolds a spec skeleton and indexes it.

`bash scripts/okf pending` lists ADRs still `status: proposed` and flags ADRs missing a status field.

# Map discovery

After installation, the helper reads `docs/okf-map.yml`.

In this source-kit repo, it may also read root `okf-map.yml` as the install template when `docs/okf-map.yml` is absent.

# Stale mapping behavior

`check-stale` uses repo-relative changed files from Git.

For each changed source file mapped in `docs/okf-map.yml`, the check passes when at least one mapped spec or ADR changed.

A changed `docs/log.md` also passes as the documented rationale path when no spec or ADR edit is warranted.

The check ignores workflow files such as `docs/`, `.claude/`, `CLAUDE.md`, `CLAUDE.local.md`, and `scripts/okf`.

Outside hook mode, `check-stale` also prints a non-blocking note listing changed implementation files that match no mapping, so new source areas get mapped as they gain governing docs. Repo-meta files (README, changelog, license, ignore and editor config, `.env.example`) are excluded from the note, and unmapped files never change the exit status. Hook mode stays silent about unmapped files to avoid false blocks.

# Draft behavior

`draft` must write to `docs/specs/_drafts/`.

Drafts are review-only scaffolding. They must not be treated as accepted specs until a human or agent rewrites and promotes them into `docs/specs/`.

Drafts may include observable facts such as file counts, language extensions, public surface clues, tests found, and mapped docs.

# ADR suggestion behavior

`adr-suggest` must stay conservative.

It may suggest ADRs for dependency, persistence, cache, queue, worker, scheduler, auth, security, privacy, API, deployment, or ownership-boundary changes.

It should stay quiet for local refactors, formatting, test-only changes, and bug fixes that do not create a standing decision.

# Scaffolding behavior

`new-adr` computes the next four-digit number from existing `docs/adr/NNNN-*.md` files, writes frontmatter with at least `type: ADR`, a title, a timestamp, and `status: proposed`, and lays out the required sections: status, context, decision, alternatives considered, consequences, and rollback/revisit trigger.

`new-spec` writes `docs/specs/<slug>.md` with `type: Spec` frontmatter and purpose, contract, and verification sections; the contract section prompts for the example interactions users actually give the surface, including a rejected or edge input.

Both commands append an entry to the matching `index.md` (creating it with its heading when missing), refuse to overwrite existing files, and emit bracketed placeholders the author must fill — a scaffold is a skeleton, not a decision or a contract.

# Pending review behavior

`pending` scans `docs/adr/*.md` for a frontmatter `status:` field, excluding the index and installer-written numbered review candidates (`*.N.md`), which are not live ADRs. It lists files whose status is `proposed` with their titles, and separately flags files with no status field, since those are invisible to the proposed-ADR review scan. It is informational and always exits zero.
