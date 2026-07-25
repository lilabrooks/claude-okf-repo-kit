---
type: Spec
title: OKF helper command
description: Expected behavior for the repo-local scripts/okf helper.
tags: [okf, bash, cli]
generated: { by: claude-code/opus-5, at: 2026-07-05T00:00:00Z }
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Purpose

`scripts/okf` is a repo-local Bash helper included with this kit.

It is not an official OKF CLI, not a global command, and not a prompt.

# Commands

`bash scripts/okf check-stale` checks whether changed source files have a changed mapped spec or ADR.

`bash scripts/okf draft [paths...]` writes fact-based spec drafts under `docs/specs/_drafts/`. It is aimed at existing codebases with undocumented modules; greenfield repos usually write specs as modules land.

`bash scripts/okf adr-suggest` prints ADR candidates for decision-shaped changes, each with a matching `new-adr` scaffold command.

`bash scripts/okf new-adr <slug> [title...]` scaffolds the next-numbered ADR with `status: proposed` and indexes it.

`bash scripts/okf new-spec <slug> [title...]` scaffolds a spec skeleton and indexes it.

`bash scripts/okf pending` lists ADRs still `status: proposed` and flags ADRs missing a status field.

# Map discovery

After installation, the helper reads `docs/okf-map.yml`.

In this source-kit repo, it may also read root `okf-map.yml` as the install template when `docs/okf-map.yml` is absent.

# Layout block

The map file may carry an optional top-level `layout:` block relocating the knowledge homes for repos that already keep specs or ADRs elsewhere (ADR 0018). Recognized keys, with defaults: `specs_dir` (`docs/specs`; drafts live in `<specs_dir>/_drafts`), `adr_dir` (`docs/adr`; the index lives at `<adr_dir>/index.md`), and `stamp_file` (`docs/index.md`; read by the SessionStart hook, not this helper). Every command resolves its paths through the block; absent keys fall back to the defaults, so canonical repos behave exactly as before.

