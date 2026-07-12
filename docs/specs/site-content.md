---
type: Spec
title: Site content and style
description: What the kit's website in site/ must say and how it must read, so updates stay accurate and keep the editorial voice.
tags: [website, content, style]
timestamp: 2026-07-12T00:00:00Z
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Purpose

The website in `site/` is the kit's public explanation. This spec governs its content and voice so that, as the kit changes, the site can be updated without drifting in accuracy or tone. It complements the packaging spec (which covers where `site/` lives and how it deploys) and ADR 0016 (the apex mirror and the relative-path constraint).

# Scope and ownership

The website is entirely the source-repo maintainer's concern. It is not part of the installed kit contract, and these boundaries are deliberate:

- **Source-only; never installed.** Installers copy an explicit allowlist (templates, `settings.json`, hooks, `scripts/okf`, the starter map); they never copy `site/`, `.github/workflows/pages.yml`, `VERSION`, the `Makefile`, this spec, or ADR 0009/0016. Repos that install the kit receive no site machinery and manage their own websites however they wish. The `smoke-install` and `smoke-existing` validation tests assert these artifacts are absent from a freshly installed target, so a future installer regression that leaked them fails the suite.
- **Owner-curated dogfood set.** The dogfood page lists only repositories the owner explicitly selects, and it is hand-authored. It is never generated from the machine-local harvest registry (ADR 0014) or any other automated source; the harvest helper reports deltas to the maintainer but never writes to `site/`.
- **Owner-approved updates only.** No automation changes the site or moves the apex. Every site edit is a maintainer commit, and the apex advances only when the owner bumps the submodule — ADR 0016 chose a manual bump over cross-repo auto-sync for exactly this reason. The `VERSION`-bump review and the `check-stale` map entries are prompts; the owner decides which kit changes warrant a site change.

# Pages and structure

- **`index.html`** — the explainer, in this order: hero → the baseline (why the repo can't remember a goal on its own: `/goal` is session-scoped, auto memory is unversioned) → what the kit adds (the operating contract) → what the kit installs (the concrete files) → what is verified (mechanical vs. judgment) → adopting the kit (new vs. existing repo) → where the approach helps → evidence (link to the dogfood record and the source repo).
- **`how-it-works/index.html`** — the detailed installed-behavior walkthrough: session start (context without re-reading), the goal interview, the iteration loop, how decisions get made, the standing guardrails with the enforcement caveat, interrupted-session resume, and an "anatomy of a conversation" set of request/response scenarios. This is the depth behind the home page's overview; keep the two consistent.
- **`dogfood/index.html`** — one section per dogfood repository: what it tested, what it found, and the change carried back into the kit.
- **Redirect stubs** (`now/`, `notes/`, `projects/**`) and **`404.html`** — short, styled with the same CSS, kept only for URL continuity.

# Voice

- Plain, precise, and calm. No marketing hype, no exclamation, no superlatives. Explain the mechanism, not a pitch.
- Prefer concrete nouns from the repo (goal, milestone, spec, ADR, source map, hook, acceptance pass) over abstractions.
- Sentence-level honesty over enthusiasm: when something is an instruction rather than an enforced gate, say so.

# Honesty framing (do not soften)

- Keep the **verified-vs-judgment** distinction the site already draws: the mechanics are real; the content of a spec or decision still needs human review.
- Keep the status labels on the "what is verified" list — `Yes`, `Qualified`, `Mechanical` — and use them accurately.
- Keep the **enforcement boundary** caveat: the only hard gates the kit installs are the docs-sync hooks and the `.env` read-denial; tests, wider security, and destructive-action rules are instruction-level unless the target repo adds CI or branch protection.
- Keep the **"evidence is still early"** note: the tests validate mechanisms and the dogfood repos give concrete findings, but no measured improvement in delivery time or defects is claimed.

# Accuracy rule

Every factual claim about kit behavior must be traceable to a kit ADR, a spec, or a dated `docs/log.md` entry. When kit behavior changes, the corresponding site copy changes with it (see "Keeping the site current"). Do not describe behavior the installed templates do not implement.

# Style constraints

- **Reuse the existing CSS** in `site/styles.css` and its component classes (`section`, `section-head`, `principle-grid`/`principle`, `route-grid`/`route-card`/`steps-list`, `working-set-list`, `path-grid`/`path-card`, `limit-note`, `claim-status`, `text-link`, `button`). Do not add new CSS for new content; compose from what exists.
- **Relative paths only** (ADR 0016): assets, navigation, and redirect targets are relative so the same files render at both the apex and the project base; stylesheet `url()` font references are relative. Absolute `canonical`, Open Graph, and schema.org URLs point at the apex.
- Self-hosted IBM Plex Mono (display) and IBM Plex Sans (body), under the SIL Open Font License; keep `fonts/LICENSE.txt`.
- Keep the author metadata and visible footer naming Lila Brooks; the home page carries `SoftwareSourceCode` schema, the dogfood page `TechArticle`. When the dogfood page changes, update its `dateModified` and `article:modified_time`.

# Keeping the site current

- A `VERSION` bump means installed behavior changed, which is exactly when the site can go stale. Treat "re-read every site claim against the change and update `site/`" as a required step of any release that bumps `VERSION` (packaging spec).
- `docs/okf-map.yml` maps `site/index.html` alongside the behavior-defining templates (`templates/CLAUDE.md`, `templates/skills/**`) so `check-stale` surfaces the site when those change. This is a reminder, not a hard gate — `check-stale` is satisfied by any one mapped-doc change or a `docs/log.md` note — so the release step above is the real assurance.
- Publishing is two steps: edit `site/` here (the project-base Pages redeploys), then bump the apex submodule in the `lilabrooks.github.io` repo (ADR 0016).
