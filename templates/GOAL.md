---
type: Goal
title: Project goal
description: The goal, success criteria, and milestone backlog Claude Code iterates toward in this repo.
tags: [goal, milestones]
timestamp: 2026-07-07T00:00:00Z
owner: [owner name]
deciders: [owner name]
---

<!-- Template. Fill every [bracket], update the timestamp, then delete this comment.
     This file is the goal Claude Code iterates toward. Keep milestones ordered and
     check one off only when its verification passes. -->

# Goal

Kind: [app | service | utility]

Problem: [who has what problem, 1-2 sentences]

Solution: [what this repo delivers to solve it, concrete nouns]

# Target state

[What exists when the goal is met: modules, interfaces, behaviors.
For an app: the user-facing flows that work end to end.
For a service: the API contracts it serves and to whom.
For a utility: the commands or functions it exposes and their inputs/outputs.]

# Success criteria

Verifiable checks that prove the goal is met:

- [test command that passes]
- [observable behavior: endpoint responds, command produces output, flow completes]
- [quality bar: coverage threshold, benchmark number, size limit]

# Non-goals

- [what this repo deliberately does not do]

# Constraints

- [governing specs and ADRs by path]
- [runtime, dependency, or platform limits]

# Milestones

Ordered backlog. When asked to continue without a specific task, Claude Code
takes the first unchecked milestone. Check a milestone off only when its
verification passes, and record progress in `docs/log.md`.

- [ ] [first shippable slice + how to verify it]
- [ ] [next milestone + how to verify it]
- [ ] [next milestone + how to verify it]
