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
