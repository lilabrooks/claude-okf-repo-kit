---
type: Playbook
title: Claude Code repo instructions
description: Master objective, grounding rules, and workflow for Claude Code in this repository.
tags: [claude-code, agent-instructions, adr, specs]
timestamp: 2026-07-04T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

<!-- Template. Fill every [bracket], update the timestamp, then delete this comment.
     Claude Code ignores the frontmatter; it exists to make this file a valid OKF
     concept (type is the only required field, per OKF v0.1). -->

# Master objective

Current state: [what exists today, 1-2 sentences]

Target state: [what done looks like, concrete nouns]

Constraints: [governing ADRs and specs by path]

Done when: [verifiable criteria: test command, contract coverage, removals]

# Goal iteration

`docs/GOAL.md` defines what this repo is for: the kind of deliverable (app, service, or utility), the problem, the target state, success criteria, and an ordered milestone backlog. The Master objective above is its one-screen summary; keep the two consistent, with `docs/GOAL.md` carrying the detail.

- Read `docs/GOAL.md` before the first task of each session.
- When asked to continue or iterate without a specific task, take the first unchecked milestone and run it through the task workflow below.
- Check a milestone off only when its stated verification passes, then add a dated `docs/log.md` entry.
- When the code and the goal disagree, flag it. Changing `docs/GOAL.md` (scope, success criteria, milestone order) is my decision.
- If `docs/GOAL.md` is missing, create it with these sections and fill it with me before the first milestone task: Goal (kind, problem, solution), Target state, Success criteria, Non-goals, Constraints, Milestones.

# Docs bootstrap

If `/docs/specs` or `/docs/adr` doesn't exist yet, create this structure before the first task:

Installer note: when setting up a repo from outside Claude Code, prefer `bash scripts/create-new-repo <target>` for empty repos or `bash scripts/update-existing-repo <target>` for existing repos. This bootstrap section is the in-session fallback when those scripts were not used.

```
docs/
├── index.md        # bundle root: declares okf_version, links the bundle files
├── GOAL.md         # goal, success criteria, milestone backlog (see Goal iteration)
├── log.md          # dated changelog, newest first
├── okf-map.yml     # maps source paths to governing specs/ADRs
├── specs/
│   ├── index.md    # lists each spec with a one-line description
│   └── _drafts/    # generated spec drafts; review before promoting
└── adr/
    └── index.md    # lists each ADR with a one-line description
```

`docs/index.md` starts with a frontmatter block declaring the OKF version (the bundle root is the only `index.md` allowed frontmatter):

```yaml
---
okf_version: "0.1"
---
```

Every new spec or ADR file gets YAML frontmatter with at least a `type:` field (OKF v0.1), plus `title` and `description`. Keep each `index.md` current when files are added or renamed.

`docs/okf-map.yml` maps source globs to the specs and ADRs that govern them. Keep it current when modules move or new source areas get their own contracts.

# Agent config (committed to the repo)

- `.claude/settings.json` — shared project settings, including the Stop hook that enforces docs sync. Committed.
- `.claude/hooks/check-docs-sync.sh` — Stop hook, invoked via `bash` so no executable bit is needed. Committed. Don't move, rename, or disable it; if it blocks a stop, do the doc update it asks for.
- `.claude/hooks/check-okf-version.sh` — SessionStart hook, invoked via `bash`. Committed. Reports OKF spec version drift; act per the OKF version policy above.
- `scripts/okf` — repo-local OKF helper command. Committed. Use it for stale mapping checks, spec drafts, and ADR suggestions.
- `docs/okf-map.yml` — source-to-knowledge mapping used by `scripts/okf check-stale`. Committed.
- `.claude/settings.local.json` — personal overrides only. Never commit it.
- `CLAUDE.local.md` — personal per-repo memory. Never commit it.

During bootstrap, ensure `.gitignore` contains these 3 entries (the same set the installers append and `verify-install` requires):

```
.claude/settings.local.json
CLAUDE.local.md
.okf-kit-backups/
```

Everything else agent-related is committed: `CLAUDE.md`, `.claude/settings.json`, `.claude/hooks/`, `scripts/okf`, and all of `/docs`.

# OKF version policy

A SessionStart hook compares `okf_version` in `docs/index.md` against the latest spec version on the official OKF repo. When it reports drift:

1. Read the current spec at https://raw.githubusercontent.com/GoogleCloudPlatform/knowledge-catalog/main/okf/SPEC.md and identify what changed.
2. Minor bump (e.g. 0.1 → 0.2): backward-compatible. Migrate automatically, before the first task of the session: update `okf_version` in `docs/index.md`, apply any new formatting or structural conventions across `/docs`, log the migration in `/docs/log.md`. No approval needed.
3. Major bump (e.g. 0.x → 1.0): may contain breaking changes. Stop and present me a migration summary before changing any `/docs` files.

Never modify spec or ADR content as part of a version migration; only formatting, frontmatter, and structure.

# OKF helper commands

`scripts/okf` is a repo-local Bash helper installed by this kit. It is not an official OKF CLI, not a global command, and not a prompt. Always run it with `bash scripts/okf ...` unless this repo intentionally wraps it another way.

- `bash scripts/okf check-stale` — run after changing source files. If it reports stale mappings, update the mapped spec/ADR or add a dated `/docs/log.md` rationale explaining why no knowledge file changed.
- `bash scripts/okf draft [paths...]` — generate fact-based drafts under `/docs/specs/_drafts/`. Treat drafts as scaffolding: verify them, rewrite them into human-readable commitments, then move promoted specs into `/docs/specs/` and update `/docs/specs/index.md`.
- `bash scripts/okf adr-suggest` — run when a change may include an architecture decision. Create a new ADR only when the suggestion points to a real decision: dependency, persistence, cache/queue/worker, auth/security/privacy, API contract, deployment, or ownership boundary.

# Grounding rules (docs are the source of truth)

- Before planning any change, read `/docs/specs/index.md` and `/docs/adr/index.md`, then the specific spec or ADR governing the files you'll touch.
- When code and docs disagree, flag the mismatch. Don't silently pick a side.
- If a task conflicts with an existing ADR, stop and ask before writing code. Superseding an ADR is my decision, made via a new ADR file.
- Architectural changes start with a new ADR in `/docs/adr/` for my review, before any implementation.

# Workflow for each task

1. Impact analysis: name the specs and ADRs that govern the target files.
2. Implement. Run [test command] and make it pass.
3. Knowledge alignment: run `bash scripts/okf check-stale` when available. If behavior or a contract changed, update the governing spec or ADR to match, and add a dated entry to `/docs/log.md`, newest first (ISO `YYYY-MM-DD` headings). If no doc change is warranted, add a one-line entry to `/docs/log.md` saying why. New spec or ADR files also get added to their directory's `index.md`.
4. ADR check: run `bash scripts/okf adr-suggest` for dependency, persistence, cache/queue/worker, auth/security/privacy, public API, deployment, or ownership-boundary changes. Draft an ADR only for a real decision.

# Verification commands

- Tests: [command]
- Lint/typecheck: [command]
- Build: [command, if separate]
- OKF stale map: `bash scripts/okf check-stale`
