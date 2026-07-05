# Claude OKF repo kit

![Status](https://img.shields.io/badge/status-alpha-orange)
![Tests](https://github.com/lilabrooks/claude-okf-repo-kit/actions/workflows/test.yml/badge.svg)
![Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-5D3FD3)
![OKF](https://img.shields.io/badge/docs-OKF%200.1-blue)
![Bash](https://img.shields.io/badge/scripts-Bash-4EAA25?logo=gnubash&logoColor=white)
![Specs + ADRs](https://img.shields.io/badge/specs%20%2B%20ADRs-included-0A7)
![License](https://img.shields.io/github/license/lilabrooks/claude-okf-repo-kit)

## What this kit does

This kit sets up a repo so Claude Code works from project knowledge instead of only reading code and guessing intent.

It gives your repo a small, repeatable structure:

- `CLAUDE.md` tells Claude Code the project goal, rules, workflow, and verification commands.
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

Use this when you want Claude Code to keep implementation, specs, and architecture decisions in sync across a new or existing repo.

This source repo also includes its own `docs/` knowledge bundle with specs and ADRs that govern the kit itself.

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
| `settings.json`         | `.claude/settings.json`             | Registers both hooks.                                          |
| `scripts/check-docs-sync.sh`    | `.claude/hooks/check-docs-sync.sh`  | Stop hook. Blocks missing docs updates and stale mapped docs. |
| `scripts/check-okf-version.sh`  | `.claude/hooks/check-okf-version.sh`| SessionStart hook. Reports OKF spec version drift so Claude migrates `/docs` formatting. |
| `scripts/okf`                   | `scripts/okf`                       | Repo-local OKF helper command: `check-stale`, `draft`, and `adr-suggest`. |
| `okf-map.yml`           | `docs/okf-map.yml`                  | Starter map from source globs to governing specs and ADRs.     |

`Makefile` validates this source kit. You do not need to copy it into target repos.

`docs/` documents this source kit. Target repos get their own `docs/` bundle during installation.

Root `CLAUDE.md` is filled in for maintaining this source repo. Target repos receive `templates/CLAUDE.md` as their `CLAUDE.md`.

Source-only automation scripts:

- `scripts/create-new-repo`
- `scripts/update-existing-repo`

These scripts install the kit into target repos. They do not need to be copied into target repos.

## How to use this kit

Use this repo as a source kit. Copy its files into the repo where you want Claude Code to keep specs, ADRs, and code changes tied together.

In this kit repo, the files sit at the root for easy review. In the target repo, put them at the destinations in the table above.

### Automated setup

For a new empty repo:

```bash
KIT=/path/to/claude-okf-repo-kit
TARGET=/path/to/new-repo
bash "$KIT/scripts/create-new-repo" "$TARGET"
```

The new-repo script creates the target directory if needed. The target must be empty except for an optional `.git/` directory.

For an existing repo:

```bash
KIT=/path/to/claude-okf-repo-kit
TARGET=/path/to/existing-repo
bash "$KIT/scripts/update-existing-repo" "$TARGET"
```

The existing-repo script avoids destructive overwrites:

- backs up replaced files under `.okf-kit-backups/<timestamp>/`
- merges `.claude/settings.json` hooks instead of replacing existing settings
- appends required `.gitignore` entries instead of replacing `.gitignore`
- leaves existing Markdown files untouched and writes same-folder numbered candidates such as `CLAUDE.2.md`
- leaves an existing `docs/okf-map.yml` untouched and writes a same-folder numbered candidate such as `docs/okf-map.2.yml`
- prints a clear summary of created, updated, skipped, backed-up, and review-needed files

After either script runs, edit `CLAUDE.md` and `docs/okf-map.yml`, then run the verification commands below.

The bootstrap instructions inside `CLAUDE.md` are still useful. They are the fallback for Claude Code when a repo was opened before the installer scripts were run. The scripts are the preferred setup path for people or automation because they validate files and protect existing repos.

### Manual new repo

1. Create or open the repo you want Claude Code to work in.
2. Set these paths in your terminal:

```bash
KIT=/path/to/claude-okf-repo-kit
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
```

5. Add the starter docs files:

```bash
cat > "$TARGET/docs/index.md" <<'EOF'
---
okf_version: "0.1"
---

# Knowledge bundle

- [Specs](specs/index.md)
- [ADRs](adr/index.md)
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

6. Edit `CLAUDE.md` in the target repo. Fill every bracket: current state, target state, constraints, done criteria, and the real test/lint/build commands. Update the timestamp and delete the template comment.
7. Edit `docs/okf-map.yml`. Replace the commented placeholder with real repo-relative paths.
8. Add these lines to the target repo's `.gitignore`:

```gitignore
.claude/settings.local.json
CLAUDE.local.md
.okf-kit-backups/
```

9. Verify the target repo install:

```bash
cd "$TARGET"
python3 -m json.tool .claude/settings.json >/dev/null
bash -n scripts/okf
bash -n .claude/hooks/check-docs-sync.sh
bash -n .claude/hooks/check-okf-version.sh
bash scripts/okf check-stale
bash scripts/okf adr-suggest
```

10. Commit the kit files with your repo.
11. Open the target repo in Claude Code and give it a task. Claude Code will read `CLAUDE.md` at session start.

### Manual existing repo

The update script is the safer path for existing repos because it backs up replaced kit-managed scripts, appends `.gitignore`, merges settings, and writes numbered candidates for same-name Markdown/map files. Use the manual path only when you want to review every file operation yourself.

1. Check what already exists:

```bash
TARGET=/path/to/target-repo
KIT=/path/to/claude-okf-repo-kit
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

If the repo already has `.claude/settings.json`, merge the `hooks` block from this kit's `settings.json`. Preserve any existing hooks.

4. Copy the hook scripts and helper command. Back up any existing files first:

```bash
mkdir -p "$TARGET/.claude/hooks" "$TARGET/scripts" "$TARGET/docs/specs/_drafts" "$TARGET/docs/adr"

[ -f "$TARGET/.claude/hooks/check-docs-sync.sh" ] && cp "$TARGET/.claude/hooks/check-docs-sync.sh" "$TARGET/.claude/hooks/check-docs-sync.sh.bak"
[ -f "$TARGET/.claude/hooks/check-okf-version.sh" ] && cp "$TARGET/.claude/hooks/check-okf-version.sh" "$TARGET/.claude/hooks/check-okf-version.sh.bak"
[ -f "$TARGET/scripts/okf" ] && cp "$TARGET/scripts/okf" "$TARGET/scripts/okf.bak"

cp "$KIT/scripts/check-docs-sync.sh" "$TARGET/.claude/hooks/check-docs-sync.sh"
cp "$KIT/scripts/check-okf-version.sh" "$TARGET/.claude/hooks/check-okf-version.sh"
cp "$KIT/scripts/okf" "$TARGET/scripts/okf"
```

5. If the repo does not already have `docs/index.md`, `docs/log.md`, `docs/specs/index.md`, or `docs/adr/index.md`, create them using the starter files from the new-repo steps.
6. Copy `okf-map.yml` to `docs/okf-map.yml` only if that file does not already exist. If it does exist, add any new mappings by hand.
7. Fill in `docs/okf-map.yml` gradually. Start with the modules Claude touches most often.
8. Append required local-file ignores without replacing `.gitignore`:

```bash
touch "$TARGET/.gitignore"
for entry in '.claude/settings.local.json' 'CLAUDE.local.md' '.okf-kit-backups/'; do
  grep -qxF "$entry" "$TARGET/.gitignore" || printf '%s\n' "$entry" >> "$TARGET/.gitignore"
done
```
9. Run the checks from the target repo root:

```bash
cd "$TARGET"
python3 -m json.tool .claude/settings.json >/dev/null
bash -n scripts/okf
bash -n .claude/hooks/check-docs-sync.sh
bash -n .claude/hooks/check-okf-version.sh
bash scripts/okf check-stale
bash scripts/okf adr-suggest
```

10. Fill any remaining brackets in `CLAUDE.md`, then commit the installed files once the checks are clean.

The target repo should end up with this structure:

```
docs/
├── index.md        # bundle root, declares okf_version
├── log.md          # dated changelog, newest first
├── okf-map.yml     # source-to-knowledge map
├── specs/
│   ├── index.md
│   └── _drafts/
└── adr/
    └── index.md
```

### Daily use after installation

1. Open the target repo in Claude Code.
2. Ask for changes the usual way, but point at the relevant spec or ADR when you know it:

```text
Review /docs/specs/[module].md and implement [change] in [module path].
```

3. Let Claude Code update code and docs together. If code changes without a `/docs` update, the Stop hook blocks the turn and tells Claude to fix the missing knowledge update.
4. When a mapped source area changes, `bash scripts/okf check-stale` makes sure the mapped spec or ADR changed too. A dated `docs/log.md` entry is enough when no spec or ADR edit is warranted.
5. For a new or poorly documented module, run:

```bash
bash scripts/okf draft path/to/module
```

Review the generated file under `docs/specs/_drafts/`, rewrite it, then move it into `docs/specs/` when it is ready.

6. For dependency, persistence, API, auth, deployment, worker, cache, queue, or ownership-boundary changes, run:

```bash
bash scripts/okf adr-suggest
```

Create an ADR only when the suggestion points to a real standing decision.
7. Commit code, specs, ADRs, and `docs/log.md` together.

## Commit vs ignore

Committed: `CLAUDE.md`, `.claude/settings.json`, `.claude/hooks/`, `scripts/okf`, and all of `/docs`.

Ignored: `.claude/settings.local.json`, `CLAUDE.local.md`, `.okf-kit-backups/`, local `.env` files, and `*.log`. Claude local files are personal per-machine files. Backup folders are generated by the safe update script. `.env.example` remains trackable for documented sample configuration.

## How the hooks behave

**Docs sync (every turn).** When Claude tries to finish a turn after changing code without touching `/docs`, the hook blocks the stop and Claude keeps working: it updates the governing spec or ADR, or records in `/docs/log.md` why no update was needed.

**Stale map check (every turn, when configured).** If `scripts/okf` and `docs/okf-map.yml` exist, the same Stop hook also runs `bash scripts/okf check-stale`. This catches the subtler case where some doc changed, but the mapped spec or ADR for the touched source area did not.

**OKF version (session start).** The hook fetches the spec version from the official OKF repo (silent when offline) and compares it to `okf_version` in `docs/index.md`. On a minor bump Claude migrates `/docs` formatting automatically before the first task. On a major bump it stops and presents a migration summary for approval.

## OKF helper commands

`okf` is a local Bash helper included with this kit. It is not an official OKF CLI, not a globally installed command, and not a prompt. In this repo it lives at `scripts/okf`; after installation in another repo, run it with `bash scripts/okf ...`.

Run these from the repo root:

```bash
bash scripts/okf check-stale
bash scripts/okf draft path/to/module
bash scripts/okf adr-suggest
```

`check-stale` compares changed source files against `docs/okf-map.yml`.

`draft` writes fact-based markdown drafts to `docs/specs/_drafts/`. Review and rewrite before promoting a draft into `docs/specs/`.

`adr-suggest` prints ADR candidates only for decision-shaped changes: dependencies, persistence, cache/queue/worker behavior, auth/security/privacy, public API contracts, deployment, or ownership boundaries.

## Verifying an installed target repo

Run these from the target repo root after installation:

```bash
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
- `git status --ignored` shows `.claude/settings.local.json`, `CLAUDE.local.md`, and `.okf-kit-backups/` as ignored if they exist.

To manually test the Stop hook, edit a mapped source file and try to finish a Claude Code turn without touching `/docs`. Claude should be blocked and told to update the mapped spec/ADR or add a dated `docs/log.md` rationale. Then touch an unrelated doc: Claude should still be blocked by `check-stale`.

## Validating this kit

From this source-kit repo, run:

```bash
make test
```

That runs shell syntax checks, optional ShellCheck linting, JSON validation, stale-reference and local-path scans, Markdown link checks, new-repo install simulation, existing-repo install simulation, installer idempotency checks, hook behavior checks, and `okf` helper smoke tests.

You can also run narrower targets:

```bash
make syntax
make json
make scan
make links
make smoke
make shellcheck
```

## References

- OKF spec: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
- Claude Code hooks: https://code.claude.com/docs/en/hooks
- Claude Code settings: https://code.claude.com/docs/en/settings
