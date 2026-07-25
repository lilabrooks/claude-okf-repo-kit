---
type: Spec
title: Claude hooks
description: Stop and SessionStart hook behavior for the installed kit.
tags: [claude-code, hooks, docs]
generated: { by: claude-code/fable-5, at: 2026-07-05T00:00:00Z }
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

README, changelog, license, `.gitignore`, `.editorconfig`, `.env.example`, Claude local memory, hook/helper files, and agent config — `.claude/`, `CLAUDE.md`, plus a second agent's `.codex/`, `.agents/` (its skill home), `AGENTS.md`, and `Codex.local.md` when present — are not treated as implementation files. File-name exclusions are end-anchored exact matches (so `LICENSE-MIT` or `CLAUDE.md.bak` count as code); directory exclusions keep prefix semantics.

This non-implementation list is exactly the union of the `check-stale` exclusions in `scripts/okf` — its workflow/agent-config set and its repo-meta set (OKF helper command spec). A file added to either side is added to the other in the same change; the two lists must not drift, and `make parity` asserts their set-equality so drift fails the build instead of shipping (the `.agents/` gap fixed in 0.3.9 lived exactly here, guarded until then by prose alone).

The hook honors `stop_hook_active` from the hook stdin payload: after a prior block in the same stop cycle it warns on stderr and allows the stop instead of blocking again, so a session that cannot write to `docs/` (a read-only sandbox, for example) never loops. Manual runs without a stdin payload behave as if the guard were absent.

The hook emits JSON for Claude Code and exits successfully, allowing Claude Code to continue the turn rather than treating the hook itself as a shell failure. Its block message points at the repo playbook (`CLAUDE.md`; `AGENTS.md` if present) rather than a single agent's file, and both hooks resolve the repo root through `CLAUDE_PROJECT_DIR`, then `CODEX_PROJECT_DIR`, then the current directory, so unmodified copies work when mirrored into another agent's hook config.

# SessionStart hook

`.claude/hooks/check-okf-version.sh` checks the declared `okf_version` in the stamp file — `docs/index.md` by default; the `layout: stamp_file` key in `docs/okf-map.yml` relocates it (ADR 0018) — against the latest OKF spec version published by the official OKF repo. When the stamp file is absent or declares no `okf_version`, the check stays silent and skips the network fetch entirely — the same absent-stamp contract `kit_version` has always had — so brownfield repos without a bundle root are not nagged every session.

The same hook also checks the declared `kit_version` in the same stamp file — stamped by the installers — against the kit's published `VERSION` file on the source repo's main branch (ADR 0010). It stays silent when the stamp file carries no `kit_version` stamp.

The hook fails silent when offline or when the upstream spec or version file cannot be parsed.

The same hook also reports the ADR review inbox: it counts files under the ADR home (`docs/adr/` by default, per the layout block) whose status is `proposed`, skipping `index.md` and installer-written numbered candidates — the same files `bash scripts/okf pending` lists, with the same tolerant status detection (frontmatter `status:`, then a `- Status:` bullet, then a `# Status` section, normalized to the lowercased first word; ADR 0018) — and notes the count so proposed decisions stay visible every session instead of only in the goal-met report. This check is local and offline; it stays silent at zero.

The same hook also reports unresolved numbered kit candidates: it reads the machine-local candidate manifest (`.okf-kit-backups/candidate-manifest`), selects the recorded paths with numbered-candidate names (`CLAUDE.2.md` and similar), and notes any that still exist on disk — inactive review copies from an install or upgrade that should be merged and deleted, not committed. The note tells the agent to remind the owner rather than resolve candidates itself, matching the installed playbook's kit-version policy. Local and offline; silent when the manifest is absent (fresh clone, pre-manifest install) or every recorded candidate is gone.

The same hook also reports map coverage: when the map file exists but carries no active mapping (no uncommented `- source:` entry), it notes that `check-stale` has nothing to guard and the Stop hook is still on its coarse `docs/` gate, and that mappings should be added as source areas gain their governing specs or ADRs. Local and offline; silent once a mapping exists and when no map file is present at all (the ADR 0018 no-nag contract).

The same hook also carries the undeclared-mirror advisory (ADR 0021 amendment, ADR 0024): it scans a bounded depth for byte-identical copies of the two kit hooks outside `.claude/hooks/` (skipping `.git`, `.okf-kit-backups`, and `node_modules`), and notes any directory not covered by the map's top-level `mirrors:` list, recommending the declaration and pointing at the `okf-second-agent` skill. Byte-identical matches only — a same-named but different file may be the target's own script and draws no claim — and detection never drives a sync; the safe updater acts only on declared mirrors. The mirrors parser is a minimal inline copy of the `verify-install` parser so a mirrored copy of the hook stands alone. Local and offline; silent when every mirror-shaped directory is declared.

When anything is detected, the hook injects context for Claude Code rather than modifying files directly. All notes — OKF drift, kit drift, the ADR inbox, unresolved candidates, map coverage, and the mirror advisory — are combined into a single valid-JSON context injection, with backslashes and double quotes escaped at the emit boundary so an odd filename or stamp path embedded in a note cannot break the payload. The installed `CLAUDE.md` policies tell Claude Code what to do with each note.

# Version migration policy

Minor OKF version bumps may be migrated automatically before the first task of a session.

Major OKF version bumps require a migration summary and user approval before editing docs.

Version migrations must only change formatting, frontmatter, and structure. They must not rewrite spec or ADR content.
