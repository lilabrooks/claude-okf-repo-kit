# ADRs

- [0001 Source kit layout](0001-source-kit-layout.md): Keep install artifacts reviewable in this source repo while copying them to Claude Code paths in target repos.
- [0002 Repo-local Bash helper](0002-repo-local-bash-helper.md): Implement OKF helper commands as a repo-local Bash script.
- [0003 Claude hook guardrails](0003-claude-hook-guardrails.md): Use Claude Code hooks to block missing or stale docs updates.
- [0004 Source-kit validation Makefile](0004-source-kit-validation-makefile.md): Validate the kit with local Make targets and temp-repo smoke tests.
- [0005 Safe installer scripts](0005-safe-installer-scripts.md): Provide safe installer, verification, and placeholder scripts for target repos.
- [0006 Goal file template](0006-goal-file-template.md): Capture the target repo's goal and milestone backlog in an installed `docs/GOAL.md`.
- [0007 Autonomous iteration guardrails](0007-autonomous-iteration-guardrails.md): Run the installed goal loop unattended with proposed ADRs and test/security/destructive-action guardrails.
- [0008 Context preloading via CLAUDE.md imports](0008-context-preloading-imports.md): Preload the goal file and spec/ADR indexes each session with `@` imports instead of instructed reads.
- [0009 GitHub Pages website from main via Actions](0009-github-pages-website.md): Publish the kit's website from `site/` on main with the Actions Pages deployment.
- [0010 Kit version stamp and drift reporting](0010-kit-version-stamp.md): Stamp installed repos with the kit release that produced them and report drift at session start.
- [0011 Env-file read denial in shipped settings](0011-env-read-denial.md): Ship `permissions.deny` Read rules for local env files, making the secrets guardrail mechanical.
- [0012 Stale-candidate refresh via digest manifest](0012-candidate-refresh-manifest.md): Refresh updater-written candidates in place (proven by content digest) instead of numbering past them each kit release.
- [0013 Kit-managed script refresh via manifest provenance](0013-script-provenance-refresh.md): Refresh installed kit scripts in place only when provably unedited kit output; preserve owner-edited scripts with a kit candidate for review.
- [0014 Dogfood harvest via a machine-local registry](0014-dogfood-harvest-registry.md): Track installed dogfood repos with a git-ignored high-water-mark registry and a source-only delta-report helper.
- [0015 Workflow procedures as installed skills](0015-workflow-skills.md): Deliver the episodic workflow procedures as installed `okf-*` skills loading on demand, with binding one-liners resident in the installed `CLAUDE.md`.
- [0016 Apex mirror of the kit site via submodule](0016-apex-mirror-editorial-site.md): Make `site/` the single governed source of an editorial site, mirrored to the owner's apex user-site repo through a git submodule, with relative paths so the same files render at both bases.
- [0017 Adopt Compact Theme for the website](0017-compact-theme-site.md): Rebuild the site on the vendored Compact Theme (`compact-theme.css`/`.js`) for a maintained design system with light/dark modes, replacing the bespoke `styles.css`.
- [0018 Brownfield layout tolerance and adoption](0018-brownfield-layout-tolerance.md): Tolerate existing docs arrangements — tolerant status and numbering detection, a minimal layout block in the map, and an adopting updater — instead of forcing the canonical tree.
