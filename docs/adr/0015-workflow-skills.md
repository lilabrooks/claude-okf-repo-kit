---
type: ADR
title: Workflow procedures as installed skills
description: Deliver the four episodic workflow procedures as installed Claude Code skills that load on demand, with binding one-liners staying resident in the installed CLAUDE.md.
tags: [adr, skills, context, template]
timestamp: 2026-07-12T01:36:05Z
status: accepted
---

# Status

Accepted (2026-07-12, at the owner's direction; implementation was already in place per the propose-then-implement policy)

# Context

The installed `CLAUDE.md` loads into context at every session start, so every resident line is a per-session token cost in every installed repo. Most of the template is binding rules that must always be present, but four sections are episodic procedures that fire rarely: the goal interview (once per repo), the acceptance pass (once per goal), ADR review mechanics (when the owner reviews), and the kit-upgrade walkthrough (when a drift note appears). Carrying their full expansions resident means paying for them in the hundreds of sessions where they never fire.

This was parked on 2026-07-09 pending skywatch's first loop: if the interview and acceptance pass executed cleanly from resident prose, skills would be a context optimization rather than a correctness fix. They did — and the owner has now asked for the optimization, alongside a second constraint the resident form can't serve: procedures delivered as prose can't grow richer without growing every session's context, while skills can carry checklists and worked examples at zero resident cost.

# Decision

Ship four namespaced Claude Code skills as install artifacts, sourced from `templates/skills/` and installed to `.claude/skills/okf-*/SKILL.md`:

- `okf-goal-interview` — the full interview script with worked examples, per-kind phrasing, and the tool-availability check.
- `okf-acceptance-pass` — the first-time-user checklist, wrong-input catalog, and findings handling.
- `okf-adr-review` — accept/reject/request-changes mechanics, including marker cleanup and the propose-then-implement note.
- `okf-kit-upgrade` — the drift-note walkthrough: updater behavior, candidate review, mirror re-sync, post-update verification.

`templates/CLAUDE.md` goes on a diet: each of the four sections compresses to a binding one-liner (or compact list) that names its skill and stands alone. The design rule is load-bearing: **guardrails and anything the loop depends on never move into skills** — skills trigger probabilistically, so a missed skill must degrade to the resident one-liner, never to nothing. The resident interview question list, the acceptance-pass obligation, the review semantics (accept binds, reject reverts), and the updater recommendation all stay in the template; only their expansions moved.

The skills are kit-managed installed files: both installers copy them, `create-new-repo` seeds their digests into the provenance manifest (seven entries total), the updater refreshes them in place only when provably unedited kit output (ADR 0013), `verify-install` requires them, and the harvest helper classifies their drift.

# Alternatives considered

- Keep everything resident (the status quo blessed by ADR 0008's framing): rejected by the owner's token-economy direction — the per-session cost is paid in every installed repo forever, and it caps how rich the procedures can get.
- Move guardrails and loop semantics into skills too: rejected — skill triggering is probabilistic, and a guardrail that sometimes doesn't load is not a guardrail.
- An instructed "read docs/procedures.md when interviewing" file instead of skills: rejected — it relies on model discipline with no trigger mechanism, exactly the failure mode ADR 0008 removed for the goal file by switching to imports.
- Domain-expertise skill packs (per outside config-repo examples): rejected when this was first parked — out of scope for a domain-agnostic workflow kit; these four skills carry the kit's own workflow only.

# Consequences

- Every session in every installed repo carries a smaller resident template, and the four procedures got substantially richer than the template ever held (wrong-input catalogs, rejection mechanics, mirror re-sync steps) at no resident cost.
- Relationship to ADR 0008: extends its principle (small resident context, detail on disk until needed) from knowledge files to procedures; the import list and its closed-list rule are unchanged. No supersession.
- Four more kit-managed files ride the ADR 0012/0013 provenance machinery; installers, `verify-install`, the harvest helper, the packaging/installer/validation specs, README, guide, and site must stay in sync.
- Installed behavior changes, so `VERSION` bumps and stamped repos get a drift note (ADR 0010).
- Repos that edit a skill locally get the standard preserve-plus-candidate treatment on update, like any kit-managed file.

# Rollback / revisit trigger

Revert by merging the skill bodies back into `templates/CLAUDE.md` sections and dropping the skill files from the installers and manifest seed — the resident one-liners are compressions of the same content, so no information is lost. Revisit if a dogfooded loop shows a skill failing to trigger at its moment (interview or acceptance pass starting from the one-liner when the expansion existed): that degrades quality, and the failing skill's content moves back resident.
