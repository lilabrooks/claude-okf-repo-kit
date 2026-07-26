---
type: ADR
title: Source-only repair tags
description: "Publish urgent source-only repairs with an immutable source-v<installed-version>-r<n> tag while leaving the installed kit version unchanged."
tags: [adr, release, source-only]
generated: { by: process:codex, at: 2026-07-25T23:45:20Z }
status: accepted
---

# Status

Accepted 2026-07-25, at the owner's direction.

# Context

ADR 0010 gives `VERSION` one specific meaning: the release of the artifacts
installed into target repositories. Source-only tools, tests, workflow files,
and governance records do not change those artifacts, so bumping `VERSION` for
them would send every installed repository a false upgrade signal.

Some source-only fixes still need an unambiguous release identity. The urgent
write-containment repair in `scripts/update-existing-repo` is the first case. It
changes a never-installed tool and its source-repo tests, while the installed
`scripts/okf` helper remains unchanged. Calling both states `0.3.14` without
another marker would make incident records and downstream pinning ambiguous.

# Decision

- Keep `VERSION` unchanged when a release changes no installed artifact.
- Identify a published source-only repair with an annotated tag named
  `source-v<installed-version>-r<n>`, where `<installed-version>` is the current
  `VERSION` and `<n>` starts at 1 and increases monotonically for that version.
- The first eligible repair is `source-v0.3.14-r1`.
- A source-only tag supplements `VERSION`; installers never stamp it into a
  target, and the SessionStart version hook does not compare it.
- The tagged commit must be on the protected mainline, pass `make test`, and
  record the repair and its boundary in `docs/log.md`. If the repair addresses
  only part of an umbrella finding, the log must say so and the finding remains
  open.
- Publish a signed annotated tag. Before treating the release as published,
  verify the remote tag object, its signature, and its peeled commit. If signing
  is unavailable, stop and configure it rather than silently substituting a
  lightweight or unsigned tag.

This ADR defines the release mechanism. It does not itself create a tag.

# Alternatives considered

- **Bump `VERSION`.** Rejected because installed repositories would report an
  upgrade even though rerunning the installer would change no installed file.
- **Use only the commit SHA.** A SHA is precise, but it gives operators no
  stable release name and makes the source-only boundary easy to miss.
- **Use a build-metadata semver such as `0.3.14+source.1`.** Rejected because the
  root version is stamped into targets and compared as a plain string. Changing
  it would still create the false drift signal this policy avoids.
- **Use an unsigned or lightweight tag.** Rejected for an urgent safety repair:
  neither supplies the same publisher attestation and release metadata as a
  signed annotated tag.

# Consequences

- Installed-version semantics stay exact.
- Source-only releases have stable names suitable for pinning and incident
  records.
- Publishing requires signing configuration and remote verification.
- A later installed-artifact release bumps `VERSION` normally. Its source-only
  repair counter starts again at `r1` only if that installed version needs one.

# Revisit trigger

Revisit if the project adopts a release system that can carry separate source
and installed-artifact versions without changing the target stamp, or if remote
tag protection and provenance attestations replace signed Git tags.
