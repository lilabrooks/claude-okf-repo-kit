---
type: ADR
title: Stale-candidate refresh via digest manifest
description: Let the updater refresh numbered candidates it can prove it wrote, tracked by content digest, instead of numbering past them each kit release.
tags: [installer, candidates, upgrade, safety]
generated: { by: claude-code/fable-5, at: 2026-07-09T00:00:00Z }
owner: Lila Brooks
deciders: [Lila Brooks]
status: accepted
---

# Status

Accepted (implemented at the owner's direction)

# Context

`update-existing-repo` never overwrites existing Markdown/map files; it writes numbered review candidates (`CLAUDE.2.md`) instead, and skips writing when an identical candidate already exists (ADR 0005, ADR 0006). That skip only matches byte-for-byte. When the kit's templates change between releases, an old candidate no longer matches, so the updater numbers past it — observed on repo-pulse, where a second updater run at kit 0.1.1 produced `CLAUDE.3.md` and `docs/index.3.md` beside the stale `.2` files. Across many releases, an unattended repo accumulates candidate strata the owner never asked for, and the kit-version drift loop (ADR 0010) makes repeated updater runs the expected workflow.

The constraint is the safety contract: a candidate is owner-review material, and an owner may have edited one in place as a merge workspace. The updater must never destroy content it cannot prove is its own.

# Decision

- The updater keeps a manifest at `.okf-kit-backups/candidate-manifest` (already git-ignored in targets): one `sha256<TAB>relative-path` line per candidate it writes.
- When a new candidate is needed and existing candidates are present, each is checked against the manifest. A candidate whose current digest was recorded for that path is provably the updater's own unedited output: the first such candidate is backed up and refreshed in place with the new kit content; any further provably-ours duplicates for the same destination are backed up and removed.
- Any candidate that does not match the manifest — owner-edited, hand-made, or written before the manifest existed — is never touched; the updater falls back to writing the next free number, exactly as before.
- A skip because an existing candidate already matches the new kit content also records that candidate in the manifest (content identical to kit output is kit output by definition), so pre-manifest installs opt in after one run.
- Refreshes are reported under "Needs review", removals under "Updated", and every replaced or removed file lands in the timestamped backup directory first.

Alternatives considered:

- Keep numbering up (status quo). Rejected: candidate strata grow with every release; the drift-reporting loop makes this the common path, not an edge case.
- Overwrite the highest-numbered candidate with backup, unconditionally. Rejected: an owner mid-merge inside a candidate would silently lose work to a git-ignored backup directory; "backed up" is not "safe" for review material.
- Mark kit-written candidates with an in-file comment. Rejected: candidates must stay byte-identical to what would be installed (that is what makes them diffable and mergeable), and comment syntax varies by file type.
- Store the manifest outside `.okf-kit-backups/`. Rejected: the backups directory is already the updater's git-ignored state area; a new dotfile adds install surface. Losing the manifest (owners may prune backups) degrades gracefully to numbering.

# Consequences

Repeated updater runs across kit releases converge on a single fresh candidate per file instead of strata. The never-overwrite promise is preserved in the only form that matters: nothing the owner created or edited is ever modified, and even provably-ours refreshes are backed up first.

The manifest is best-effort state: deleting `.okf-kit-backups/` forfeits refresh (falls back to numbering) until candidates are re-recorded. Manifest lines for replaced content become inert; the file grows trivially and is never pruned.

`verify-install` intentionally ignores the manifest — it is updater state, not install contract.

# Rollback / revisit trigger

Remove the manifest helpers and the refresh branch from `write_numbered_candidate`; behavior reverts to pure numbering and existing manifests become inert files inside an ignored directory. Revisit if owners report surprise at in-place candidate refreshes (tighten to a `--refresh` opt-in flag) or if candidate workflows move into the kit-version drift hook, which would warrant its own ADR.
