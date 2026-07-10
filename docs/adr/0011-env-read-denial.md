---
type: ADR
title: Env-file read denial in shipped settings
description: Ship permissions.deny Read rules for local env files in settings.json, converting part of the secrets guardrail from instruction to enforcement.
tags: [security, permissions, settings, secrets]
timestamp: 2026-07-09T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
status: accepted
---

# Status

Accepted (authored per the decision policy; accepted by the owner on 2026-07-09)

# Context

The kit's security guardrail keeps secrets out of tracked files: `.env` is git-ignored by the installers and the installed `CLAUDE.md` forbids writing secrets to anything committed. But gitignore only keeps secrets out of commits. Claude Code can still `Read` a `.env` sitting on disk, which puts the secret into conversation context and transcripts — the exact exfiltration path the guardrail exists to close, and one the kit's stated enforcement caveat admits is instruction-level only.

Claude Code has no native `.claudeignore` (open upstream feature requests; a third-party PreToolUse hook emulates it). Its supported access-control mechanism is `permissions.deny` rules in `.claude/settings.json`, e.g. `Read(./.env)`. The kit already ships `settings.json`; it carried only hooks.

# Decision

- `settings.json` ships a `permissions.deny` block with `Read(./.env)` and `Read(./**/.env)`, blocking reads of local env files at the repo root and in subdirectories.
- The deny set deliberately excludes `.env.*` globs: deny rules cannot be negated, so a `Read(./.env.*)` pattern would also block the committed `.env.example` that the kit's own conventions require Claude Code to read and maintain. Owners who use variant files with real secrets (such as `.env.local`) extend the deny list in their own settings.
- Read denial only: writing is not denied, because Claude Code cannot leak a secret it cannot read, the guardrail already forbids writing secrets, and a Write denial would block scaffolding work the conventions allow.
- `update-existing-repo` merges the kit's `permissions` rules into an existing `.claude/settings.json` the same way it merges hooks — union by exact rule, preserving the target's own entries — so existing installs receive the denial on upgrade.
- `verify-install` fails when the installed settings lack the two deny rules, matching how required hook commands are enforced.
- The enforcement caveat in README, guide, and site changes from "docs-sync hooks are the only mechanical enforcement" to name both mechanical guardrails: docs-sync hooks and the env-file read denial.

Alternatives considered:

- Ship a `.claudeignore` file. Rejected: Claude Code does not support one, so it would be false security — worse than no mechanism, since users would assume protection that does not exist.
- Ship a PreToolUse hook implementing `.claudeignore` semantics. Rejected: invents nonstandard behavior upstream may ship natively, adds an installed file and merge surface, and the native deny rules already cover the secrets case.
- Deny broader secret patterns (`secrets/**`, key files). Rejected for the default: a generic kit cannot know which paths hold real secrets in every repo; false denials on fixtures or samples would train users to delete the block. The env-file convention is the kit's own, so it is the defensible default; the ADR records that owners extend per repo.

# Consequences

Secrets in local env files stay out of Claude Code's context mechanically, not by instruction. The installed `CLAUDE.md` tells Claude Code the denial exists and not to work around it — if a task seems to need `.env` contents, it stops and asks the owner.

Debugging flows that legitimately need env values now require the owner: either read the value themselves or add a scoped allow in personal `settings.local.json` (note deny wins over allow in the same scope, so a true override means removing the rule locally, which stays uncommitted).

The settings merge surface grows: `merge_settings` unions `permissions` as well as hooks, and idempotency smoke tests cover both.

# Rollback / revisit trigger

Remove the `permissions` block from `settings.json`, the merge branch, and the `verify-install` check; existing installs keep their merged copy until edited, and the caveat wording reverts. Revisit if Claude Code ships native `.claudeignore` support (adopt it and supersede this ADR) or if the deny syntax or precedence semantics change upstream.
