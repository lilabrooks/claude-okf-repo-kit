# Log

## 2026-07-07

- Added `templates/GOAL.md`, installed to target `docs/GOAL.md`: a goal template with repo kind (app, service, or utility), problem, target state, verifiable success criteria, non-goals, constraints, and an ordered milestone backlog (ADR 0006).
- Added a Goal iteration section to `templates/CLAUDE.md`: Claude Code reads `docs/GOAL.md` each session, takes the first unchecked milestone when asked to continue, checks it off only when its verification passes, and logs progress.
- Both installers now install `docs/GOAL.md`; the existing-repo installer preserves an existing file and writes a numbered candidate such as `docs/GOAL.2.md`.
- The existing-repo installer now skips writing a numbered candidate when the existing file already matches the kit content, keeping repeated updates idempotent for kit-created files.
- `verify-install` checks `docs/GOAL.md` exists; `check-placeholders` reports its unfilled template placeholders.
- Updated README, guide, packaging and installer specs, source map, and Makefile smoke tests to cover the goal file.
- Fixed `make scan` false pass: when ripgrep was not installed, the missing command looked like "no matches" and the scan reported success without running. The scan now falls back to `grep -rnEI` and fails on scanner errors instead of reporting success.
- QA pass: starter `docs/index.md` written by installers and README manual steps now links `GOAL.md` so the bundle root index is current on install; ADR 0006 and the installer spec now state that the identical-content candidate skip applies to all installer candidate writes; README and guide mention the skip.
- Ignore-policy audit: root `CLAUDE.md` ignore policy now includes the Python bytecode/cache entries that `.gitignore` and the packaging spec already had; `templates/CLAUDE.md` bootstrap now requires all 3 target ignore entries (adding `.okf-kit-backups/`) so bootstrapped repos pass `verify-install`. No `.gitignore` content changed; both files matched the intended policy.
- Added `.github/dependabot.yml` (weekly GitHub Actions version updates), the repo's only dependency surface. Considered and rejected Snyk: the kit has no dependency manifests, containers, or IaC, and Snyk Code does not analyze Bash; ShellCheck plus the Makefile smoke tests remain the security-relevant checks.
- Enabled this repo's GitHub-side security toggles (not reproducible from a clone): Dependabot alerts (`gh api -X PUT repos/OWNER/REPO/vulnerability-alerts`) and Dependabot security updates (`gh api -X PUT repos/OWNER/REPO/automated-security-fixes`); secret scanning and push protection were already on. Recorded them in a new README "Repository settings" section since server-side settings leave no tracked-file trace. These apply to this source repo only and are not installed into target repos.

## 2026-07-05

- Replaced setup examples with clone-and-`KIT="$(pwd)"` commands so docs do not depend on a local checkout path.
- Added a static README OKF validated badge that links to the kit validation section.
- Added a README Project Status section and linked the preview badge to it.
- Clarified that source-kit OKF validation covers helper behavior and stale mappings, while target repos own stricter OKF document-schema checks when needed.
- Made all README badges clickable.
- Made the README GitHub Actions test badge clickable.
- Removed the README license badge while keeping the MIT license file.
- Added safe install, verification, and placeholder helper scripts with Makefile smoke coverage.
- Clarified README setup paths, target-repo ignore rules, source-repo ignore rules, and OKF version hook behavior.
- Added a README table of contents for faster navigation.
- Changed the README status badge from alpha to preview.
- Added a clearer README opening section that explains what the kit does before installation details.
- Added Python bytecode/cache ignores and changed the syntax check to avoid writing bytecode.
- Added quality checks for optional ShellCheck linting, Markdown links, local-path scanning, installer idempotency, and GitHub Actions validation.
- Added an MIT license and README badges for the new `lilabrooks/claude-okf-repo-kit` GitHub repo.
- Updated README, guide, specs, and ADR index so the documented installer contract matches the safe script behavior.
- Strengthened installer behavior so `.gitignore` is appended, existing Markdown/map files are preserved, same-folder numbered candidates are created for name collisions, and script results print clearly.
- Updated ignore policy to include local env files and logs while keeping `.env.example` trackable.
- Split source repo instructions from the installable `CLAUDE.md` template. Root `CLAUDE.md` now governs this repo; `templates/CLAUDE.md` is copied into target repos.
- Added validation coverage proving installers copy `templates/CLAUDE.md`, not root `CLAUDE.md`.
- Clarified that installer scripts are the preferred pre-session setup path, while `CLAUDE.md` docs bootstrap remains the in-session fallback.
- Added safe installer scripts for creating new target repos and updating existing repos.
- Clarified source-kit verification and installed target repo verification in the README and guide.
- Added the initial OKF knowledge bundle for this repo: specs, ADRs, indexes, log, and source-to-doc mappings.
- Standardized on ADR naming. The user's "ARD" request maps to Architecture Decision Records, matching the repo guide.
