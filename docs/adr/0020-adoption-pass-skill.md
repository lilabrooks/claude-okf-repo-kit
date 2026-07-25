---
type: ADR
title: Guided brownfield adoption as an installed skill
description: Deliver the thorough first-time adoption pass — inventory, map, backfill, validate — as an installed okf-adopt skill with adapt-in-place as the default and migration to canonical as an owner-directed option, instead of growing the installer into a converter.
tags: [adr, brownfield, adoption, skills]
generated: { by: claude-code/fable-5, at: 2026-07-14T00:55:38Z }
status: accepted
---

# Status

Accepted (2026-07-14, at the owner's direction; implementation landed with the proposal per the propose-then-implement policy)

# Context

ADRs 0018 and 0019 made the kit's mechanics tolerant of existing arrangements: the installer detects the layout, the helper follows local naming and status conventions, and `check-stale` governs mapped repos. What remains manual is the thorough first-time pass the owner actually wants on an existing repo: find every piece of knowledge wherever it lives, connect it to the source it governs, write governing docs for the modules that have none, and hand back a repo the goal loop can iterate on. The owner asked whether that pass should be a kit feature that "just goes through them thoroughly, irrespective" of structure.

The middle of that pipeline is content work, not mechanics. Deciding whether a stray notes file is really a spec, rewriting a decision record without changing its meaning, and authoring new specs for undocumented modules all require judgment — exactly what the kit's division of labor assigns to the model, not to Bash. The installer must stay a deterministic mechanic (ADR 0005); the kit is Bash-only by constraint; and a scripted converter would emit the least reviewable artifact possible, a whole-corpus rewrite in one diff. Meanwhile the kit already ships judgment-shaped procedures as installed skills (ADR 0015) and already has the mechanical substrate this pass needs: layout detection, tolerant readers, `okf draft` for fact-based backfill, the map, and layout-aware validation.

# Decision

Ship the adoption pass as a fifth installed workflow skill, `okf-adopt`, loaded on demand like the other four, with a binding one-liner in the installed playbook. The skill runs after `update-existing-repo` (which stays purely mechanical and unchanged) and walks Claude through:

1. **Inventory** — sweep the whole repo for knowledge, not just the detected homes: spec- and ADR-shaped Markdown in any directory, machine-readable contracts (`schemas/`), runbooks, design notes. Report the inventory to the owner; move nothing.
2. **Arrangement decision** — adapt-in-place is the default: keep the repo's own layout, naming, index format, and validators, relying on the ADR 0018/0019 tolerance. Migration to the canonical tree happens only at explicit owner direction, and then the skill also repairs what the rename breaks — cross-links, IDs, CI validators, badges — which is precisely why migration is skill work, not script work.
3. **Map** — populate `docs/okf-map.yml` mappings from the inventory, using existing metadata (frontmatter component lists, module boundaries) so `check-stale` becomes the authority and the crude stop-gate retires.
4. **Backfill** — for implementation areas with no governing doc, run `bash scripts/okf draft <paths>`, rewrite the drafts into commitments, promote them into the spec home following its local conventions (including manual index entries where the helper declines a table), and map each promoted spec. Conform new files' frontmatter to the target repo's own validator when it has one.
5. **Validate** — `verify-install`, `bash scripts/okf check-stale`, `bash scripts/okf pending`, the repo's own docs and test gates, and the `kit_version` stamp; record the pass in a dated `docs/log.md` entry, including any helper misfires for harvest.

The goal interview remains a separate skill and follows when `docs/GOAL.md` is still a template.

# Alternatives considered

- A scripted converter in the installer ("scan, restructure, rewrite, validate"): rejected — the restructuring and rewriting steps are judgment, a Bash script cannot author or faithfully rewrite specs, and the output is an unreviewable whole-corpus diff. The installer stays deterministic mechanics.
- Migration to canonical as the default with adapt-in-place as the option: rejected — ADRs 0018 and 0019 already established that forced renaming breaks cross-links, IDs, and reading order for zero benefit, and real repos encode their conventions in their own CI; adapting is the default precisely because it is the reversible, low-risk path.
- A standalone prompt document instead of an installed skill: rejected — ADR 0015 already chose skills for episodic procedures; a skill loads on demand, travels with the install, and is refreshed by the updater's provenance machinery like the other four.
- Doing nothing (leave adoption as ad-hoc agent work): rejected — the pass has a stable, repeatable shape across dogfood targets, and an unscripted version re-derives it (and its ordering mistakes) in every adopting repo.

# Consequences

- A fifth skill travels with every install: the manifest grows to eight seeded entries, and the installers, verifier, harvest list, README, packaging and installer specs, playbook template, and smoke assertions all carry `okf-adopt`.
- The mechanical substrate stays verified by `make test`; the quality of inventory, mapping, and backfill decisions rests on the model and the owner's review, exactly like spec and ADR authorship today — the skill sequences the judgment, it does not fake determinism.
- Adopting repos get a defined, repeatable onboarding: updater → adoption pass → goal interview → loop.
- Installed behavior changes; this folds into the unpublished 0.3.0 (ADR 0010), and the site's adoption section mentions the guided pass (ADR 0016).

# Rollback / revisit trigger

Revert by removing `templates/skills/okf-adopt/`, its installer/verifier/harvest/manifest entries, the playbook one-liner, and the doc mentions; no other mechanism depends on it. Revisit when a second dogfood adoption shows the pass needs mechanical support the helper lacks (an inventory subcommand, a map-population helper), when owner-directed migration proves common enough to deserve its own tooling, or when the skill's steps drift from what real adoptions actually do.
