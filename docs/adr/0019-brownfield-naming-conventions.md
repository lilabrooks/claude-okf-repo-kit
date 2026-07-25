---
type: ADR
title: Brownfield naming-convention tolerance
description: Follow alpha-prefixed ADR/spec numbering (adr-0001-, spec-000-), decline to append bullets into table-style indexes, and stamp kit_version into an existing bundle root instead of staging a replacement candidate.
tags: [adr, brownfield, naming, installer, helper]
generated: { by: claude-code/fable-5, at: 2026-07-14T00:17:11Z }
status: accepted
---

# Status

Accepted (2026-07-14, at the owner's direction; implementation landed with the proposal per the propose-then-implement policy)

# Context

The fourth dogfood target (the spec-agent-cli repo) is the inverse brownfield of ADR 0018's AWS case: the directories are canonical (`docs/specs/`, `docs/adr/`, a stamped `docs/index.md` declaring `okf_version`), but the file conventions are not. ADRs are named `adr-0001-*.md` and specs `spec-000-*.md`, both indexes are Markdown tables rather than bullet lists, and the repo runs its own frontmatter validator in CI.

Against that repo three kit mechanics misfire. `new-adr`'s numbering scan globs `[0-9]*-*.md`, so alpha-prefixed names are invisible and the helper would fork a parallel `0001-*.md` sequence — the exact failure ADR 0018 fixed for bare-numeric names, one step less tolerant than the repos that actually exist. `new-spec` has no naming detection at all and would drop a plain `slug.md` beside ten `spec-NNN-*` files. And `index_append` appends a bullet after the last line, which under a table index produces a malformed stray entry. Separately, the updater stages a full `docs/index.2.md` bundle-root candidate against a repo whose bundle root already exists and already declares `okf_version` — a whole-file review candidate whose only real payload is the missing `kit_version` stamp. ADR 0018's revisit trigger named this moment: extend deliberately when detection misfires on a real repo.

# Decision

Extend convention tolerance in four bounded moves, all detection-side — no new `layout:` keys, no configuration:

1. **`new-adr` follows an alpha-prefixed numbering convention.** The numbering scan reads every non-index, non-candidate `*.md` in the ADR home and classifies names as bare-numeric (`0001-*`, `001-*`) or alpha-prefixed (`adr-0001-*`: a purely alphabetic word, a hyphen, digits, a hyphen). Bare-numeric files keep absolute precedence — any bare-numeric ADR means today's behavior, unchanged. Only when there are no bare-numeric ADRs and every alpha-prefixed ADR shares one prefix word does the helper adopt it: next file `<prefix>-<next>-<slug>.md`, number and zero-pad width detected exactly as ADR 0018 specified. Mixed prefixes or an empty directory fall back to the four-digit default.

2. **`new-spec` follows the same alpha-prefixed convention — and only that.** Bare-numeric spec names (`01-overview.md`) signal a curated chapter order where position is editorial, so they are deliberately not followed; the helper keeps writing plain `<slug>.md` beside them (the AWS-shape behavior, unchanged). A single shared alpha prefix (`spec-000-*`) signals an append-only ID sequence, so the helper continues it: `spec-009-<slug>.md`.

3. **`index_append` declines tables instead of guessing.** When the index contains any table row (a line starting with `|`), nothing is appended; the command reports the entry for the author to add in the index's own format and still scaffolds the file. The last line alone is no signal — the observed real indexes keep prose after their tables. Generating table rows would mean guessing column layouts — declining is the right amount of tolerance.

4. **The updater stamps `kit_version` in place.** When the target's `docs/index.md` exists, opens with a frontmatter block, and declares `okf_version`, the updater inserts (or corrects) the `kit_version` line in that frontmatter directly — after a backup — instead of staging a bundle-root replacement candidate. The precedent is `append_gitignore_entry`: mechanical one-line additions to owner files are made directly. A bundle root without frontmatter or without `okf_version` keeps today's candidate behavior.

# Alternatives considered

- New `layout:` keys for naming (`adr_prefix`, `spec_prefix`, index format): rejected — ADR 0018 already ruled that knob growth turns a reviewable kit into a framework; both observed conventions are detectable from the files themselves.
- Renaming the target repo's files to the canonical `NNNN-*` form at adoption: rejected by ADR 0018 as the adoption-time bulldozer — it breaks existing cross-links and IDs for zero benefit.
- Following bare-numeric spec chapters in `new-spec`: rejected — chapter numbers encode a curated reading order the helper cannot judge; appending `18-<slug>.md` to a spec book is a content decision, not a scaffold.
- Appending table rows to table-style indexes: rejected — column layouts vary per repo; a wrong guess corrupts a governed index, while declining costs one manual line.
- Adapting scaffold frontmatter to repos with their own validators (e.g. required `owner`/`deciders` keys), via repo-local template overrides: deferred — one observed repo is below the evidence bar; noted as a revisit trigger.

# Consequences

- Canonical installs and the AWS-shape brownfield behave identically: bare-numeric ADR numbering takes precedence, bare-numeric spec chapters still get plain-slug specs, bullet-list indexes still get appends, and heading-only bundle roots without `okf_version` still get the full candidate. The existing smoke targets prove it and gain cases for the new shapes.
- Repos with `adr-NNNN-`/`spec-NNN-` names get continued sequences instead of forks; their table indexes are never corrupted, at the cost of one manual index line per scaffold.
- Stamped-but-unversioned bundle roots gain drift detection immediately after one updater run, with no whole-file candidate to reconcile.
- The numbering scan now reads the whole ADR home rather than a numeric glob; index and `*.N.md` review candidates are excluded, matching `pending`'s exclusion rule.
- Installed behavior changes, so `VERSION` bumps to 0.3.0 (ADR 0010) and stamped repos get a drift note.
- The helper and installer specs carry the new contracts.

# Rollback / revisit trigger

Revert by restoring the numeric-glob scan in `new-adr`, the fixed `<slug>.md` name in `new-spec`, the unconditional append in `index_append`, and the unconditional bundle-root candidate in the updater; the four moves are independent and can be reverted separately. Revisit when a repo needs prefix forms beyond `<word>-<digits>-` (dates, multi-word prefixes), when a second repo's own frontmatter validator rejects kit scaffolds (then weigh repo-local scaffold templates), or when declining table indexes proves too manual in practice.
