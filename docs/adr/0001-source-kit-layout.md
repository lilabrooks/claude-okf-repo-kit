---
type: ADR
title: Source kit layout
description: Keep source-kit files reviewable at repo paths while documenting target install destinations.
tags: [packaging, layout]
timestamp: 2026-07-05T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
status: accepted
---

# Status

Accepted

# Context

The kit has two audiences:

- people reviewing or publishing this source repo
- people installing the kit into a target repo

The installed target layout needs `.claude/hooks/`, `.claude/settings.json`, `scripts/okf`, and `docs/okf-map.yml`.

The source repo needs a layout that is easy to read and validate before copying files elsewhere.

# Decision

Keep install artifacts in the source repo at:

- `templates/CLAUDE.md`
- `settings.json`
- `okf-map.yml`
- `scripts/okf`
- `scripts/check-docs-sync.sh`
- `scripts/check-okf-version.sh`

Document their target destinations in `README.md` and the guide.

Keep this repo's own project instructions at root `CLAUDE.md` and its own knowledge bundle under `docs/`.

# Consequences

The source repo is not a literal installed target repo. It is a kit that explains where each file goes.

Validation must test both the source layout and the installed target layout.

The root `okf-map.yml` remains an install template. This repo's own mappings live in `docs/okf-map.yml`.
