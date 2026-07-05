---
type: ADR
title: Safe installer scripts
description: Provide automation for new and existing repo setup without destructive overwrites.
tags: [installer, safety, bash]
timestamp: 2026-07-05T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Status

Accepted

# Context

Manual installation is easy to get wrong because the source-kit paths differ from target repo paths.

Existing repos may already have `CLAUDE.md`, `.claude/settings.json`, docs, and scripts that should not be overwritten blindly.

# Decision

Add two source-only installer scripts:

- `scripts/create-new-repo`
- `scripts/update-existing-repo`
- `scripts/install-kit`
- `scripts/verify-install`
- `scripts/check-placeholders`

The new-repo installer only runs on an empty target, except for an optional `.git/` directory.

The wrapper script chooses between new-repo and existing-repo installers based on the target directory state. Verification and placeholder scripts provide safe post-install checks without filling project-specific content.

The existing-repo installer uses backups, settings merges, same-folder numbered candidates, and `.gitignore` appends instead of destructive overwrites.

Existing Markdown and `docs/okf-map.yml` files stay in place. When the kit has a same-name file to offer, the installer writes a numbered candidate beside the existing file, such as `CLAUDE.2.md` or `docs/okf-map.2.yml`.

Each installer prints a clear completion summary so users can see what was created, updated, skipped, backed up, or left for review.

Installers copy `templates/CLAUDE.md` into target repos. Root `CLAUDE.md` remains specific to this source kit repo.

# Consequences

Users get a faster setup path than manual copy commands.

The scripts become part of this source kit's tested surface, but they are not copied into target repos.

The update script may leave manual merge work when preserving existing files is safer than guessing.

The printed summary is part of the user-facing contract and must remain covered by smoke tests.
