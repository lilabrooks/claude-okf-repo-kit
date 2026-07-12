---
name: okf-adr-review
description: Accept or reject a proposed ADR at the owner's direction — status flip, reversal per rollback trigger, index and log updates. Use when the owner reviews pending decisions, says to accept/reject an ADR, or asks what's awaiting review.
---

# ADR review mechanics

The owner finds pending decisions with `bash scripts/okf pending` (the SessionStart hook also reports the count). The decision is the owner's; the edits can be yours at their direction.

Accepting an ADR:

1. Flip `status: proposed` to `status: accepted` in the frontmatter, and update the body `# Status` section (date, "at the owner's direction").
2. Remove any "(proposed)" markers the ADR carries in `docs/adr/index.md` entries, `docs/GOAL.md` milestones, or the current-state line of `CLAUDE.md`.
3. No implementation change is usually needed: under the propose-then-implement policy the work already exists — acceptance makes it binding for future work.
4. Add a dated `docs/log.md` entry recording the acceptance, and verify `bash scripts/okf pending` no longer lists it.

Rejecting an ADR:

1. Revert the work built on it, per the ADR's own rollback / revisit trigger section — that section names what reverting takes.
2. Either delete the ADR file and its index entry, or keep it with a `status: rejected` note recording why, per the owner's preference.
3. Run the repo's test command after the reversal; a broken revert is not a completed rejection.
4. Log the rejection and the reversal scope in `docs/log.md`.

Requested changes (neither accept nor reject): treat the owner's comments as a task — amend the ADR and the implementation together, keep `status: proposed`, and flag it again in the summary.

Old ADRs missing a `status:` field are invisible to the pending scan — add frontmatter status to them when found, as a formatting-only fix.