The parser is a small awk routine over flat `key: value` lines, tolerant of quotes and comments. Inline copies live in `check-okf-version.sh`, `verify-install`, `update-existing-repo`, and `harvest-dogfood` so each tool stands alone (hooks especially, when mirrored into another agent's config); the copies must stay in sync with this helper's. The shared programs — the layout parser and the mirrors parser — are shell string constants wrapped in `OKF-SHARED-BEGIN`/`OKF-SHARED-END` markers, and `make parity` asserts every copy is byte-identical to the canonical block, so parser divergence fails the build instead of shipping (two of the three bugs the 0.3.9 audit confirmed lived in exactly this divergence).

# Stale mapping behavior

`check-stale` uses repo-relative changed files from Git.

For each changed source file mapped in `docs/okf-map.yml`, the check passes when at least one mapped spec or ADR changed.

A changed `docs/log.md` also passes as the documented rationale path when no spec or ADR edit is warranted.

The check ignores workflow and agent-config files: `docs/`, `.claude/`, `.codex/`, `.agents/`, `CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md`, `Codex.local.md`, and `scripts/okf`. A second agent's `.codex/`, `.agents/` (its skill home), `AGENTS.md`, and `Codex.local.md` are config for the same checkout, not implementation, so they neither go stale nor appear in the unmapped note. Layout-relocated spec and ADR homes count as workflow files even when they sit outside `docs/`.

Map patterns match with shell globbing where `*` crosses `/` — `app/*` and `app/**` govern the same tree. This over-matches relative to gitignore intuition and never under-matches; write `**` for recursive intent anyway, so the map reads as it behaves.

Outside hook mode, `check-stale` also prints a non-blocking note listing changed implementation files that match no mapping, so new source areas get mapped as they gain governing docs. Repo-meta files (README, changelog, license, ignore and editor config, `.env.example`) are excluded from the note, and unmapped files never change the exit status. Hook mode stays silent about unmapped files to avoid false blocks.

The workflow/agent-config exclusions and the repo-meta set are, together, exactly the Stop hook's non-implementation list (Claude hooks spec); the two lists must not drift, and `make parity` asserts their set-equality.

# Emitted provenance

Every scaffolder — `draft`, `new-adr`, and `new-spec` — records when it produced the skeleton as an OKF 0.2 provenance mapping, `generated: { by: process:okf-scaffold, at: <ISO 8601 UTC> }` (ADR 0027). The retired v0.1 `timestamp` key is not emitted. The actor is the `process:<id>` form because a scaffold skeleton is machine-produced; whoever fills the document in may overwrite `by` with their own actor, and the helper does not require it. The mapping is written in YAML flow form on one line, which parses as a two-key mapping and keeps one line per frontmatter key.

Nothing in the helper rewrites the frontmatter of documents that already exist, so a repo carrying legacy `timestamp` keys is left alone and migrates on its own schedule under the OKF version policy.

# Draft behavior

`draft` must write to the drafts folder — `<specs_dir>/_drafts/`, which is `docs/specs/_drafts/` by default.

Drafts are review-only scaffolding. They must not be treated as accepted specs until a human or agent rewrites and promotes them into the spec home (`docs/specs/` by default).

Drafts may include observable facts such as file counts, language extensions, public surface clues, tests found, and mapped docs. The public-surface scan prefers ripgrep and falls back to plain recursive `grep` when `rg` is not installed, so the clues section degrades gracefully instead of silently reporting nothing on machines without it.

# ADR suggestion behavior

`adr-suggest` must stay conservative.

It may suggest ADRs for dependency, persistence, cache, queue, worker, scheduler, auth, security, privacy, API, deployment, or ownership-boundary changes.

Machine-readable contract schemas (JSON Schema, GraphQL, proto) classify under the public API/contract suggestion, not persistence; persistence still matches migrations, SQL, and database paths. The printed draft path follows the configured ADR home.

It should stay quiet for local refactors, formatting, test-only changes, and bug fixes that do not create a standing decision.

# Scaffolding behavior

`new-adr` scaffolds into the ADR home and follows whatever numbering already exists there (ADRs 0018, 0019): the next number is the highest existing numeric prefix plus one, zero-padded to the widest existing prefix width — a repo with `001-*.md` ADRs gets `017-`, never a parallel `0001-` sequence — and four digits when the directory holds no numbered ADRs. Bare-numeric names take precedence; when none exist and every alpha-prefixed name (`adr-0001-*.md`: an alphabetic word, hyphen, digits, hyphen) shares one prefix word, that convention is continued instead (`adr-0011-<slug>.md`). Mixed prefixes fall back to the four-digit default. The scan ignores `index.md` and installer-written `*.N.md` review candidates, matching the pending scan. It writes frontmatter with at least `type: ADR`, a title, a `generated` provenance mapping, and `status: proposed`, and lays out the required sections: status, context, decision, alternatives considered, consequences, and rollback/revisit trigger.

`new-spec` writes `<specs_dir>/<slug>.md` with `type: Spec` frontmatter and purpose, contract, and verification sections; the contract section prompts for the example interactions users actually give the surface, including a rejected or edge input. When the spec home's sole numbered convention is an alpha-prefixed ID sequence (`spec-000-*.md`), the sequence is continued (`spec-009-<slug>.md`); bare-numeric chapter names (`01-overview.md`) are deliberately not followed, since chapter position is an editorial decision, and those repos keep plain `<slug>.md` (ADR 0019).

Both commands append an entry to the matching `index.md`, refuse to overwrite existing files, and emit bracketed placeholders the author must fill — a scaffold is a skeleton, not a decision or a contract. A missing index is created seeded with an entry per knowledge file already in the directory (titles from frontmatter or the first heading), so a fresh index never lists less than its directory holds. When the existing index contains a table row (a line starting with `|` — the last line is no signal, since real table indexes keep prose after the table), nothing is appended — a bullet would corrupt a table-style index and generating a row means guessing its columns — and the command instead prints the entry for the author to add in the index's own format (ADR 0019).

# Pending review behavior

`pending` scans the ADR home's `*.md` files, excluding the index and installer-written numbered review candidates (`*.N.md`), which are not live ADRs. Status detection tolerates brownfield conventions (ADR 0018): frontmatter `status:` first, then a `- Status: X` body bullet, then the first word following a `# Status`/`## Status` heading — bullet and heading matched case-insensitively (`- STATUS:` counts) and normalized to the lowercased first word, so `Accepted (2026-07-12)` reads as `accepted`. It lists files whose status is `proposed` with their titles (frontmatter `title:`, falling back to the first `#` heading), and separately flags files with no status in any recognized form, since those are invisible to the proposed-ADR review scan. It is informational and always exits zero. The SessionStart hook's inbox count applies the same detection.
