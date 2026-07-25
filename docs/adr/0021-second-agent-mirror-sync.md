---
type: ADR
title: Kit-managed second-agent mirror sync
description: Teach the updater to refresh declared second-agent hook mirrors in place, byte-identical to the .claude/hooks originals, removing the manual re-sync step; skills stay owner-managed.
tags: [adr, second-agent, installer, mirrors]
generated: { by: claude-code/fable-5, at: 2026-07-14T19:02:00Z }
status: accepted
---

# Status

Accepted (2026-07-18, by the owner). Implementation landed with the acceptance: the `mirrors:` declaration, the updater sync through the ADR 0013 provenance path, `verify-install` parity warnings, and smoke coverage.

# Context

ADR 0018 made the kit tolerant of a second agent: `AGENTS.md`, `.codex/`, and `.agents/` are treated as agent config, `check-stale` skips them, and a ported playbook is staged rather than overwritten. What the kit never took on is keeping the second agent's *hook mirrors* current. The `okf-kit-upgrade` skill's step 4 tells the owner to copy the refreshed `.claude/hooks/` scripts over their mirrors by hand after every kit upgrade, because `update-existing-repo` manages only the `.claude/hooks/` copies and does not know other agents' directories exist.

The live spec-agent-cli adoption is the worked example. A Codex stack (`.codex/hooks/`) landed beside the Claude stack, and the two hook copies must stay byte-identical for both agents to enforce the same guardrails. Nothing mechanical kept them so: a hook edited on the Claude side leaves the mirror stale with no signal until a Codex session behaves differently. Kit 0.3.2 addressed the *detection* half by recommending that a mirror-maintaining repo add a parity check to its own gate — but detection is not sync. The owner still copies files by hand on every kit hook change, and that is exactly the kind of invariant mechanic the kit's division of labor says should live in code, not discipline.

# Decision

`update-existing-repo` learns to refresh declared second-agent hook mirrors. A target that keeps mirrors declares their locations — a small `mirrors:` list in `docs/okf-map.yml` naming the mirror hook directories (for example `.codex/hooks`). When a kit hook is refreshed in place under `.claude/hooks/`, the updater writes the same content, byte-for-byte, into each declared mirror directory, reusing ADR 0013's backup-and-provenance path: a mirror file is overwritten only when it is absent or its manifest digest proves it is prior unedited kit output, and an owner-edited mirror is left untouched with the kit version staged as a numbered candidate.

The scope is deliberately narrow:

- **Hooks only.** Only the two lifecycle hook scripts are synced, because they are meant to be byte-identical across stacks.
- **Skills stay owner-managed.** Workflow skills carry deliberate per-agent substitutions (`CLAUDE.md` ⇄ `AGENTS.md`, `.claude` ⇄ `.codex`) the kit cannot mechanically reproduce, so the updater never writes mirror skills. Skill-set pairing remains the target's own check (kit 0.3.2).
- **Declared, not detected.** No directory is treated as a mirror without an explicit `mirrors:` entry; an undeclared `.codex/hooks` keeps today's manual behavior.

# Alternatives considered

- **Keep the manual step plus the 0.3.2 recommendation (status quo).** The recommendation catches drift but never fixes it — the owner still syncs by hand every upgrade. This ADR exists to remove that manual mechanic, but the status quo remains the fallback if the maintenance cost outweighs the benefit for a mostly Claude-only user base.
- **Ship a parity-check helper (`scripts/okf check-mirrors`) instead of syncing.** Still detection, not sync, and it duplicates what the target's own gate already does under 0.3.2; shipping a check into arbitrary target stacks also cuts against the division of labor that keeps target-side tests in the target.
- **Auto-detect mirror directories** by scanning for `.codex/hooks`, `.agents/`, and the like. Rejected as fragile: the updater cannot reliably tell a mirror from the target's own scripts, and a wrong guess overwrites real work. Explicit declaration matches the `layout:` block precedent.
- **Sync skills too, applying the substitutions mechanically.** Rejected: the kit cannot guarantee it reproduces every legitimately agent-specific adaptation, and a bad rewrite is worse than a manual copy. Presence-parity is the target's concern.

# Consequences

- A kit hook change propagates to every declared mirror in a single updater run; the manual re-sync step in `okf-kit-upgrade` disappears for declared mirrors and stays only for skills and undeclared mirrors.
- New surface to build and test: a `mirrors:` declaration parsed from `docs/okf-map.yml`, the updater applying ADR 0013's provenance and backup logic to mirror paths, and smoke coverage for the sync, the provenance guard on an owner-edited mirror, and the Claude-only no-op.
- The 0.3.2 target-side parity check becomes belt-and-suspenders rather than the only guard: it still catches an undeclared mirror or a hand-edit the updater deliberately left alone.
- `verify-install` and `harvest-dogfood` may need to understand the `mirrors:` declaration so their reports stay accurate.

Amendment (2026-07-19, with ADR 0024): the "auto-detect mirror directories" rejection above concerns the updater *acting* on a detected guess, where a wrong guess overwrites real work. Detection used only to *warn* is a different risk class: `verify-install` and the SessionStart hook now flag a byte-identical copy of a kit hook in an undeclared directory and recommend the `mirrors:` declaration, and a wrong guess there costs one advisory line. Declaration remains the only path to mechanical sync.

# Rollback / revisit trigger

Revisit if the declaration proves rarely used (the user base stays overwhelmingly Claude-only), if applying provenance to mirror files makes candidate review confusing, or if a future first-class multi-agent kit design supersedes the mirror model entirely. Rollback means dropping the `mirrors:` sync and declaration and restoring the manual step, with the kit 0.3.2 recommendation left in place as the guard.
