# Log

## 2026-07-05

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
