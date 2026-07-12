# Claude OKF repo kit

[![Status](https://img.shields.io/badge/status-preview-blue)](#project-status)
[![Website](https://img.shields.io/badge/website-live-5D3FD3)](https://lilabrooks.github.io/claude-okf-repo-kit/)
[![Tests](https://github.com/lilabrooks/claude-okf-repo-kit/actions/workflows/test.yml/badge.svg)](https://github.com/lilabrooks/claude-okf-repo-kit/actions/workflows/test.yml)
[![Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-5D3FD3)](#daily-use-after-installation)
[![OKF](https://img.shields.io/badge/docs-OKF%200.1-blue)](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
[![OKF validated](https://img.shields.io/badge/OKF-validated-brightgreen)](#validating-this-kit)
[![Bash](https://img.shields.io/badge/scripts-Bash-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/manual/bash.html)
[![Specs + ADRs](https://img.shields.io/badge/specs%20%2B%20ADRs-included-0A7)](docs/)

## What this kit does

This kit sets up a repo so Claude Code works from project knowledge instead of only reading code and guessing intent.

It gives your repo a small, repeatable structure:

- `CLAUDE.md` tells Claude Code the project goal, rules, workflow, and verification commands. Its `@` imports preload `docs/GOAL.md` and the spec/ADR indexes into context at every session start, so Claude begins each session already knowing the goal and what knowledge exists without re-reading the repo.
- `docs/GOAL.md` states the goal Claude Code iterates toward for your app, service, or utility: the problem, target state, success criteria, and an ordered milestone backlog.
- `docs/specs/` holds the behavior and contracts Claude should preserve.
- `docs/adr/` holds architecture decisions Claude should follow.
- `docs/okf-map.yml` maps source files to the specs and ADRs that govern them.
- `.claude/hooks/` adds guardrails that catch code changes without matching docs updates.
- `scripts/okf` gives you local checks for stale specs, draft specs, and ADR suggestions.

After installation, the normal loop is simple:

1. You ask Claude Code to change the repo.
2. Claude reads the relevant specs and ADRs before editing.
3. If code changes, Claude updates the matching docs or adds a dated `docs/log.md` note explaining why no spec or ADR changed.
4. The helper checks catch stale mappings, generate draft specs for poorly documented areas, and suggest ADRs only for standing decisions.
5. When you ask Claude Code to continue without naming a task, it takes the first unchecked milestone in `docs/GOAL.md`, verifies it, checks it off, logs the progress, and moves to the next milestone until the backlog is done or a decision only you can make comes up. Before declaring the goal met, it runs an acceptance pass — exercising the deliverable like a first-time user, from a clean checkout through the README quickstart and realistic (including wrong) inputs — because tests prove the contract and that pass proves the experience. If a session gets cut off mid-milestone, the next session treats uncommitted changes as in-flight work and reconciles them against the backlog and the latest `docs/log.md` entry instead of starting over.
6. Standing guardrails hold across every session: a milestone is done only when its verification passes, failing tests can't be deleted or weakened to force a green run, secrets stay out of tracked files, decision-shaped changes (dependencies, persistence, auth, APIs, deployment) are recorded as proposed ADRs for your review, and destructive or outward-facing actions wait for your explicit go-ahead.

One limit to know up front: the guardrails in step 6 are instructions to Claude Code, not mechanical enforcement. The only hard gates the kit installs are the docs-sync hooks and a permissions rule that denies Claude Code reading local `.env` files (so secrets on disk stay out of conversation context). The test, wider security, and destructive-action rules live in the installed `CLAUDE.md` and rely on Claude Code following them. If you need guaranteed gates — tests must pass before merge, secrets can never land in a commit — add them to your repo's own CI and branch protection on top of this kit.

Use this when you want Claude Code to keep implementation, specs, and architecture decisions in sync across a new or existing repo, and to iterate toward a goal you defined once instead of re-explaining it every session. You own the goal; Claude Code makes and records the decisions that reach it, inside those guardrails.

This source repo also includes its own `docs/` knowledge bundle with specs and ADRs that govern the kit itself.

## Table of contents

- [What this kit does](#what-this-kit-does)
- [Fast verification](#fast-verification)
- [Install files and destinations](#install-files-and-destinations)
- [How to use this kit](#how-to-use-this-kit)
  - [Automated setup](#automated-setup)
  - [Manual new repo](#manual-new-repo)
  - [Manual existing repo](#manual-existing-repo)
  - [Daily use after installation](#daily-use-after-installation)
  - [Upgrading an installed repo](#upgrading-an-installed-repo)
  - [Using a second agent for repo chores (optional)](#using-a-second-agent-for-repo-chores-optional)
- [Commit vs ignore](#commit-vs-ignore)
- [How the hooks behave](#how-the-hooks-behave)
- [OKF helper commands](#okf-helper-commands)
- [Verifying an installed target repo](#verifying-an-installed-target-repo)
- [Tracking dogfood repos](#tracking-dogfood-repos)
- [Validating this kit](#validating-this-kit)
- [References](#references)
- [Repository settings](#repository-settings)
- [Project Status](#project-status)

## Fast verification

Before publishing or installing from this source repo, run:

```bash
make test
```

That validates script syntax, optional ShellCheck linting, `settings.json`, stale-reference and local-path scans, local Markdown links, source-kit behavior, new-repo installation, existing-repo installation, installer idempotency, hook behavior, and the `scripts/okf` helper.

## Install files and destinations

| File in this folder     | Destination in the repo             | Purpose                                                        |
|-------------------------|-------------------------------------|----------------------------------------------------------------|
| `templates/CLAUDE.md`   | `CLAUDE.md` (repo root)             | Master objective template, grounding rules, workflow. Loaded every session. |
| `templates/GOAL.md`     | `docs/GOAL.md`                      | Goal template: repo kind, problem, target state, success criteria, milestone backlog. |
| `templates/skills/okf-*/SKILL.md` | `.claude/skills/okf-*/SKILL.md` | Workflow skills loading on demand: goal interview, acceptance pass, ADR review, kit upgrade. `CLAUDE.md` keeps binding one-liners that stand alone if a skill doesn't load. |
| `settings.json`         | `.claude/settings.json`             | Registers both hooks and denies reading local `.env` files.    |
| `scripts/check-docs-sync.sh`    | `.claude/hooks/check-docs-sync.sh`  | Stop hook. Blocks missing docs updates and stale mapped docs. |
| `scripts/check-okf-version.sh`  | `.claude/hooks/check-okf-version.sh`| SessionStart hook. Reports OKF spec version drift so Claude migrates `/docs` formatting. |
| `scripts/okf`                   | `scripts/okf`                       | Repo-local OKF helper command: `check-stale`, `draft`, `adr-suggest`, `new-adr`, `new-spec`, and `pending`. |
| `okf-map.yml`           | `docs/okf-map.yml`                  | Starter map from source globs to governing specs and ADRs.     |

`Makefile` validates this source kit. You do not need to copy it into target repos.

`docs/` documents this source kit. Target repos get their own `docs/` bundle during installation.

Root `CLAUDE.md` is filled in for maintaining this source repo. Target repos receive `templates/CLAUDE.md` as their `CLAUDE.md`.

Source-only automation scripts:

- `scripts/install-kit`
- `scripts/create-new-repo`
- `scripts/update-existing-repo`
- `scripts/verify-install`
- `scripts/check-placeholders`

These scripts install or check the kit in target repos. They do not need to be copied into target repos.

The kit's release version lives in the source-only `VERSION` file at the repo root. Installers stamp it into the target's `docs/index.md` as `kit_version`, which is what lets an installed repo notice at session start that the kit has moved on (see [Upgrading an installed repo](#upgrading-an-installed-repo)).

The kit's website is also source-only: its static source lives in `site/` on `main` and is published to [GitHub Pages](https://lilabrooks.github.io/claude-okf-repo-kit/) by `.github/workflows/pages.yml` (ADR 0009). Installers never copy it into target repos.

## How to use this kit

Use this repo as a source kit. The easiest path is to run one installer script from this repo and point it at the repo you want to set up.

Choose the setup path that matches your target repo:

| Target repo state | Recommended path |
|-------------------|------------------|
| New or empty repo | Run `scripts/create-new-repo`. |
| Existing repo with files already in it | Run `scripts/update-existing-repo`. |
| Existing repo where you want to review every file operation yourself | Follow the manual existing-repo steps. |

In this kit repo, installable files sit at the root for easy review. In the target repo, the installer puts them at the destinations in the table above.

### Automated setup

For most repos, use the safe wrapper. It detects whether the target is new/empty or existing, then delegates to the right installer:

```bash
git clone https://github.com/lilabrooks/claude-okf-repo-kit.git
cd claude-okf-repo-kit
KIT="$(pwd)"
TARGET=/path/to/target-repo
bash "$KIT/scripts/install-kit" "$TARGET"
```

If you prefer explicit commands, use the matching installer yourself.

For a new empty repo:

```bash
bash "$KIT/scripts/create-new-repo" "$TARGET"
```

The new-repo script creates the target directory if needed. The target must be empty except for an optional `.git/` directory.

For an existing repo:

```bash
bash "$KIT/scripts/update-existing-repo" "$TARGET"
```

The existing-repo script avoids destructive overwrites:

- backs up replaced files under `.okf-kit-backups/<timestamp>/`
- merges `.claude/settings.json` hooks and permission rules instead of replacing existing settings
- appends required `.gitignore` entries instead of replacing `.gitignore`
- leaves existing Markdown files untouched and writes same-folder numbered candidates such as `CLAUDE.2.md`
- leaves an existing `docs/okf-map.yml` untouched and writes a same-folder numbered candidate such as `docs/okf-map.2.yml`
- skips the numbered candidate when the existing file already matches the kit content, so repeated updates stay clean
- refreshes its own stale candidates in place when the kit has moved on — proven by a digest manifest under `.okf-kit-backups/`, backed up first — so candidates don't pile up across releases; a candidate you edited is never touched and a new number is used instead
- prints a clear summary of created, updated, skipped, backed-up, and review-needed files

After installation, run the safe checks from this kit repo:

```bash
bash "$KIT/scripts/verify-install" "$TARGET"
bash "$KIT/scripts/check-placeholders" "$TARGET"
```

`verify-install` checks the installed files, settings, shell syntax, required ignores, and helper commands. `check-placeholders` is expected to report items until `CLAUDE.md`, `docs/GOAL.md`, and `docs/okf-map.yml` are filled in for the target repo. The map is the one file that need not be filled on day one: in a new repo there is nothing to map until modules and specs exist, and Claude Code adds mappings during iteration as source areas gain their governing docs — so its placeholder warning is a standing reminder, not an installation failure.

Then fill in the target repo's files. The recommended path is to open the repo in Claude Code: the installed `CLAUDE.md` makes it run a short goal interview — what you're building and for whom, the concrete done state, the mechanical verification, non-goals, which stack choices are fixed versus left to proposed ADRs, and the first shippable slice — and it drafts `docs/GOAL.md` and `CLAUDE.md` from your answers for your confirmation. Editing `docs/GOAL.md`, `CLAUDE.md`, and `docs/okf-map.yml` by hand works the same way. Either way, rerun the checks and commit once the output is clean.

The bootstrap instructions inside `CLAUDE.md` are still useful. They are the fallback for Claude Code when a repo was opened before the installer scripts were run. The scripts are the preferred setup path for people or automation because they validate files and protect existing repos.

### Manual new repo

1. Create or open the repo you want Claude Code to work in.
2. Set these paths in your terminal:

```bash
KIT="$(pwd)"
TARGET=/path/to/target-repo
```

3. Create the target folders:

```bash
mkdir -p "$TARGET/.claude/hooks" "$TARGET/scripts" "$TARGET/docs/specs/_drafts" "$TARGET/docs/adr"
```

4. Copy the kit files into place:

```bash
cp "$KIT/templates/CLAUDE.md" "$TARGET/CLAUDE.md"
cp "$KIT/settings.json" "$TARGET/.claude/settings.json"
cp "$KIT/scripts/check-docs-sync.sh" "$TARGET/.claude/hooks/check-docs-sync.sh"
cp "$KIT/scripts/check-okf-version.sh" "$TARGET/.claude/hooks/check-okf-version.sh"
cp "$KIT/scripts/okf" "$TARGET/scripts/okf"
cp "$KIT/okf-map.yml" "$TARGET/docs/okf-map.yml"
cp "$KIT/templates/GOAL.md" "$TARGET/docs/GOAL.md"
for skill in okf-goal-interview okf-acceptance-pass okf-adr-review okf-kit-upgrade; do
  mkdir -p "$TARGET/.claude/skills/$skill"
  cp "$KIT/templates/skills/$skill/SKILL.md" "$TARGET/.claude/skills/$skill/SKILL.md"
done
```

5. Add the starter docs files:

```bash
cat > "$TARGET/docs/index.md" <<EOF
---
okf_version: "0.1"
kit_version: "$(head -n 1 "$KIT/VERSION")"
---

# Knowledge bundle

- [Goal](GOAL.md)
- [Specs](specs/index.md)
- [ADRs](adr/index.md)
- [Log](log.md)
- [Source map](okf-map.yml)
EOF

cat > "$TARGET/docs/log.md" <<'EOF'
# Log
EOF

cat > "$TARGET/docs/specs/index.md" <<'EOF'
# Specs
EOF

cat > "$TARGET/docs/adr/index.md" <<'EOF'
# ADRs
EOF
```

6. Edit `docs/GOAL.md` in the target repo. Fill every bracket: repo kind (app, service, or utility), problem, target state, success criteria, and an ordered milestone list Claude Code can work through. Update the timestamp and delete the template comment.
7. Edit `CLAUDE.md` in the target repo. Fill every bracket: current state, target state, constraints, done criteria, and the real test/lint/build commands. Update the timestamp and delete the template comment.
8. Edit `docs/okf-map.yml`. Replace the commented placeholder with real repo-relative paths. In a brand-new repo, skip this for now: Claude Code adds mappings during iteration as modules gain specs.
9. Add these lines to the target repo's `.gitignore` (`!.env.example` keeps the sample env file trackable):

```gitignore
.claude/settings.local.json
CLAUDE.local.md
.okf-kit-backups/
.DS_Store
.env
.env.*
!.env.example
```

10. Verify the target repo install:

```bash
bash "$KIT/scripts/verify-install" "$TARGET"
bash "$KIT/scripts/check-placeholders" "$TARGET"
```

The placeholder check should pass only after `CLAUDE.md`, `docs/GOAL.md`, and `docs/okf-map.yml` are filled in with real target-repo details.

11. Commit the kit files with your repo.
12. Open the target repo in Claude Code and give it a task, or just ask it to continue toward the goal. Claude Code will read `CLAUDE.md` at session start and take the first unchecked milestone from `docs/GOAL.md`.

### Manual existing repo

The update script is the safer path for existing repos because it backs up replaced kit-managed scripts, appends `.gitignore`, merges settings, and writes numbered candidates for same-name Markdown/map files. Use the manual path only when you want to review every file operation yourself.

1. Check what already exists:

```bash
TARGET=/path/to/target-repo
KIT="$(pwd)"
ls "$TARGET/CLAUDE.md" "$TARGET/.claude/settings.json" "$TARGET/docs" 2>/dev/null
```

2. Install or merge `CLAUDE.md`:

```bash
if [ ! -f "$TARGET/CLAUDE.md" ]; then
  cp "$KIT/templates/CLAUDE.md" "$TARGET/CLAUDE.md"
fi
```

If the repo already has `CLAUDE.md`, merge this kit's sections into it by hand instead of replacing the file. Keep existing project-specific instructions.

3. Install or merge `.claude/settings.json`:

```bash
mkdir -p "$TARGET/.claude"
if [ ! -f "$TARGET/.claude/settings.json" ]; then
  cp "$KIT/settings.json" "$TARGET/.claude/settings.json"
fi
```

If the repo already has `.claude/settings.json`, merge the `hooks` and `permissions` blocks from this kit's `settings.json`. Preserve any existing hooks and permission rules.

4. Copy the hook scripts and helper command. Back up any existing files first:

```bash
mkdir -p "$TARGET/.claude/hooks" "$TARGET/scripts" "$TARGET/docs/specs/_drafts" "$TARGET/docs/adr"

[ -f "$TARGET/.claude/hooks/check-docs-sync.sh" ] && cp "$TARGET/.claude/hooks/check-docs-sync.sh" "$TARGET/.claude/hooks/check-docs-sync.sh.bak"
[ -f "$TARGET/.claude/hooks/check-okf-version.sh" ] && cp "$TARGET/.claude/hooks/check-okf-version.sh" "$TARGET/.claude/hooks/check-okf-version.sh.bak"
[ -f "$TARGET/scripts/okf" ] && cp "$TARGET/scripts/okf" "$TARGET/scripts/okf.bak"

cp "$KIT/scripts/check-docs-sync.sh" "$TARGET/.claude/hooks/check-docs-sync.sh"
cp "$KIT/scripts/check-okf-version.sh" "$TARGET/.claude/hooks/check-okf-version.sh"
cp "$KIT/scripts/okf" "$TARGET/scripts/okf"
for skill in okf-goal-interview okf-acceptance-pass okf-adr-review okf-kit-upgrade; do
  mkdir -p "$TARGET/.claude/skills/$skill"
  cp "$KIT/templates/skills/$skill/SKILL.md" "$TARGET/.claude/skills/$skill/SKILL.md"
done
```

5. If the repo does not already have `docs/index.md`, `docs/log.md`, `docs/specs/index.md`, or `docs/adr/index.md`, create them using the starter files from the new-repo steps.
6. Copy `okf-map.yml` to `docs/okf-map.yml` only if that file does not already exist. If it does exist, add any new mappings by hand.
7. Copy `templates/GOAL.md` to `docs/GOAL.md` only if that file does not already exist, then fill in the repo kind, problem, target state, success criteria, and milestones:

```bash
if [ ! -f "$TARGET/docs/GOAL.md" ]; then
  cp "$KIT/templates/GOAL.md" "$TARGET/docs/GOAL.md"
fi
```

8. Fill in `docs/okf-map.yml` gradually. Start with the modules Claude touches most often.
9. Append required local-file ignores without replacing `.gitignore`:

```bash
touch "$TARGET/.gitignore"
for entry in '.claude/settings.local.json' 'CLAUDE.local.md' '.okf-kit-backups/' '.DS_Store' '.env' '.env.*' '!.env.example'; do
  grep -qxF "$entry" "$TARGET/.gitignore" || printf '%s\n' "$entry" >> "$TARGET/.gitignore"
done
```
10. Run the checks from this kit repo:

```bash
bash "$KIT/scripts/verify-install" "$TARGET"
bash "$KIT/scripts/check-placeholders" "$TARGET"
```

11. Fill any remaining brackets in `CLAUDE.md` and `docs/GOAL.md`, update `docs/okf-map.yml`, rerun the checks, then commit the installed files once the output is clean.

The target repo should end up with this structure:

```
docs/
├── index.md        # bundle root, declares okf_version
├── GOAL.md         # goal, success criteria, milestone backlog
├── log.md          # dated changelog, newest first
├── okf-map.yml     # source-to-knowledge map
├── specs/
│   ├── index.md
│   └── _drafts/
└── adr/
    └── index.md
```

### Daily use after installation

1. Open the target repo in Claude Code. If `docs/GOAL.md` or `CLAUDE.md` still has template brackets, Claude Code starts with the goal interview and fills them with you before any milestone work.
2. To iterate toward the goal without writing a task, just ask Claude Code to continue. It reads `docs/GOAL.md`, takes the first unchecked milestone, verifies it against the milestone's stated check, checks it off, logs the progress in `docs/log.md`, and keeps going milestone by milestone until the backlog is done, a decision reserved for you comes up, or you stop it. Decision-shaped changes land as `status: proposed` ADRs in `docs/adr/` for your review — list them any time with `bash scripts/okf pending`, then accept one by flipping its status to `accepted` (or just tell Claude Code to; the decision is yours, the edit can be Claude's), ask for changes, or reject it and have the work reverted per the ADR's rollback trigger. When every milestone is checked and the success criteria pass, it runs an acceptance pass — exercising the deliverable like a first-time user, from a clean checkout through the README quickstart and realistic (including wrong) inputs — then reports the goal met, lists any ADRs still awaiting your review, and proposes candidate next milestones — drawn from `docs/log.md` known items, ADR revisit triggers, acceptance-pass findings, standard repo hygiene the repo still lacks (license, CI running the verification commands and the stale-map check, dependency updates, badges), and extensions that fit the stated non-goals, with anything needing a non-goal revision flagged separately — and adds nothing to `docs/GOAL.md` until you choose.
3. For a specific change, ask the usual way, but point at the relevant spec or ADR when you know it:

```text
Review /docs/specs/[module].md and implement [change] in [module path].
```

4. Let Claude Code update code and docs together. If code changes without a `/docs` update, the Stop hook blocks the turn and tells Claude to fix the missing knowledge update.
5. When a mapped source area changes, `bash scripts/okf check-stale` makes sure the mapped spec or ADR changed too. A dated `docs/log.md` entry is enough when no spec or ADR edit is warranted.
6. For a new or poorly documented module, run:

```bash
bash scripts/okf draft path/to/module
```

Review the generated file under `docs/specs/_drafts/`, rewrite it, then move it into `docs/specs/` when it is ready.

7. For dependency, persistence, API, auth, deployment, worker, cache, queue, or ownership-boundary changes, run:

```bash
bash scripts/okf adr-suggest
```

Create an ADR only when the suggestion points to a real standing decision, and scaffold it with `bash scripts/okf new-adr <slug> "Title"` — that numbers the file, sets `status: proposed`, lays out the required sections, and adds the index entry.
8. Commit code, specs, ADRs, and `docs/log.md` together.

### Upgrading an installed repo

Installed repos are snapshots of the kit at install time. The installers stamp the kit release into the target's `docs/index.md` as `kit_version`, and the SessionStart hook compares that stamp against this repo's published `VERSION` file — when they differ, Claude Code gets a session-start note and will tell you the kit has moved on.

To upgrade, pull the latest kit and re-run the safe updater:

```bash
cd claude-okf-repo-kit
git pull
bash scripts/update-existing-repo /path/to/target-repo
```

The updater never overwrites your work. Kit-managed files (`scripts/okf`, the two hooks, and the four `okf-*` skills) are refreshed in place — after a backup under `.okf-kit-backups/<timestamp>/` — only when a digest manifest proves the current content is the kit's own unedited output; a script you edited is left exactly as you had it, with the new kit version written beside it as a numbered candidate (such as `check-docs-sync.2.sh`) under "Needs review". Changed templates get same-folder numbered candidates (such as `CLAUDE.2.md`) the same way. Across repeated upgrades it refreshes its own untouched candidates in place instead of stacking `CLAUDE.3.md`, `CLAUDE.4.md`, and so on — only candidates you edited keep their content and get a new number beside them. Review the candidates, merge what you want, and delete the rest. The manifest lives in the git-ignored `.okf-kit-backups/`, so it never leaves your working copy; repos installed or updated before the manifest existed take the safe path (preserve plus candidate) once, then opt in. Repos installed before the version stamp existed stay silent about drift until one updater run (or a hand-added `kit_version` in `docs/index.md`) opts them in — `verify-install` warns when the stamp is missing.

### Using a second agent for repo chores (optional)

The kit is built for Claude Code, and the goal loop — the interview, milestones, proposed ADRs, and guardrails — stays with it. Optionally, you can point a second agent (Codex CLI, for example) at the same installed repo for commodity chores: a license, CI, dependency-update automation, badges, repository metadata. Both dogfood repos used exactly this split, and the docs discipline held — chore commits still landed their `docs/log.md` entries and ADRs.

If you do this:

- Commit the second agent's config (`AGENTS.md`, `.codex/`, or the equivalent). The shipped hooks already treat those paths as agent config rather than implementation code, so their presence won't re-trigger the docs-sync block every turn.
- The `@` imports in `CLAUDE.md` and the env-file read denial in `.claude/settings.json` are Claude Code mechanisms. A ported playbook (such as `AGENTS.md`) needs explicit "read these files at session start" instructions instead of imports, and should state honestly that the second agent has no mechanical `.env` protection — for it, the secrets guardrail is policy prose.
- If you want the docs-sync gate enforced in the second agent's sessions too, mirror the two hook scripts into its config (the shipped scripts resolve their root via `CLAUDE_PROJECT_DIR`, then `CODEX_PROJECT_DIR`, then the current directory, so unmodified copies work) and keep the mirrors byte-identical to the `.claude/hooks/` originals.
- After a kit upgrade, re-sync any mirrors by hand: the updater manages only the `.claude/hooks/` copies and doesn't know about other agents' directories.

## Commit vs ignore

In an installed target repo, commit these files:

- `CLAUDE.md`
- `.claude/settings.json`
- `.claude/hooks/`
- `.claude/skills/`
- `scripts/okf`
- all of `docs/`

The installer appends these target-repo ignore entries:

- `.claude/settings.local.json`
- `CLAUDE.local.md`
- `.okf-kit-backups/`
- `.DS_Store`
- `.env`
- `.env.*`
- `!.env.example`

Claude local files are personal per-machine files. Backup folders are generated by the safe update script. `.DS_Store` files are macOS Finder artifacts and harmless to ignore everywhere. Env files hold secrets and stay out of version control, while `!.env.example` keeps a committed sample env file trackable so required variables stay documented with placeholder values.

This source kit repo additionally ignores logs, Python bytecode/cache files, and `.obsidian/`.

## How the hooks behave

**Docs sync (every turn).** When Claude tries to finish a turn after changing code without touching `/docs`, the hook blocks the stop and Claude keeps working: it updates the governing spec or ADR, or records in `/docs/log.md` why no update was needed. If the same stop cycle already blocked once (`stop_hook_active` in the hook payload), the hook warns on stderr and lets the turn end instead of blocking again, so a session that cannot write to `docs/` — a read-only sandbox, for example — never loops. Agent configuration (`.claude/`, `CLAUDE.md`, and a second agent's `.codex/` or `AGENTS.md` if present) doesn't count as implementation code; the file exclusions are exact-name matches, so lookalikes such as `LICENSE-MIT` still count as code.

**Stale map check (every turn, when configured).** If `scripts/okf` and `docs/okf-map.yml` exist, the same Stop hook also runs `bash scripts/okf check-stale`. This catches the subtler case where some doc changed, but the mapped spec or ADR for the touched source area did not.

**OKF version (session start).** The hook fetches the spec version from the official OKF repo (silent when offline) and compares it to `okf_version` in `docs/index.md`. When drift is detected, it adds context for Claude Code. The policy in `CLAUDE.md` tells Claude how to handle minor and major OKF version changes.

**Kit version (session start).** The same hook compares the `kit_version` stamped in `docs/index.md` against this repo's published `VERSION` file. On drift, Claude Code is told to recommend the safe updater (see [Upgrading an installed repo](#upgrading-an-installed-repo)); it never updates anything itself. Repos without the stamp get no note.

**ADR review inbox (session start).** The same hook counts ADRs under `docs/adr/` still marked `status: proposed` — skipping installer-written numbered candidates, exactly like `bash scripts/okf pending` — and injects the count as session-start context. Proposed decisions stay visible every session instead of only in the goal-met report, so they don't linger unreviewed. This check is local and works offline.

**Env-file read denial (every tool call).** The installed `.claude/settings.json` also carries `permissions.deny` rules (`Read(./.env)`, `Read(./**/.env)`) so Claude Code cannot read local env files into conversation context. `.env.example` is deliberately not denied — deny rules can't be negated, and the committed sample file must stay readable. Extend the deny list in your own settings for other secret paths.

The hooks and the env-file read denial are the kit's only mechanical enforcement. Every other guardrail — tests passing, wider security rules, owner-gated destructive actions — is instruction-level in the installed `CLAUDE.md`. Repos that need hard gates add them in their own CI and branch protection.

## OKF helper commands

`okf` is a local Bash helper included with this kit. It is not an official OKF CLI, not a globally installed command, and not a prompt. In this repo it lives at `scripts/okf`; after installation in another repo, run it with `bash scripts/okf ...`.

Run these from the repo root:

```bash
bash scripts/okf check-stale
bash scripts/okf draft path/to/module
bash scripts/okf adr-suggest
bash scripts/okf new-adr <slug> "Title"
bash scripts/okf new-spec <slug> "Title"
bash scripts/okf pending
```

`check-stale` compares changed source files against `docs/okf-map.yml`. It also prints a non-blocking note listing changed files that match no mapping, so new source areas get mapped as they gain governing docs.

`draft` writes fact-based markdown drafts to `docs/specs/_drafts/`. It is aimed at existing codebases with undocumented modules — greenfield repos usually write specs as modules land. Review and rewrite before promoting a draft into `docs/specs/`.

`adr-suggest` prints ADR candidates only for decision-shaped changes: dependencies, persistence, cache/queue/worker behavior, auth/security/privacy, public API contracts, deployment, or ownership boundaries.

`new-adr` scaffolds the next-numbered ADR with `status: proposed` frontmatter, the required sections (context, decision, alternatives, consequences, rollback trigger), and an index entry. `new-spec` does the same for a spec skeleton. Both refuse to overwrite existing files and leave bracketed placeholders to fill.

`pending` lists ADRs still `status: proposed` — the owner's review inbox — and flags any ADR missing a status field, which would otherwise be invisible to that review.

## Verifying an installed target repo

From this kit repo, run:

```bash
KIT="$(pwd)"
TARGET=/path/to/target-repo
bash "$KIT/scripts/verify-install" "$TARGET"
bash "$KIT/scripts/check-placeholders" "$TARGET"
```

`check-placeholders` exits nonzero while target-specific template fields remain. Treat that as a checklist, not as an installer failure.

You can also run the underlying target-repo checks manually:

```bash
cd "$TARGET"
python3 -m json.tool .claude/settings.json >/dev/null
bash -n scripts/okf
bash -n .claude/hooks/check-docs-sync.sh
bash -n .claude/hooks/check-okf-version.sh
bash scripts/okf check-stale
bash scripts/okf adr-suggest
git status --short --ignored
```

Expected results:

- JSON and shell syntax checks print no errors.
- `check-stale` either says mappings are current or names the mapped spec/ADR to update.
- `adr-suggest` either says no ADR-shaped changes were detected or prints conservative ADR candidates.
- `git status --ignored` shows `.claude/settings.local.json`, `CLAUDE.local.md`, `.okf-kit-backups/`, and `.env` as ignored if they exist; a committed `.env.example` stays tracked.
- `verify-install` requires the settings to carry the env-file read deny rules, and warns (without failing) when `docs/index.md` lacks the `kit_version` stamp used for upgrade drift reporting.

To manually test the Stop hook, edit a mapped source file and try to finish a Claude Code turn without touching `/docs`. Claude should be blocked and told to update the mapped spec/ADR or add a dated `docs/log.md` rationale. Then touch an unrelated doc: Claude should still be blocked by `check-stale`.

## Tracking dogfood repos

For kit maintainers who dogfood the kit in their own repos, the source-only `scripts/harvest-dogfood` reports what changed in each registered repo since the last review — no codebase exploration needed, because the installed docs-sync hook guarantees every target change leaves a `docs/log.md` trace:

```bash
bash scripts/harvest-dogfood add /path/to/installed-repo   # register at current HEAD
bash scripts/harvest-dogfood                               # delta report for all repos
bash scripts/harvest-dogfood mark                          # record the reviewed point
bash scripts/harvest-dogfood list                          # show the registry
bash scripts/harvest-dogfood query <pattern>               # search all repos' knowledge
```

Per repo, the report shows commits and new `docs/log.md` entries since the last mark (lines mentioning the kit or upstreaming are flagged), kit-managed file drift with manifest provenance (matches the kit, unedited older kit output, or owner-edited), the proposed-ADR review inbox, the `kit_version` stamp vs this kit's `VERSION`, uncommitted-change and second-agent-config notes. The helper never modifies a registered repo. Its registry holds absolute local paths, so it is machine-local and git-ignored under `.okf-kit-backups/` — a fresh kit clone starts with an empty registry and repos are re-added with one command each (ADR 0014).

`query` answers cross-repo questions in one command instead of an exploration: it rebuilds a derived knowledge index from every registered repo — goal lines, milestones, spec and ADR index entries with statuses, log bullets, each tagged with its repo and source path — then greps it case-insensitively. Because the index is rebuilt on every query, it can never go stale; like the registry, it stays machine-local and git-ignored.

## Validating this kit

From this source-kit repo, run:

```bash
make test
```

That runs shell syntax checks, optional ShellCheck linting, JSON validation, stale-reference and local-path scans, Markdown link checks, new-repo install simulation, existing-repo install simulation, installer idempotency checks, candidate and script-provenance refresh simulations, install/verify/placeholder helper checks, hook behavior checks, `okf` helper smoke tests, and the dogfood harvest smoke check.

You can also run narrower targets:

```bash
make syntax
make json
make scan
make links
make smoke
make shellcheck
```

For a change that only touches documentation — accepting an already-implemented ADR (a `status:` flip plus a log entry), or a log-only edit — `make check-docs` is a fast gate that runs just the checks covering `docs/` prose (the local-path scan and Markdown links) plus the OKF helper sanity checks, skipping the installer and hook smoke simulations a doc edit cannot affect. Anything touching scripts, templates, `settings.json`, or `VERSION` still needs the full `make test`.

## References

- OKF spec: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
- Claude Code hooks: https://code.claude.com/docs/en/hooks
- Claude Code settings: https://code.claude.com/docs/en/settings

## Repository settings

Some of this repo's hygiene lives in GitHub settings rather than in tracked files, so it is not reproducible from a clone. `.github/dependabot.yml` (Dependabot version updates) is committed, but these are server-side toggles enabled on the GitHub repository:

| Setting | State | Restore command |
|---------|-------|-----------------|
| Dependabot version updates | On (via `.github/dependabot.yml`) | committed to the repo |
| Dependabot alerts | On | `gh api -X PUT repos/OWNER/REPO/vulnerability-alerts` |
| Dependabot security updates | On | `gh api -X PUT repos/OWNER/REPO/automated-security-fixes` |
| Secret scanning + push protection | On | GitHub Settings → Code security |
| GitHub Pages source | GitHub Actions | GitHub Settings → Pages → Source: GitHub Actions, or `gh api -X POST repos/OWNER/REPO/pages -f build_type=workflow` |

These apply to this source repo only; the installers do not add Dependabot or GitHub settings to target repos.

## Project Status

This is a personal side project, maintained on a best-effort basis rather than a supported product. Tests, linting, and type-checking run on every change, but there's no SLA on response time — issues and pull requests are welcome, and may take a while to get to.
