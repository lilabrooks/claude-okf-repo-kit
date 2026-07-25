---
type: ADR
title: Autonomous iteration guardrails
description: Let the installed template run the goal loop unattended - proposed ADRs for decisions, plus test, security, and destructive-action guardrails.
tags: [autonomy, guardrails, template, security]
generated: { by: claude-code/fable-5, at: 2026-07-08T00:00:00Z }
owner: Lila Brooks
deciders: [Lila Brooks]
status: accepted
---

# Status

Accepted

# Context

The kit's target workflow is spec-driven autonomy: the repo owner provides the goal in `docs/GOAL.md`, then Claude Code makes the decisions that reach it and iterates until the goal is met. ADR 0006 gave installed repos the goal backlog, but the installed `CLAUDE.md` still gated every architectural change on owner review before implementation and defined "continue" as a single milestone. Run unattended, that loop either stalls at the first real decision or proceeds with no stated rules for tests, secrets, or destructive actions.

The kit cannot enforce these rules mechanically: target repos own their runtimes, test commands, and CI (a stated non-goal), and the kit's only hooks are the docs-sync guardrails of ADR 0003. Instruction-level guardrails in the installed `CLAUDE.md` are the portable option.

# Decision

`templates/CLAUDE.md` carries an autonomous iteration contract:

- Bootstrap with the owner: when `docs/GOAL.md` or `CLAUDE.md` still contains template placeholders, Claude Code fills them with the owner before the first milestone task. The owner supplies the goal, constraints, and real commands; Claude drafts the rest for confirmation.
- Loop until done: "continue" means take the first unchecked milestone, verify, check off, log, and move to the next, stopping when the backlog is empty, a reserved decision comes up, or the owner says stop. When all milestones are checked and the success criteria pass, Claude reports the goal met instead of inventing scope.
- Decision policy: implementation choices inside existing specs, accepted ADRs, and the guardrails are Claude's to make without asking. Decision-shaped changes (dependency, persistence, cache/queue/worker, auth/security/privacy, API contract, deployment, ownership boundary) start with a self-authored ADR marked `status: proposed`; Claude implements against it and flags it for asynchronous owner review. Changing `docs/GOAL.md` and superseding or contradicting an accepted ADR remain owner decisions.
- Standing guardrails, held in every session:
  - Verification: the test command runs after every change; a milestone is never checked off with failing tests; failing tests are never deleted, skipped, or weakened to force green; outcomes are reported as they are.
  - Security: no secrets in tracked files; env and credential files are confirmed git-ignored before creation; auth, session, input-parsing, file-path, network, crypto, and permission changes are security-sensitive and go through `adr-suggest`; new runtime dependencies need a proposed ADR naming the maintenance and security tradeoff.
  - Owner-gated actions: force pushes and history rewrites on shared branches, deleting or migrating stored data, deleting files beyond task scope, publishing, deploying, releasing, and external calls with side effects.

Alternatives considered:

- Keep owner-gated ADR review before any implementation (status quo). Rejected: it stalls unattended iteration at the first decision, defeating the goal loop ADR 0006 set up.
- Enforce test and security gates with more hooks or installed CI. Rejected: the kit cannot know target-repo toolchains or platforms, and heavier hooks would misfire across ecosystems. Owners who need hard gates add them to their own CI.

# Consequences

An installed repo can run "continue until the goal is met" unattended. The owner reviews decisions asynchronously by scanning `docs/adr/` for `status: proposed` entries and reading `docs/log.md`.

Propose-then-implement means an owner may revert work built on an ADR they reject; the rollback or revisit trigger required in every proposed ADR is what keeps that reversal tractable.

The guardrails are instructions, not enforcement. The docs-sync hooks still only enforce knowledge updates.

Revisit trigger: if unattended sessions routinely produce rejected proposed ADRs or guardrail violations, tighten back toward owner-gated review via a superseding ADR.
