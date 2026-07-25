---
type: ADR
title: Kit version stamp and drift reporting
description: Stamp installed repos with the kit release that produced them and report drift at session start, so template improvements reach existing installs.
tags: [versioning, upgrade, hooks, installer]
generated: { by: claude-code/fable-5, at: 2026-07-09T00:00:00Z }
owner: Lila Brooks
deciders: [Lila Brooks]
status: accepted
---

# Status

Accepted

# Context

Installed repos are snapshots. The repo-pulse dogfood run was installed the same morning the kit gained its post-goal proposal protocol, and its `CLAUDE.md` lacked that behavior within hours — with no signal in the installed repo that the kit had moved on. `scripts/update-existing-repo` already updates safely (backups, merged settings, numbered candidates), but nothing tells an installed repo that running it would yield anything. The SessionStart hook checks the OKF spec version, not the kit's own.

Without a version signal, every lesson the kit absorbs reaches only future installs; existing repos drift silently.

# Decision

- The source kit publishes its release version in a root `VERSION` file (semver, one line) on `main`. `VERSION` is source-only: installers never copy it into target repos.
- Both installers stamp the version they installed as `kit_version` in the target's `docs/index.md` frontmatter, read from `VERSION` at install time. The existing-repo installer stamps it in the `docs/index.md` it creates, and carries it in the numbered candidate when a `docs/index.md` already exists — merging the candidate (or adding the field by hand) is what opts a pre-existing bundle in.
- The SessionStart hook `check-okf-version.sh` also compares the stamped `kit_version` against the published `VERSION` on the kit's main branch and injects a context note on drift. The installed `CLAUDE.md` carries a Kit version policy: on drift, tell the owner and recommend re-running `scripts/update-existing-repo` from an up-to-date kit clone. The hook stays silent when the stamp is absent, when offline, or when the published file cannot be parsed.
- `verify-install` warns (not fails) when `docs/index.md` lacks the stamp, so pre-stamp installs and hand-rolled bundles verify with guidance instead of breaking.
- Upgrading remains the safe updater's job and the owner's review: nothing auto-updates, and the hook only reports.

Alternatives considered:

- A separate kit-version hook file. Rejected: one more installed file to copy, merge, and keep in settings; the existing SessionStart hook already parses `docs/index.md` frontmatter and the two checks share their failure mode (silent offline).
- Stamping every installed file with a version comment. Rejected: churns every file on every release, makes numbered-candidate diffs noisy, and the bundle root already exists as the single declared-versions location (`okf_version` set the precedent).
- Auto-updating installed files when drift is detected. Rejected: contradicts ADR 0005's never-overwrite contract and turns a report into a side effect.

# Consequences

Installed repos learn that the kit moved on at session start, and the upgrade path is the already-tested safe updater. Kit releases now carry a maintenance duty: bump `VERSION` when installed behavior changes, or drift reporting under-reports.

Repos installed before this ADR stay silent until one updater run (or a hand-added `kit_version`) opts them in; `verify-install` surfaces this as a warning.

The hook now makes two network calls at session start, both bounded by the existing 5-second timeout and silent on failure.

Revisit trigger: if version drift notes prove noisy (frequent releases with no installed-file changes) or the raw-URL check becomes unreliable, move the published version signal to a release artifact or tag listing and update the hook in a superseding ADR.
