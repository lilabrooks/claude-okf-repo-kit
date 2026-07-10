---
type: Spec
title: Claude hooks
description: Stop and SessionStart hook behavior for the installed kit.
tags: [claude-code, hooks, docs]
timestamp: 2026-07-05T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Purpose

The installed kit uses Claude Code hooks to keep code changes tied to project knowledge.

# Settings

The source `settings.json` installs:

- a `SessionStart` hook for OKF version checks
- a `Stop` hook for docs sync checks
- `permissions.deny` rules `Read(./.env)` and `Read(./**/.env)` that block reading local env files, keeping secrets out of conversation context (ADR 0011)

Hook commands must invoke scripts with `bash` so executable bits are not required.

The deny set must not use an `.env.*` glob: deny rules cannot be negated, and the committed `.env.example` must stay readable so Claude Code can document and consult required variables. Repos with real-secret variant files extend the deny list in their own settings.

# Stop hook

`.claude/hooks/check-docs-sync.sh` blocks when implementation files changed and no file under `docs/` changed.

If `scripts/okf` exists in the target repo, the Stop hook also runs `bash scripts/okf check-stale` in hook mode.

README, changelog, license, `.gitignore`, `.editorconfig`, Claude local memory, and hook/helper files are not treated as implementation files.

The hook emits JSON for Claude Code and exits successfully, allowing Claude Code to continue the turn rather than treating the hook itself as a shell failure.

# SessionStart hook

`.claude/hooks/check-okf-version.sh` checks the declared `okf_version` in `docs/index.md` against the latest OKF spec version published by the official OKF repo.

The same hook also checks the declared `kit_version` in `docs/index.md` — stamped by the installers — against the kit's published `VERSION` file on the source repo's main branch (ADR 0010). It stays silent when `docs/index.md` carries no `kit_version` stamp.

The hook fails silent when offline or when the upstream spec or version file cannot be parsed.

When drift is detected, the hook injects context for Claude Code rather than modifying files directly. OKF and kit drift notes are combined into a single context injection. The installed `CLAUDE.md` version policies tell Claude Code what to do with each note.

# Version migration policy

Minor OKF version bumps may be migrated automatically before the first task of a session.

Major OKF version bumps require a migration summary and user approval before editing docs.

Version migrations must only change formatting, frontmatter, and structure. They must not rewrite spec or ADR content.
