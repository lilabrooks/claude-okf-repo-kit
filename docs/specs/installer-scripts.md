---
type: Spec
title: Installer scripts
description: Safe automation for creating new repos and updating existing repos with this kit.
tags: [installer, bash, safety]
timestamp: 2026-07-08T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Purpose

The source kit includes installer scripts so users do not have to manually copy every file.

The scripts must preserve the same install contract documented in `README.md`.

The scripts are not a replacement for the `CLAUDE.md` bootstrap instructions. They are the preferred setup path before a Claude Code session starts. The bootstrap instructions remain the in-session fallback when a repo does not yet have the expected docs tree.

Installer completion output must point to the in-session goal interview as the recommended path for filling `CLAUDE.md` and `docs/GOAL.md`, with manual editing as the alternative.

Installers must copy source `templates/CLAUDE.md` to target `CLAUDE.md`. They must not copy source root `CLAUDE.md`, which is project-specific to this kit repo.

Installers must copy source `templates/GOAL.md` to target `docs/GOAL.md` so every installed repo starts with a goal template Claude Code can iterate toward.

# New repo installer

`bash scripts/create-new-repo /path/to/new-repo` creates a new target repo with the kit installed.

The target may be missing or empty. It may contain an existing `.git/` directory.

The script must refuse to run against a non-empty target with files other than `.git/`.

The script must print a clear completion summary that lists created, updated, and skipped files, then names the verification checks it ran.

It must create:

- `.claude/settings.json`
- `.claude/hooks/check-docs-sync.sh`
- `.claude/hooks/check-okf-version.sh`
- `.claude/skills/okf-goal-interview/SKILL.md`
- `.claude/skills/okf-acceptance-pass/SKILL.md`
- `.claude/skills/okf-adr-review/SKILL.md`
- `.claude/skills/okf-kit-upgrade/SKILL.md`
- `.claude/skills/okf-adopt/SKILL.md`
- `scripts/okf`
- `docs/index.md`
- `docs/log.md`
- `docs/specs/index.md`
- `docs/specs/_drafts/`
- `docs/adr/index.md`
- `docs/okf-map.yml`
- `docs/GOAL.md`
- `CLAUDE.md`

It must add these ignores:

- `.claude/settings.local.json`
- `CLAUDE.local.md`
- `.okf-kit-backups/`
- `.DS_Store` (macOS Finder artifacts; harmless elsewhere)
- `.env`
- `.env.*`
- `!.env.example` (keeps the sample env file trackable)

It must seed `.okf-kit-backups/candidate-manifest` with the digests of the kit-managed files it installs (`scripts/okf`, the two hooks, and the five `okf-*` skills — eight entries), so a later updater run can prove they are unedited kit output and refresh them in place (ADRs 0013, 0015). The manifest is git-ignored, per-working-copy provenance — not a tracked artifact.

# Existing repo installer

`bash scripts/update-existing-repo /path/to/existing-repo` updates an existing repo without destructive overwrites.

It must:

