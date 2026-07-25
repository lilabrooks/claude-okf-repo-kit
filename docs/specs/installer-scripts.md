---
type: Spec
title: Installer scripts
description: Safe automation for creating new repos and updating existing repos with this kit.
tags: [installer, bash, safety]
generated: { by: claude-code/opus-4.8, at: 2026-07-08T00:00:00Z }
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

The script must print a completion summary whose section labels are a stable output contract (ADR 0023): `Created:`, `Updated:`, and `Skipped:`, followed by `Verification run:`. Every label prints on every run (`none` under an empty section). Downstream stack templates relay and test against these labels; renaming or dropping one is a breaking change requiring a new ADR and a `VERSION` bump, while appending new labels is allowed.

It must create:

- `.claude/settings.json`
- `.claude/hooks/check-docs-sync.sh`
- `.claude/hooks/check-okf-version.sh`
- `.claude/skills/okf-goal-interview/SKILL.md`
- `.claude/skills/okf-acceptance-pass/SKILL.md`
- `.claude/skills/okf-adr-review/SKILL.md`
- `.claude/skills/okf-kit-upgrade/SKILL.md`
- `.claude/skills/okf-adopt/SKILL.md`
- `.claude/skills/okf-second-agent/SKILL.md`
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

It must seed `.okf-kit-backups/candidate-manifest` with the digests of the kit-managed files it installs (`scripts/okf`, the two hooks, and the six `okf-*` skills — nine entries), so a later updater run can prove they are unedited kit output and refresh them in place (ADRs 0013, 0015). The manifest is git-ignored, per-working-copy provenance — not a tracked artifact.

# Existing repo installer

`bash scripts/update-existing-repo /path/to/existing-repo` updates an existing repo without destructive overwrites.

It must:

