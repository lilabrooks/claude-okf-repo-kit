---
type: ADR
title: Brownfield layout tolerance and adoption
description: Tolerate existing docs arrangements — tolerant status and numbering detection, a minimal layout block in the map, and an adopting updater — instead of forcing the canonical tree.
tags: [adr, brownfield, layout, installer, hooks]
generated: { by: claude-code/opus-4.8, at: 2026-07-13T00:00:00Z }
status: accepted
---

# Status

Accepted (2026-07-13, at the owner's direction; implementation landed with the proposal per the propose-then-implement policy)

# Context

The third dogfood target (the AWS Alerting System repo) is the kit's conceptual model ported by hand with a different physical layout: specs live in `docs/architecture/specification/` as numbered chapters indexed by an architecture README, sixteen ADRs use three-digit `001-*.md` names with `- Status: Accepted` body bullets instead of frontmatter, JSON Schemas under `schemas/` are first-class governing contracts, `AGENTS.md` is the playbook with `CLAUDE.md` as a pure `@`-import shim, and there is no `docs/index.md`, `docs/log.md`, or `docs/specs/`.

Against that repo the kit's mechanics all assume the canonical tree: `new-adr` would fork a parallel `0001-` numbering sequence and create an index listing one of seventeen ADRs; `new-spec` and `draft` hardcode `docs/specs/`; `pending` and the SessionStart inbox are blind to body-status conventions (a body-status proposed ADR silently escapes review); the version hook nags "okf_version (none)" every online session because there is no bundle root; the updater would plant empty parallel indexes beside the real knowledge and stage a `CLAUDE.2.md` candidate when the real merge target is `AGENTS.md`; `verify-install` then passes green on the shells; and the Stop hook's `docs/`-prefix gate misclassifies mapped machine-readable contracts as undocumented code. Meanwhile the mapping engine itself (`check-stale` plus `okf-map.yml`) already handles the layout — validated live with a prototype map. Nearly every real adoption candidate is a brownfield repo with some existing arrangement, so this is the kit's growth path, not an edge case.

# Decision

Make the kit layout-tolerant in three bounded moves, keeping the canonical tree as the unchanged default:

1. **Convention tolerance with no new configuration.** ADR status detection reads frontmatter `status:` first, then a `- Status: X` bullet, then a `# Status`/`## Status` section, normalized to the lowercased first word — in `okf pending`, the SessionStart inbox, and the harvest index (frontmatter stays the preferred form for new files). `new-adr` follows whatever numbering already exists (highest number plus one, widest existing zero-pad width; four digits only in an empty directory). Indexes are never created empty beside existing knowledge: `scripts/okf` and the updater seed a new index with an entry per knowledge file already in the directory. The version hook stays silent about `okf_version` when the stamp file is absent or undeclared — the contract `kit_version` always had — and skips the network fetch in that case. `adr-suggest` classifies `schema` as a contract change, not persistence.

2. **A minimal `layout:` block in `docs/okf-map.yml`** with exactly three keys — `specs_dir`, `adr_dir`, `stamp_file` — everything else derived (drafts at `<specs_dir>/_drafts`, indexes at `<dir>/index.md`). Absent block means today's paths, so existing installs see no behavioral change. Read by `scripts/okf`, both hooks (each carries an inline parser copy so a mirrored hook stands alone), `verify-install`, and `harvest-dogfood`. The map is the home because it already travels with the repo and every tool already locates it.

3. **Brownfield adoption in `update-existing-repo`.** Detection order: a layout block in the target's existing map, then filesystem probes over bounded candidate lists, then defaults. On a non-canonical detection the installed (or candidate) map records the layout block. Missing indexes are created seeded; existing heading-only starters (`docs/log.md`, the indexes) are left untouched with no numbered candidate; the `docs/GOAL.md` template candidate is suppressed when the existing goal already has the kit's structure and no template brackets; when `AGENTS.md` exists and `CLAUDE.md` is absent or an import shim, the kit playbook stages as an `AGENTS.md` numbered candidate with its preloaded-import lines rewritten to the detected layout, and a missing `CLAUDE.md` is created as an import shim; the starter `docs/index.md` links the layout homes plus `docs/runbooks/` and root `schemas/` when present.

One deliberate gate change rides along: the Stop hook's `docs/`-prefix gate applies only while the map carries no active mapping (or `scripts/okf` is missing). Once mappings exist, `check-stale` is the authority, so mapped governing docs may live outside `docs/` — machine-readable contract schemas — and count as documentation.

# Alternatives considered

- Force brownfield repos to migrate to the canonical tree: rejected — renumbering ADRs and moving spec chapters breaks their cross-links and read order for zero benefit, and makes the kit an adoption-time bulldozer.
- Adopt the AWS repo's arrangement as the kit default: rejected — numbered spec chapters suit a design-first single system read linearly; the kit's loop is per-module and map-driven, and a default swap would migrate every existing install, the templates, and this repo itself.
- A separate config file (such as `.okf.yml`): rejected — the map already travels with the repo and is already discovered by every tool; a second file is more surface with no new capability.
- A real YAML parser dependency: rejected — the kit is Bash-only by constraint; three flat keys need only the small awk block parser.
- Configurable everything (log path, index filenames, numbering scheme, multiple ADR dirs): rejected — knob growth turns a reviewable kit into a framework. Three keys cover the observed variance; extend only on evidence.

# Consequences

- Canonical installs (repo-pulse, skywatch) behave identically: absent layout block, absent brownfield markers, same outputs — the existing canonical smoke tests prove it.
- In mapped repos, unmapped source changes no longer hard-block at stop; they surface through `check-stale`'s non-blocking unmapped note. That is a deliberate loosening: the map, once real, is the contract. Map-less repos keep the crude gate.
- The layout parser is intentionally duplicated (helper, SessionStart hook, `verify-install`, updater, harvest) so hooks stand alone when mirrored into another agent's config; the copies must stay in sync, and the helper spec names them.
- Installed behavior changes, so `VERSION` bumps to 0.2.0 (ADR 0010), stamped repos get a drift note, and the site review applies (ADR 0016).
- The helper, hooks, installer, packaging, validation, and dogfood-harvest specs carry the new contracts; skills and template wording point at layout-aware defaults.

Amendment (2026-07-24, kit 0.3.12): decision point 2's reader list — "Read by `scripts/okf`, both hooks …, `verify-install`, and `harvest-dogfood`" — was wrong in both directions, and the correct list was already in this ADR. It omitted `update-existing-repo`, and it claimed both hooks when only the SessionStart hook reads layout. The duplication line above names the accurate set (helper, SessionStart hook, `verify-install`, updater, harvest), and the code agrees: layout-parser copies in `scripts/okf`, `check-okf-version.sh`, `verify-install`, `harvest-dogfood`, and `update-existing-repo` — the updater additionally carrying eleven stamp-file references, the heaviest use of the block anywhere — while `check-docs-sync.sh` reads no layout at all. Point 2 is the outlier; read the duplication line as authoritative. The omission was not harmless: the sentence a reviewer consults to ask "must the installer follow the declared layout?" answered no, and the installer stamped a hardcoded `docs/index.md` for eight days and ten commits before the 0.3.9 audit caught it — a drift `check-stale` could not see either, because this ADR was mapped to nothing. `docs/okf-map.yml` now maps it to those five scripts and deliberately not to the docs-sync hook. The decision itself is unchanged: three keys, declared rather than detected, an absent block meaning today's paths — and point 3 always bound the updater for brownfield detection, so the installer was never outside this ADR's scope, only outside one sentence's description of it.

# Rollback / revisit trigger

Revert by removing the layout parsers and detection blocks and restoring the fixed canonical paths; the tolerance items (status forms, numbering detection, seeded indexes, stamp silence) are independent and can stay. Revisit when a second brownfield dogfood needs keys beyond the three (a relocated log, multiple ADR homes) or when detection misfires on a real repo — then extend the key set deliberately or make the updater ask instead of probe.