- require the target directory to exist
- create `.okf-kit-backups/<timestamp>/`
- refresh a kit-managed file (`scripts/okf`, the two hooks, the five `okf-*` skills) in place — after a backup — only when the manifest proves its current content is the installer's own unedited output; record identical content in the manifest (the opt-in path for pre-manifest installs); leave differing content with no recorded provenance untouched and write the kit version as a same-folder numbered candidate (such as `check-docs-sync.2.sh`) listed under review (ADRs 0013, 0015)
- merge `.claude/settings.json` hooks and `permissions` rules (union by exact rule) while preserving existing settings
- append the required `.gitignore` entries (the same seven the new-repo installer adds) while preserving existing entries
- leave existing Markdown files untouched and write same-folder numbered candidates when names collide
- detect an existing knowledge arrangement — a `layout:` block in the target's `docs/okf-map.yml` first, then filesystem probes over bounded candidate lists for the spec and ADR homes, then the canonical defaults — and scaffold into the detected homes; a non-canonical detection is recorded as a `layout:` block in the installed map (and in the map candidate) so every kit tool follows it (ADR 0018)
- leave an existing `CLAUDE.md` untouched and write a candidate such as `CLAUDE.2.md`; when `AGENTS.md` exists and `CLAUDE.md` is absent or a pure `@`-import shim, stage the kit playbook as an `AGENTS.md` numbered candidate instead — with the preloaded-import lines rewritten to the detected layout — leave the shim untouched, and create a missing `CLAUDE.md` as a four-line import shim pointing at `AGENTS.md`, the goal, and the layout's indexes (ADR 0018)
- leave an existing `docs/okf-map.yml` untouched and write a candidate such as `docs/okf-map.2.yml`
- leave an existing `docs/GOAL.md` untouched and write a candidate such as `docs/GOAL.2.md`, except when the existing goal already carries the kit's structure (`# Goal`, `# Milestones`) with no template brackets — a filled goal gets no template candidate; create `docs/GOAL.md` from `templates/GOAL.md` when it is missing
- skip writing a numbered candidate when the existing file already matches the kit content byte for byte, recording such matches in the manifest so pre-manifest candidates opt in
- record every candidate and kit-managed script it writes in `.okf-kit-backups/candidate-manifest` (`sha256` plus repo-relative path), and on later runs refresh in place — after a backup — a stale candidate whose digest proves it is this script's own unedited output, removing provably-ours duplicates for the same destination; owner-edited or unrecorded candidates are never touched and keep the numbered-path behavior (ADRs 0012, 0013)
- create a missing spec or ADR index seeded with an entry per knowledge file already in its directory (titles from frontmatter or the first heading) — never an empty index beside existing work — and create a missing `docs/log.md`; existing indexes and log files are left untouched with no heading-only numbered candidate, since a heading-only starter carries nothing worth reviewing (ADR 0018)
- print a clear completion summary that lists created, updated, skipped, backed-up, and review-needed files, then names the verification checks it ran

Starter `docs/index.md` content written by either installer must link `GOAL.md`, the spec and ADR indexes at their layout homes (`specs/index.md` and `adr/index.md` in the canonical tree), `log.md`, and `okf-map.yml` — plus `docs/runbooks/` and a root `schemas/` directory when the target has them (ADR 0018) — and must declare `okf_version` plus the installing kit's `kit_version` read from the source `VERSION` file (ADR 0010). When a `docs/index.md` already exists and opens with a frontmatter block declaring `okf_version`, the existing-repo installer stamps `kit_version` into that frontmatter directly — after a backup — inserting the line after `okf_version` when absent, correcting it in place when it differs from the installing kit, and skipping when it already matches; no bundle-root candidate is written (ADR 0019). Otherwise the installer carries the starter content in the numbered candidate it writes beside the existing file.

# Wrapper and verification helpers

`bash scripts/install-kit /path/to/target-repo` must choose the safe setup path:

- missing, empty, or `.git/`-only target -> `scripts/create-new-repo`
- existing target with files -> `scripts/update-existing-repo`

The wrapper must print the selected mode and delegated command before running it.

`bash scripts/verify-install /path/to/target-repo` must check installed files, settings JSON, hook commands, the env-file read deny rules, shell syntax, required `.gitignore` entries (including the env-file set), and basic `scripts/okf` execution, resolving the spec home, ADR home, and stamp file through the target's layout block (ADR 0018). It must warn — not fail — when the stamp file lacks a `kit_version` stamp, when `.env.example` is ignored, or when a knowledge index lists no entries while knowledge files sit beside it, and it must not judge project-specific content.

`bash scripts/check-placeholders /path/to/target-repo` must report remaining template placeholders in `CLAUDE.md` and `docs/GOAL.md`, and missing active mappings in `docs/okf-map.yml`. It must not modify files.

# Validation

Both installers must run syntax checks for installed scripts and JSON validation for settings.

The Makefile smoke tests must exercise both installers and the source-only install, verify, and placeholder helpers.
