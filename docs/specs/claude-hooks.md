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

`.claude/hooks/check-docs-sync.sh` blocks when implementation files changed and no file under `docs/` changed — but only while `docs/okf-map.yml` (or root `okf-map.yml`) carries no active mapping, or `scripts/okf` is missing. Once mappings exist, the stale-mapping check below is the authority and the docs/-prefix gate stands down (ADR 0018): mapped governing docs may live outside `docs/` — machine-readable contract schemas, for example — and count as documentation, while unmapped source changes surface through `check-stale`'s non-blocking note instead of a hard block. The block message names `docs/okf-map.yml` so the agent learns the mapped path.

If `scripts/okf` exists in the target repo, the Stop hook also runs `bash scripts/okf check-stale` in hook mode.

README, changelog, license, `.gitignore`, `.editorconfig`, Claude local memory, hook/helper files, and agent config — `.claude/`, `CLAUDE.md`, plus a second agent's `.codex/` and `AGENTS.md` when present — are not treated as implementation files. File-name exclusions are end-anchored exact matches (so `LICENSE-MIT` or `CLAUDE.md.bak` count as code); directory exclusions keep prefix semantics.

The hook honors `stop_hook_active` from the hook stdin payload: after a prior block in the same stop cycle it warns on stderr and allows the stop instead of blocking again, so a session that cannot write to `docs/` (a read-only sandbox, for example) never loops. Manual runs without a stdin payload behave as if the guard were absent.

The hook emits JSON for Claude Code and exits successfully, allowing Claude Code to continue the turn rather than treating the hook itself as a shell failure. Its block message points at the repo playbook (`CLAUDE.md`; `AGENTS.md` if present) rather than a single agent's file, and both hooks resolve the repo root through `CLAUDE_PROJECT_DIR`, then `CODEX_PROJECT_DIR`, then the current directory, so unmodified copies work when mirrored into another agent's hook config.

# SessionStart hook

`.claude/hooks/check-okf-version.sh` checks the declared `okf_version` in the stamp file — `docs/index.md` by default; the `layout: stamp_file` key in `docs/okf-map.yml` relocates it (ADR 0018) — against the latest OKF spec version published by the official OKF repo. When the stamp file is absent or declares no `okf_version`, the check stays silent and skips the network fetch entirely — the same absent-stamp contract `kit_version` has always had — so brownfield repos without a bundle root are not nagged every session.

The same hook also checks the declared `kit_version` in the same stamp file — stamped by the installers — against the kit's published `VERSION` file on the source repo's main branch (ADR 0010). It stays silent when the stamp file carries no `kit_version` stamp.

The hook fails silent when offline or when the upstream spec or version file cannot be parsed.

The same hook also reports the ADR review inbox: it counts files under the ADR home (`docs/adr/` by default, per the layout block) whose status is `proposed`, skipping `index.md` and installer-written numbered candidates — the same files `bash scripts/okf pending` lists, with the same tolerant status detection (frontmatter `status:`, then a `- Status:` bullet, then a `# Status` section, normalized to the lowercased first word; ADR 0018) — and notes the count so proposed decisions stay visible every session instead of only in the goal-met report. This check is local and offline; it stays silent at zero.

When anything is detected, the hook injects context for Claude Code rather than modifying files directly. OKF drift, kit drift, and the ADR inbox note are combined into a single context injection. The installed `CLAUDE.md` policies tell Claude Code what to do with each note.

# Version migration policy

Minor OKF version bumps may be migrated automatically before the first task of a session.

Major OKF version bumps require a migration summary and user approval before editing docs.

Version migrations must only change formatting, frontmatter, and structure. They must not rewrite spec or ADR content.
