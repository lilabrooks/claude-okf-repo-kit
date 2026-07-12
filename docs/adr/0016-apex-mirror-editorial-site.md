---
type: ADR
title: Apex mirror of the kit site via submodule; editorial site as the kit site
description: Make site/ the single governed source of an editorial site, mirrored to the owner's apex user-site repo through a git submodule, with relative paths so the same files render at both bases.
tags: [website, github-pages, submodule, deployment]
timestamp: 2026-07-12T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
status: accepted
---

# Status

Accepted

# Context

ADR 0009 publishes the kit's website from `site/` on `main` to the project Pages URL `https://lilabrooks.github.io/claude-okf-repo-kit/`. Separately, the owner's GitHub user site — the repo literally named `lilabrooks.github.io`, served at the apex `https://lilabrooks.github.io/` — is dedicated to this kit and carries a more polished editorial explainer (why the kit exists, what it installs, adoption paths, the verified-versus-judgment boundary, and the dogfood evidence).

That left two sites for one kit: the plainer in-repo reference at the project base and the editorial site at the apex. They split reader attention and duplicate maintenance, and only the in-repo one was governed by this repo's `check-stale` discipline.

GitHub Pages serves the apex only from the user-site repo; a project repo like this one can never own the apex URL. So "one governed source shown identically at both URLs" cannot be a single deployment — it must be one source mirrored to two Pages targets.

# Decision

- **`site/` is the single canonical source**, and it is the editorial site — a multi-page site whose `index.html` is the explainer and whose `how-it-works/` page carries the detailed installed-behavior walkthrough (session context, goal interview, iteration loop, decision policy, guardrails, interrupted-session resume) re-styled into the editorial system. The README remains the exhaustive file-and-behavior reference the site links to.
- **The apex mirrors it through a git submodule.** The user-site repo `lilabrooks.github.io` includes this repo as a submodule and deploys the submodule's `site/` at the apex. The apex is refreshed by bumping the submodule pointer — a commit in the user-site repo — so no cross-repo token or pipeline is introduced.
- **All paths in `site/` are relative, not root-relative**, and stylesheet `url()` font references are relative, so the identical HTML renders correctly at both the apex (`/`) and the project base (`/claude-okf-repo-kit/`). Absolute `canonical`, Open Graph, and schema.org URLs point at the apex, marking the apex primary and the project-base copy a duplicate.
- **The project-base deployment continues under ADR 0009** — this repo's `.github/workflows/pages.yml` still publishes `site/` at `/claude-okf-repo-kit/`. This ADR extends ADR 0009; it does not replace it.

Alternatives considered:

- Move the site into the user-site repo. Rejected: drops the `check-stale` coupling that keeps the site honest against template changes — the coupling the owner explicitly wants.
- Cross-repo CI (push from here, or pull from there) to mirror automatically. Rejected for now: adds a deploy token and a pipeline; the manual submodule-pointer bump is simpler and was the accepted trade.
- Redirect the project base to the apex, leaving one real page. Rejected: keeps the real site source outside kit governance and bounces one URL to the other.

# Consequences

- One governed source; both URLs show the same editorial site, with the apex canonical.
- Publishing an apex update is two steps: commit and push `site/` here (the project base redeploys automatically per ADR 0009), then bump the submodule pointer in the user-site repo (the apex redeploys).
- Future `site/` edits must keep paths relative — a root-relative path silently breaks the project-base copy while looking fine at the apex. `docs/okf-map.yml` ties `site/**` to this ADR and the packaging spec so `check-stale` flags site edits that skip the knowledge update.
- Self-hosted fonts (`site/fonts/*.woff2`, under the SIL Open Font License) and an external `site/styles.css` now live in the repo. The site stays static with no build step, consistent with ADR 0009's constraints.
- One-time apex setup: the user-site repo's Pages source must be **GitHub Actions**, not deploy-from-branch. A new `*.github.io` repo auto-enables Pages in `legacy` mode, which serves the repo root and cannot reach the `_kit` submodule; switching it once with `gh api -X PUT repos/OWNER/REPO/pages -f build_type=workflow` (or Settings → Pages → Source: GitHub Actions) is required, and it persists thereafter. This is a setup step, not a per-deploy risk, so it is documented rather than enforced in CI.
- No `VERSION` bump: `site/` is source-only and never installed into target repos.