- require the target directory to exist
- create `.okf-kit-backups/<timestamp>/`
- refresh a kit-managed file (`scripts/okf`, the two hooks, the six `okf-*` skills) in place — after a backup — only when the manifest proves its current content is the installer's own unedited output; record identical content in the manifest (the opt-in path for pre-manifest installs); leave differing content with no recorded provenance untouched and write the kit version as a same-folder numbered candidate (such as `check-docs-sync.2.sh`) listed under review (ADRs 0013, 0015)
- sync declared second-agent hook mirrors (ADR 0021): each repo-relative directory in the target map's top-level `mirrors:` list receives the two kit hooks through the same provenance path as `.claude/hooks/` — created when absent, refreshed in place when provably unedited kit output, preserved with a numbered candidate otherwise. A declared mirror has a second accepted proof of provenance beyond the manifest: content byte-identical to the *pre-refresh* `.claude/hooks/` original is a faithful mirror, not an owner edit, and is refreshed in place. Without it a mirror created or adopted by hand — moving the numbered candidate over the original, which ADR 0021 makes the expected resolution since declared mirrors must equal the `.claude` hook — never enters the manifest and is re-staged as the same no-op candidate on every later upgrade. The second proof applies only when the `.claude` original itself now carries the incoming kit content: when that original was preserved for review, its mirror is preserved with it, since refreshing one side alone would break the byte-identical invariant the declaration exists to keep. Hooks only (mirror skills stay owner-managed), declared never detected for syncing, entries normalized identically to the SessionStart hook and `verify-install` parsers (trailing slashes stripped, so `- .codex/hooks/` declares the same mirror as `- .codex/hooks` for the sync and the undeclared-mirror advisory alike), and absolute or `..`-containing entries (or `.claude/hooks` itself) are ignored with a note in the summary
- surface an undeclared-mirror advisory at upgrade time (ADRs 0021, 0024): a directory outside `.claude/hooks/` holding a byte-identical copy of a kit hook with no covering `mirrors:` entry draws an `Advisories:` line naming the exact declaration to add — detected against the pre-refresh originals, because after the run refreshes `.claude/hooks/` a mirror of the previous release matches nothing on disk and the drift the advisory exists to name would go unreported. Byte-identical matches only, and detection never drives a sync; `verify-install` and the SessionStart hook carry the same warn-only rule for installed repos at rest
- surface a second-agent skill-pairing advisory (ADR 0024): for each known second-agent skill home (`.agents/skills`, `.codex/skills`) that already carries at least one `okf-*` skill, an `Advisories:` line lists the `okf-*` skills present under `.claude/skills/` but missing there — the updater refreshes only `.claude/skills/` and never syncs adapted copies, so a release that adds a skill would otherwise unpair the sets silently — plus a line for `okf-*` skills with no `.claude/skills/` counterpart. Advisory only; adapted skills stay owner-managed per the `okf-second-agent` skill
- merge `.claude/settings.json` hooks and `permissions` rules (union by exact rule) while preserving existing settings
- append the required `.gitignore` entries (the same seven the new-repo installer adds) while preserving existing entries
- leave existing Markdown files untouched and write same-folder numbered candidates when names collide
- detect an existing knowledge arrangement — a `layout:` block in the target's `docs/okf-map.yml` first, then filesystem probes over bounded candidate lists for the spec and ADR homes, then the canonical defaults — and scaffold into the detected homes; a non-canonical detection is recorded as a `layout:` block in the installed map (and in the map candidate) so every kit tool follows it (ADR 0018)
- write a template-delta review aid beside the backups whenever a run that crosses kit versions stages or refreshes a playbook candidate: the prior release is read from the stamp file before restamping, its `templates/CLAUDE.md` is recovered from the kit clone's own git history (the newest commit touching `VERSION` whose content matches the stamped version), and the raw old-to-new template diff is written to `.okf-kit-backups/<timestamp>/CLAUDE.md.template-delta.diff` with an `Advisories:` line pointing at it — so candidate review merges the kit's delta instead of re-deriving it (the `okf-kit-upgrade` skill's manual `git show` technique remains the fallback). Best-effort: no prior stamp, same version, no git history, or a version with no release commit all skip silently
- leave an existing `CLAUDE.md` untouched and write a candidate such as `CLAUDE.2.md`; when `AGENTS.md` exists and `CLAUDE.md` is absent or an `@`-import shim — pure (only `@`-import and blank lines) or commented (an exact `@AGENTS.md` import plus explanatory prose, at most 15 non-blank lines, where a heading disqualifies only if the `@AGENTS.md` import sits under it — a shim may carry the preloaded-context block under a heading after its redirect; ADRs 0022, 0025) — stage the kit playbook as an `AGENTS.md` numbered candidate instead — with the preloaded-import lines rewritten to the detected layout — leave the shim untouched, and create a missing `CLAUDE.md` as a four-line import shim pointing at `AGENTS.md`, the goal, and the layout's indexes (ADR 0018)
- suppress the whole-template playbook candidate when it would review to nothing, writing the kit-only template delta instead (extending ADR 0018's filled-goal reasoning to the playbook). All three conditions must hold: the live playbook is *kit-derived* (it carries at least four of the kit playbook's landmark headings — `Master objective`, `Grounding rules`, `Decision policy`, `Guardrails`, `Workflow for each task`, `Verification commands`, `Kit version policy`, `OKF helper commands` — so a delta describes changes it can absorb; a repo's own playbook with its own structure still gets the whole template), it is *filled* (none of the template's blanks remain — the shared `playbook-placeholders` list, with the template's "delete this comment" reminder deliberately not a disqualifier since a playbook can be finished while that housekeeping line lingers, which `check-placeholders` reports separately), and the reviewer's question is *answerable* — either a delta is available (a prior stamp, a different current version, and the stamped release recoverable from the kit clone's history) or the template is provably identical between the stamped release and this one. Those last two are distinct answers and are not conflated: `diff` exits 0 when the files match, so an *empty* delta is proof there is nothing to review and suppresses the candidate on its own, while an *uncomputable* delta (a missing ingredient) leaves the reviewer nothing and still gets the whole-template candidate. Suppression reports a `Skipped:` line — naming the delta when one was written, or stating the template is unchanged since the stamped release when it was not — plus, for a real delta, an advisory naming its path
- keep the playbook-placeholder list in an `OKF-SHARED` marked block byte-identical with `scripts/check-placeholders` (enforced by `make parity`); the list is curated rather than scanned out of the template, because the template also carries brackets that stay legitimate in a filled playbook (the `tags: [...]` frontmatter list, the `[paths...]`/`[title]` argument spellings in the helper usage lines)
- leave an existing `docs/okf-map.yml` untouched and write a candidate such as `docs/okf-map.2.yml`, except when the existing map already carries at least one active `- source:` mapping and needs no `layout:` block it lacks (canonical layout detected, or the block already present) — a populated map is the owner's working mapping and the template candidate beside it carries nothing worth reviewing, the same reasoning that spares a filled goal its candidate (ADR 0018); the skip is noted in the summary with a pointer to the kit's `okf-map.yml` header for new map conventions
- leave an existing `docs/GOAL.md` untouched and write a candidate such as `docs/GOAL.2.md`, except when the existing goal already carries the kit's structure with no template brackets — a filled goal gets no template candidate. Heading detection is tolerant (ADR 0018 spirit): a goal heading may carry a title (`# Goal: <name>`) at any level, and the backlog heading may be prefixed (`## Implementation milestones`); heading style is the owner's, not a signal the goal is unfilled. Create `docs/GOAL.md` from `templates/GOAL.md` when it is missing
- skip writing a numbered candidate when the existing file already matches the kit content byte for byte, recording such matches in the manifest so pre-manifest candidates opt in
- record every candidate and kit-managed script it writes in `.okf-kit-backups/candidate-manifest` (`sha256` plus repo-relative path), and on later runs refresh in place — after a backup — a stale candidate whose digest proves it is this script's own unedited output, removing provably-ours duplicates for the same destination; owner-edited or unrecorded candidates are never touched and keep the numbered-path behavior (ADRs 0012, 0013)
- create a missing spec or ADR index seeded with an entry per knowledge file already in its directory (titles from frontmatter or the first heading) — never an empty index beside existing work — and create a missing `docs/log.md`; existing indexes and log files are left untouched with no heading-only numbered candidate, since a heading-only starter carries nothing worth reviewing (ADR 0018)
- print a completion summary whose section labels are the stable output contract of ADR 0023: `Created:`, `Updated:`, `Skipped:`, `Backed up:`, `Needs review:`, and `Advisories:` (appended under ADR 0023's new-label allowance for the warn-only mirror, skill-pairing, and template-delta notes), followed by `Verification run:`; every label prints on every run (`none` under an empty section), numbered review candidates appear under `Needs review:`, and the same breaking-change rule as the new-repo summary applies

Owner-carrying templates (`templates/CLAUDE.md`, `templates/GOAL.md`) are rendered, not copied: wherever either installer writes them — created files and numbered candidates alike — it substitutes the `[owner name]` placeholder with the target's `git config user.name`. The templates carry the placeholder inside explicit YAML shapes (`owner: "[owner name]"`, `deciders: ["[owner name]"]`) so the substituted output is a quoted string and a one-item list — a bare bracket placeholder parses as a YAML list and fails strict frontmatter validators in target repos (found in the spec-agent-cli adoption), and a hardcoded name is wrong for every adopter but the kit's author. When no identity is configured, the placeholder stays and the goal interview fills it.

Starter `docs/index.md` content written by either installer must link `GOAL.md`, the spec and ADR indexes at their layout homes (`specs/index.md` and `adr/index.md` in the canonical tree), `log.md`, and `okf-map.yml` — plus `docs/runbooks/` and a root `schemas/` directory when the target has them (ADR 0018) — and must declare `okf_version` plus the installing kit's `kit_version` read from the source `VERSION` file (ADR 0010). When a `docs/index.md` already exists and opens with a frontmatter block declaring `okf_version`, the existing-repo installer stamps `kit_version` into that frontmatter directly — after a backup — inserting the line after `okf_version` when absent, correcting it in place when it differs from the installing kit, and skipping when it already matches; no bundle-root candidate is written (ADR 0019). Otherwise the installer carries the starter content in the numbered candidate it writes beside the existing file. When the target's map relocates the stamp with `layout: stamp_file`, the declared file is the single version authority every kit tool reads, so the existing-repo installer stamps that file and only that file: stamped in place — after a backup — when it opens with a frontmatter fence (after `okf_version` when the line exists, right after the fence otherwise), and reported with a summary note when it is missing or has no frontmatter, never replaced with a candidate — it is the owner's file, not kit output. No `docs/index.md` bundle root is created or stamped beside a relocated stamp; a second stamp would leave a SessionStart drift note that never clears.

# Wrapper and verification helpers

`bash scripts/install-kit /path/to/target-repo` must choose the safe setup path:

- missing, empty, or `.git/`-only target -> `scripts/create-new-repo`
- existing target with files -> `scripts/update-existing-repo`

The wrapper must print the selected mode and delegated command before running it.

`bash scripts/verify-install /path/to/target-repo` must check installed files, settings JSON, hook commands, the env-file read deny rules, shell syntax, required `.gitignore` entries (including the env-file set), and basic `scripts/okf` execution, resolving the spec home, ADR home, and stamp file through the target's layout block (ADR 0018). It must warn — not fail — when the stamp file lacks a `kit_version` stamp, when `.env.example` is ignored, when a knowledge index lists no entries while knowledge files sit beside it, when the candidate manifest records a numbered review candidate that still exists on disk (an unresolved candidate should not reach a commit; manifest absent means nothing to check), or when a declared second-agent mirror is missing a hook or differs from its `.claude/hooks/` original (ADR 0021 — owner-edited mirrors are legitimate, the warning keeps drift visible), and it must not judge project-specific content. It must also warn about undeclared mirrors: a directory outside `.claude/hooks/` holding a byte-identical copy of a kit hook with no covering `mirrors:` entry draws an advisory recommending the declaration — byte-identical matches only, and detection never drives a sync (ADR 0021 amendment, ADR 0024).

`bash scripts/check-placeholders /path/to/target-repo` must report remaining template placeholders in `CLAUDE.md` and `docs/GOAL.md`, and missing active mappings in `docs/okf-map.yml`. It must not modify files.

# Validation

Both installers must run syntax checks for installed scripts and JSON validation for settings.

The Makefile smoke tests must exercise both installers and the source-only install, verify, and placeholder helpers.
