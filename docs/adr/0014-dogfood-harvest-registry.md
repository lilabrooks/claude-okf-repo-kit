---
type: ADR
title: Dogfood harvest via a machine-local registry
description: Track installed dogfood repos with a git-ignored registry of harvest high-water marks and a source-only helper that reports deltas from fixed probes.
tags: [adr, dogfooding, maintenance]
timestamp: 2026-07-11T22:00:37Z
status: accepted
---

# Status

Accepted (2026-07-11, at the owner's direction; implementation was already in place per the propose-then-implement policy)

# Context

The kit improves by folding back what its installed repos discover, and the first harvest (the analysis that produced kit 0.1.2 and ADR 0013) required manually re-exploring both dogfood repos: git logs, hook diffs against the kit, `docs/log.md` reads, per-repo `okf pending` runs. That cost repeats on every future harvest unless something records how far the last one got.

Two facts make a cheap mechanism possible. The installed docs-sync hook guarantees that no target change lands without a `docs/log.md` trace, so the narrative delta is always in one file. And ADR 0013's manifest makes kit-managed file drift provable rather than something to eyeball.

One constraint shapes the design: a registry of installed repos necessarily holds absolute local paths, and this kit's own `make scan` guard exists precisely to keep local machine paths out of the published repo. A committed registry would fight the kit's own guardrail.

# Decision

Ship a source-only maintainer helper, `scripts/harvest-dogfood`, with a machine-local registry:

- The registry lives at `.okf-kit-backups/dogfood-registry` in the kit clone (override: `OKF_DOGFOOD_REGISTRY`), one line per repo: name, absolute path, last-harvest commit SHA, last-seen `kit_version` stamp. It is git-ignored per-working-copy state, the same class as the ADR 0012/0013 candidate manifest, and is never committed.
- `add` registers a repo at its current HEAD; `mark` records new HEADs after a review; `list` shows the registry; the default `report` prints, per repo: commits and new `docs/log.md` lines since the recorded SHA (highlighting lines that mention the kit or upstreaming), kit-managed script drift classified via the target's manifest (matches kit, unedited older kit output, or owner-edited/unrecorded), the proposed-ADR inbox via the target's own `scripts/okf pending`, the `kit_version` stamp vs the kit `VERSION`, an uncommitted-changes note, and any second-agent config surfaces.
- The helper is read-only against targets: it never writes to, fetches into, or otherwise modifies a registered repo. The only file it writes is its own registry.
- Delta probes depend on the recorded SHA; state probes always run, so a freshly added repo still reports drift, inbox, and provenance immediately.

# Alternatives considered

- A committed registry (for example `docs/dogfood.yml`): rejected — it publishes local machine paths, which the kit's stale-reference scan explicitly guards against, and the paths are meaningless on any other machine anyway.
- Shipping a kit-feedback convention in `templates/CLAUDE.md` (targets tag log entries for upstreaming): rejected — it pushes a kit-maintainer concern into every user's installed repo; the docs-sync contract already guarantees the signal exists, and the harvester's mention-grep catches the organic phrasing dogfood repos already use.
- Relying on assistant session memory: rejected as the mechanism of record — it found things quickly once, but it is per-conversation context, not a repo fact another session or person can execute.
- Full re-exploration each time: the status quo this replaces; it cost a session of tool calls to reconstruct state the registry now keeps.

# Consequences

- A harvest becomes one command and a read of its output; "update the kit accordingly" starts from a delta, not from scratch.
- The registry is per working copy: a fresh kit clone starts empty and repos are re-`add`ed (cheap, one command each). This is the same trade ADR 0013 accepted for the manifest — the failure direction is a slightly fuller first report, never lost data.
- The helper, its spec, the validation smoke test, the packaging spec's source-only list, and the README maintainer note must stay in sync.
- Registered targets must remain untouched by the helper; any future write-back feature (for example auto-marking) still only writes the registry.

# Rollback / revisit trigger

Remove the script, its smoke target, and the registry file; no installed repo is affected because nothing ships to targets. Revisit if the registry needs to be shared across machines or maintainers — that reopens the committed-registry design with paths factored out (names plus per-machine path resolution), which was not worth the complexity for a single-maintainer kit.
