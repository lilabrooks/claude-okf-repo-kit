---
type: Spec
title: Validation workflow
description: Makefile validation contract for the source kit.
tags: [makefile, validation, smoke-tests]
timestamp: 2026-07-08T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Purpose

The source kit includes a `Makefile` to validate the kit before publishing or installing it.

The Makefile is for this repo only. It does not need to be copied into target repos.

# Primary command

`make test` must run all available validation checks.

`README.md` must name `make test` as the source-kit verification command.

`make check-docs` must provide a fast gate for documentation-only changes — ADR status flips, log-only edits — running the checks that actually cover `docs/` prose (the stale-reference/local-path scan, the parity gate, and the Markdown link check) plus the OKF helper sanity checks (`check-stale`, `pending`), without the installer, hook, and helper smoke simulations that a documentation edit cannot affect. It is a convenience subset of `make test`, not a replacement: changes that touch scripts, templates, `settings.json`, or `VERSION` still require `make test`.

# Required checks

The validation workflow must include:

- shell syntax checks for scripts
- shell syntax checks for installer scripts
- a semver format check for the root `VERSION` file
- optional ShellCheck linting when ShellCheck is installed
- Markdown local link checks
- JSON validation for `settings.json`
- stale-reference scanning for old names and local machine paths; the scan must run with ripgrep when installed, fall back to `grep -rnEI` otherwise, and fail rather than report success when the scanner itself cannot run
- a pipefail hazard scan: any script under `scripts/` that sets `pipefail` must contain no non-comment `| grep -q` pipeline — the early-exit consumer races its writer (SIGPIPE), and under pipefail the race silently flips the pipeline's meaning (the kit 0.3.6 shim-classifier bug); capture output and test it instead
- a parity gate (`make parity`, `scripts/check-parity.py`, stdlib-only) converting the specs' "must not drift" prose into build failures: the `OKF-SHARED` parser blocks (layout and mirrors awk) byte-identical across every script that carries them and present nowhere unlisted; the Stop hook's exclusion pattern set-equal to the union of `scripts/okf`'s workflow and meta sets; the `templates/skills/okf-*` roster named in the README install-artifacts table row, both installers (create-new-repo twice — copy plus manifest seed), `verify-install`, and the installer-scripts spec; the ADR 0023 summary labels present, in pinned order, in the scripts that print them plus the spec and the ADR; the installed surface (`check-docs-sync.sh`, `check-okf-version.sh`, `scripts/okf`) keeping bash shebangs with no python3 mention (ADR 0026's standalone-bash boundary); and every `scripts/*.py` file carrying `from __future__ import annotations` (the ADR 0026 amendment's floor convention). The gate runs in `make test` and `make check-docs` It must also check the Codex playbook template (`templates/AGENTS.md`): no Claude-style `@` imports or import-resolution claim, no `.Codex` for `.codex`, every referenced kit file actually present, and section headings paired with `templates/CLAUDE.md` (the context section being the one deliberate rename) — the three defect classes observed in a real find-and-replace port draft.
- source-kit smoke checks
- OKF source-kit stale mapping and ADR suggestion checks
- new-repo install simulation
- existing-repo install simulation
- existing-repo idempotency simulation
- brownfield adoption simulation (layout detection, seeded indexes, AGENTS.md-first staging; ADR 0018)
- candidate refresh simulation across kit template changes
- script provenance simulation across simulated kit releases (ADR 0013)
- dogfood harvest smoke check against a temp target (ADR 0014)
- install/verify/placeholder helper smoke checks
- hook behavior checks
- `scripts/okf` command smoke checks
- GitHub Actions validation that runs `make test` on push and pull request, then reruns it under a provisioned Python 3.9 — the kit's Python floor (ADR 0026 amendment) — so newer-than-floor syntax in any kit Python tool fails CI instead of a stock machine; a runner that can no longer provision the floor version is the signal to raise the floor, not to drop the pass. The floor version is declared once as a workflow-level `FLOOR_PYTHON` variable feeding both the `setup-python` input and a runtime assert that the interpreter actually is the floor, so the pass cannot silently degrade into a duplicate of the run above when an input changes or a future action resolves differently. That assert guards a different property than the pass itself — newer-than-floor syntax still dies at parse time inside `make test`, which no runtime check can catch
- Dependabot configuration at `.github/dependabot.yml` that keeps GitHub Actions workflow action versions current on a weekly schedule

# Smoke test expectations

New-repo install simulation must verify the target install layout and basic helper execution, and that a fresh target contains no `.py` file — the installed surface is bash only (ADR 0026).

New-repo install simulation must exercise `scripts/create-new-repo`.

New-repo install simulation must verify target `CLAUDE.md` comes from `templates/CLAUDE.md`, not source root `CLAUDE.md`.

New-repo install simulation must verify the installed `CLAUDE.md` carries the preloaded-context imports for `docs/GOAL.md`, `docs/specs/index.md`, and `docs/adr/index.md` (ADR 0008).

Both the new-repo and existing-repo simulations must verify that maintainer-only, source-only artifacts never reach a target: no `site/`, no `.github/workflows/pages.yml`, no `VERSION` or `Makefile`, no `docs/specs/site-content.md`, no ADR 0009 or ADR 0016 file, no `site/` mappings in the installed `docs/okf-map.yml` (or its candidate), and no `AGENTS.md` or `templates/AGENTS.md` — the Codex playbook template is opt-in, rendered only by the `okf-second-agent` skill during a port (ADR 0024), so a plain install never grows a second-agent playbook. This guards the site-content spec's source-only boundary against installer regressions.

New-repo install simulation must verify the starter `docs/index.md` declares `kit_version` and links the log and source map, that the env-file ignore entries (`.env`, `.env.*`, `!.env.example`) and `.DS_Store` were appended (ADR 0010), that the installed settings carry the env-file read deny rules (ADR 0011), that `.okf-kit-backups/candidate-manifest` is seeded with entries for the nine kit-managed files (ADRs 0013, 0015), and that the six `okf-*` skills are installed with matching frontmatter names while the installed `CLAUDE.md` keeps the resident one-liners pointing at them (ADR 0015).

Existing-repo install simulation must exercise `scripts/update-existing-repo`.

Existing-repo install simulation must verify the kit preserves an existing `CLAUDE.md`, preserves existing docs, preserves existing `.gitignore` entries, preserves existing settings entries (including the target's own permission rules), merges hook settings and the kit's permission deny rules, appends required ignore entries including the env-file set, backs up kit-managed scripts it refreshes, and writes numbered candidates for same-name Markdown/map files (the `docs/index.md` candidate carrying the `kit_version` stamp). Heading-only starters — `docs/log.md` and the spec and ADR indexes — leave existing files untouched with no numbered candidate (ADR 0018).

Existing-repo install simulation must verify same-name Markdown and map conflicts produce same-folder numbered candidates.

Existing-repo install simulation must verify any `CLAUDE.md` merge candidate comes from `templates/CLAUDE.md`, not source root `CLAUDE.md`.

Both install simulations must assert the completion-summary section labels pinned by ADR 0023 (`Created:`, `Updated:`, `Skipped:`, plus `Backed up:`, `Needs review:`, and `Advisories:` for the updater, and `Verification run:`), so a label change fails the build instead of a downstream consumer's CI.

Existing-repo install simulation must also verify the updater's populated-map and skill-pairing behavior: a target whose canonical-layout `docs/okf-map.yml` already carries an active mapping gets no map template candidate and a summary note saying so, a second-agent skill home holding a partial `okf-*` set draws the pairing advisory naming the missing skills, and completing the set silences it.

Existing-repo install simulation must verify that an unresolved numbered candidate surfaces after installation: the SessionStart hook emits a valid-JSON kit-candidate-review note naming the candidate, `verify-install` warns about it, and deleting the candidates silences the note. It must also verify the hook's JSON escaping: a recorded candidate whose filename contains a double quote still yields a payload that parses as JSON and carries the name intact.

Existing-repo idempotency simulation must verify repeated updates do not duplicate `.gitignore` entries, settings hooks, permission deny rules, or identical numbered candidates.

Brownfield adoption simulation must verify, against a target with an `AGENTS.md` playbook, a pure-import `CLAUDE.md` shim, specs under `docs/architecture/specification/`, three-digit body-status ADRs, and a root `schemas/` directory: the updater records the detected layout in the installed map, creates no parallel `docs/specs/` tree, seeds both indexes from the existing files, stages the kit playbook as an `AGENTS.md` numbered candidate with rewritten imports while leaving the shim untouched, suppresses the goal-template candidate for a filled goal whose headings use the tolerated variants (`# Goal: <title>`, `## Implementation milestones`), links runbooks and schemas from the starter `docs/index.md`, and produces a target that passes `verify-install`. In that target, `scripts/okf` must scaffold the next three-digit ADR into a seeded index, list a body-status proposed ADR in `pending` without flagging tolerated statuses as missing, and honor the layout for `draft` (ADR 0018). The same simulation must also verify shim classification at three edges: a commented `@AGENTS.md` shim (import plus short heading-free prose) gets the AGENTS.md-first staging with no `CLAUDE.2.md`; a shim that redirects first and then carries the preloaded-context block under a heading (the spec-drift shape — prose, `@AGENTS.md`, a heading, prose, further imports, within the 15-line budget) also gets the AGENTS.md-first staging (ADR 0025); while a real playbook that merely imports `AGENTS.md` under a heading keeps the `CLAUDE.2.md` candidate path (ADR 0022). It must also verify classification determinism: repeated classifier runs under `set -o pipefail` against a real-size playbook (a kit-template-sized `CLAUDE.md` beside an `AGENTS.md`) must classify it as a playbook every time, and the updater must stage `CLAUDE.2.md` — guarding against early-exit pipeline consumers whose SIGPIPE, under pipefail, silently flips the shim test (the race that misclassified a 187-line playbook as a pure shim in live use).

Special-character path simulation must run `create-new-repo`, `update-existing-repo` (twice, for idempotency), and `verify-install` against target paths containing glob characters (square brackets) and spaces, plus a helper and SessionStart-hook run in the existing-repo target — guarding against quoting and glob-expansion regressions observed in downstream template tooling.

Second-agent mirror simulation must verify, across a simulated kit release (ADR 0021): a target with no `mirrors:` declaration grows no second-agent directories; an undeclared byte-identical hook copy draws the advisory from `verify-install`, the SessionStart hook (valid JSON), and the updater's own `Advisories:` section — which names the `mirrors:` declaration to add — and the declaration silences all three (ADR 0024); declaring a mirror directory — with a trailing slash, proving the declaration normalizes identically for the sync and the advisory — makes the updater write both hooks there byte-identical to `.claude/hooks/`, idempotently; a kit hook change refreshes an unedited mirror in place with no candidate; an owner-edited mirror keeps its content with the kit version staged as a numbered candidate; `verify-install` reports matching mirrors and warns on drifted ones; and `check-stale` stays clean with a `mirrors:` block in the map (the mappings parser must not leak a following top-level list's items into the last mapping's docs).

Second-agent mirror simulation must also verify the hand-made-mirror path (ADR 0013 amendment): a mirror copied into place by hand, with no manifest provenance, is refreshed in place on a kit release with no candidate staged and stays byte-identical to `.claude/hooks/`, and the same holds across a second consecutive release — the recurrence observed in live upgrades. It must further verify that a `.claude` original preserved for review (owner-edited) does not leave its mirror refreshed alone.

Candidate refresh simulation must also verify the filled-playbook suppression: a kit-derived playbook with no template blanks left, on a version-crossing run, gets no whole-template candidate, gets the kit-only delta written to the backups, and reports the filled-playbook `Skipped:` line; while an unfilled playbook on the same kind of run still receives the whole-template candidate carrying the blanks to fill. It must further verify that a version-crossing run whose template did *not* change suppresses the candidate on that ground alone: no whole-template candidate, no delta advisory, and a `Skipped:` line stating the template is unchanged since the stamped release — the empty-delta case, which must not be treated as an uncomputable one. The never-kit-derived owner playbook covered earlier in the same simulation must keep its whole-template candidate, guarding the kit-derived precondition, and the runs made before that fake kit gains git history guard the uncomputable-delta fall-through.

Hook simulation must also verify the SessionStart map-coverage note: a map with active mappings stays silent, while a map with no active mapping draws the valid-JSON note that `check-stale` has nothing to guard yet.

Candidate refresh simulation must verify that when kit content changes between updater runs, the updater refreshes its own stale candidate in place instead of numbering past it, and that an owner-edited candidate is left untouched with a new number used instead (ADR 0012). It must also verify the template-delta review aid against a fake kit carrying its own git release history: an upgrade that crosses kit versions and refreshes a playbook candidate writes `CLAUDE.md.template-delta.diff` under the run's backup directory covering only the stamped release onward (not the whole template) with an `Advisories:` pointer, and a rerun that crosses no version stays delta-silent.

Script provenance simulation must verify that across a simulated kit release: an unedited kit-managed script is refreshed in place with a backup and no candidate; an owner-edited script keeps its content, with the kit version written as a same-folder numbered candidate under the review section; and a repo with no manifest takes the preserve-plus-candidate path rather than being overwritten (ADR 0013).

The dogfood harvest smoke check must verify, against a temp target with the registry redirected via `OKF_DOGFOOD_REGISTRY`: registration baselines at HEAD and rejects a duplicate name, a fresh registration reports a zero commit delta with kit-managed files matching, committed target work surfaces the commit, the new `docs/log.md` lines, and the kit-mention flag, an owner-edited hook is classified as such alongside an uncommitted-changes note, and `mark` resets the delta to zero (ADR 0014).


Install helper smoke tests must verify:

- `scripts/install-kit` chooses new-repo mode for missing or empty targets
- `scripts/install-kit` chooses existing-repo mode for non-empty targets
- `scripts/verify-install` passes after installation
- `scripts/check-placeholders` reports template placeholders after installation
- `scripts/check-placeholders` passes after placeholders and active mappings are filled

Hook smoke tests must cover:

- implementation changes with no docs update block while the map carries no active mapping (the crude prefix gate)
- with active mappings, the prefix gate stands down: a stale mapped source blocks through `check-stale`, a mapped governing doc outside `docs/` (a schema) passes, and unmapped-only changes no longer hard-block (ADR 0018)
- mapped implementation changes with unrelated docs still block
- mapped implementation changes with mapped docs pass
- README-only edits pass
- a `stop_hook_active` stdin payload downgrades a would-be block to a stderr warning that allows the stop; a payload without it still blocks
- end-anchored exclusions (map-less fixture): a lookalike file such as `LICENSE-MIT` blocks, while the exact excluded name passes
- second-agent config (`.codex/`, `.agents/`, `AGENTS.md`, `Codex.local.md`) alone does not block, and a `.env.example`-only change does not block
- the SessionStart hook reports the proposed-ADR count (including body-status conventions), skips numbered candidates, emits valid JSON, and stays silent about `okf_version` when the stamp file is absent

OKF helper smoke tests must verify draft generation, ADR suggestion behavior, the non-blocking unmapped-file note from `check-stale` (listing unmapped implementation files while skipping agent config such as `.codex/`, `.agents/`, `AGENTS.md`, and `Codex.local.md`), ADR and spec scaffolding (numbering, `status: proposed`, index entries), numbering-width detection against pre-existing numbered ADRs, seeded index creation, and the `pending` listing including its missing-status flag and the tolerant status forms (ADR 0018). Naming-convention tolerance (ADR 0019) must be covered too: a sole alpha-prefixed ADR convention is continued (`adr-0009-*` yields `adr-0010-*`), bare-numeric names keep precedence when both forms coexist, a `spec-NNN-*` sequence is continued by `new-spec` while bare-numeric chapter names still yield plain `<slug>.md`, and a table-style index gets no appended bullet — the command reports the entry for a manual add. Installer smoke tests must also verify the in-place `kit_version` stamp: an existing bundle root with `okf_version` frontmatter gains the stamp with no `docs/index.2.md` candidate, idempotently across repeated runs; and a target whose map relocates the stamp with `layout: stamp_file` gets that file restamped in place as the only stamp — no `docs/index.md` is created beside it, idempotently, and the SessionStart hook stops citing the pre-upgrade version.

This kit validates OKF helper behavior and source-to-doc freshness. Target repos that need stricter OKF frontmatter or link rules should add a repo-local docs validator to their own quality gate.

Markdown link checks must ignore fenced code blocks and external URLs.

# Target repo verification

Installed target repos must be verifiable without the source Makefile.

Target verification docs must include:

- `python3 -m json.tool .claude/settings.json`
- `bash -n scripts/okf`
- `bash -n .claude/hooks/check-docs-sync.sh`
- `bash -n .claude/hooks/check-okf-version.sh`
- `bash scripts/okf check-stale`
- `bash scripts/okf adr-suggest`
