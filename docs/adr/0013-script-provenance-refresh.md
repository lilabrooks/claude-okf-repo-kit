---
type: ADR
title: Kit-managed script refresh via manifest provenance
description: The updater refreshes kit-managed scripts in place only when their content is provably unedited kit output; owner-edited scripts are preserved with the kit version staged as a numbered candidate.
tags: [adr, installer, safety]
timestamp: 2026-07-11T21:33:56Z
status: accepted
---

# Status

Accepted (2026-07-11, at the owner's direction; implementation was already in place per the propose-then-implement policy)

# Context

`update-existing-repo` treated the kit-managed scripts (`.claude/hooks/check-docs-sync.sh`, `.claude/hooks/check-okf-version.sh`, `scripts/okf`) as always-overwrite: a differing target file was backed up into the git-ignored `.okf-kit-backups/` and replaced, and the summary listed it under "Updated", not "Needs review". Both dogfood repos broke this assumption in the same week: repo-pulse hardened its docs-sync hook (stop-loop guard, anchored exclusions) and skywatch made both hooks agent-portable — and repo-pulse's log explicitly flags the fear that "the next kit update does not revert it". The next `VERSION` bump would have done exactly that: drift note at session start, owner runs the updater, downstream hardening silently reverted with the only copy left in an ignored directory.

ADR 0012 already solved the same problem for Markdown review candidates with a digest manifest under `.okf-kit-backups/`. This ADR extends that mechanism from the candidates the updater writes to the live scripts it installs.

# Decision

The candidate manifest (`.okf-kit-backups/candidate-manifest`, `sha256` plus repo-relative path) also records every kit-managed script the installers write:

- `create-new-repo` seeds the manifest with the digests of the three scripts it installs, so fresh installs carry provenance from day one.
- `update-existing-repo` replaces its unconditional script overwrite with a provenance check: a missing file is created and recorded; identical content is skipped and recorded (the opt-in path for pre-manifest installs); differing content whose digest is recorded — provably the kit's own unedited output — is backed up and refreshed in place; differing content with no recorded provenance is treated as owner-edited, left untouched, and the kit version is written as a same-folder numbered candidate (for example `.claude/hooks/check-docs-sync.2.sh`) listed under "Needs review".

Settings stay outside this mechanism: `.claude/settings.json` is merged non-destructively, and Markdown/map files already go through the ADR 0012 candidate flow.

# Alternatives considered

- Keep overwrite-with-backup: rejected — the backup lands in a git-ignored directory and the summary gives no signal that owner content was replaced; both dogfood repos would have lost real hardening.
- Never overwrite scripts (always write candidates): rejected — unedited installs would accumulate candidate files on every release for no reason; ADR 0012 showed candidate strata are their own failure mode.
- Detect edits by comparing against every historical kit release (a shipped digest list): rejected — requires maintaining a release-digest archive in the kit and still misses repos installed from unreleased commits; the per-working-copy manifest needs no history.
- Recording provenance in tracked files or in-file markers: rejected in ADR 0012 and unchanged here — scripts must stay byte-identical to kit output, and the manifest belongs with the backups it protects.

# Consequences

- Downstream hook hardening survives kit updates; the owner reviews a candidate diff instead of losing work.
- Pre-manifest installs (repo-pulse, skywatch today) take the safe path on their first post-0.1.2 update: their edited scripts are preserved with kit candidates to merge by hand; repos whose scripts still match some kit output opt in via the content-match record after one run.
- Provenance is per working copy: the manifest is git-ignored and does not travel with clones, so a fresh clone's first update falls back to preserve-plus-candidate rather than refresh. That is the intended failure direction (never silently overwrite).
- `install-kit`, `verify-install`, the installer spec, the validation spec's smoke tests, and the README updater description must stay in sync with this behavior.

Amendment (2026-07-23, kit 0.3.11): the manifest is no longer the only accepted proof that content is unedited kit output. A *declared* second-agent hook mirror (ADR 0021) also qualifies when its content is byte-identical to the pre-refresh `.claude/hooks/` original, because ADR 0021 requires declared mirrors to equal that original — matching it is the invariant holding, not an owner edit. The manifest-only rule produced a real defect the fleet hit twice: a mirror created or adopted by hand never enters the manifest, so every later upgrade re-staged the same candidate whose review was a foregone conclusion. The safety direction is unchanged — the second proof is an equality test against known-good content, never a guess, and it applies only when the `.claude` original itself carries the incoming kit content, so a preserved original keeps its mirror preserved too.

# Rollback / revisit trigger

Revert by restoring the unconditional `copy_with_backup` path if the candidate flow proves noisier than the overwrite it replaced (e.g. owners routinely adopt kit candidates unchanged and the extra review step adds no safety). Revisit if Claude Code gains first-party managed-file provenance, or if the manifest's per-working-copy scope causes repeated candidate churn across cloned checkouts in practice.
