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

- **`index.html`** — the explainer, in this order: hero (the kit's category and value) → the baseline (why the repo can't remember a goal on its own: `/goal` is session-scoped, auto memory is unversioned) → what the kit adds (the operating contract) → the loop (a flow diagram: goal → Claude-drafted ordered milestones → the per-milestone agent loop, with Claude authoring the specs and writing the ADRs as proposals for the owner to accept, revise, or reject → acceptance pass → goal met; followed by a callout that the record lives in git, not the session's fresh, limited context window, which the kit repopulates by preloading the goal and indexes and reading the rest on demand) → what the kit installs (the concrete files) → what is verified (mechanical vs. judgment, closed by the division-of-labor note — hooks for what must never be skipped, the helper for what must never vary, preloads for what every session must know, judgment for content — and the misfire-harvest sentence linking the dogfood record, then the enforcement boundary) → adopting the kit (new vs. existing repo) → stack templates (the kit stays stack-agnostic and the goal loop builds a stack from empty on its own; a stack template is an optional accelerator, not a requirement — toolchain decisions live in separate template repositories, walking skeletons passing their own gate, layered under the kit via the existing-repo path; names the next template being built and its seed repository) → where the approach helps → evidence (link to the dogfood record and the source repo).
- **`how-it-works/index.html`** — the detailed installed-behavior walkthrough: session start (context without re-reading), the goal interview, the iteration loop, the division of labor (hooks never skipped / helper never varies / preloads always known / judgment for content, closed by the misfires-are-harvested note), how decisions get made, the standing guardrails with the enforcement caveat, interrupted-session resume, and an "anatomy of a conversation" set of request/response scenarios. This is the depth behind the home page's overview; keep the two consistent.
- **`dogfood/index.html`** — one section per dogfood story, in chronological order (a repository may return for a later round as its own numbered section): what it tested, what it found, and the change carried back into the kit. A story whose fix later ran against the live repository may carry a second row — what happened, what the live pass found, and the change carried back — so the outcome of a story is recorded in the story, not a new section.
- **Redirect stubs** (`now/`, `notes/`, `projects/**`) and **`404.html`** — short, styled with the same CSS, kept only for URL continuity.

# Voice

- Plain, precise, and calm. No marketing hype, no exclamation, no superlatives. Explain the mechanism, not a pitch.
- Prefer concrete nouns from the repo (goal, milestone, spec, ADR, source map, hook, acceptance pass) over abstractions.
- Sentence-level honesty over enthusiasm: when something is an instruction rather than an enforced gate, say so.

# Terminology (Claude and Anthropic)

Use Anthropic's own vocabulary so the site describes the real system, not a private metaphor. Keep three layers distinct:

- **Claude** — the model, which does the reasoning and makes the decisions.
- **Claude Code** — Anthropic's **agentic coding tool** (its docs' phrase; the "Claude Code engine"). It runs the **agent loop**: Claude "dynamically directs its own processes and tool usage… using tools based on environmental feedback in a loop," taking "ground truth from the environment at each step (such as tool call results or code execution)." Prefer "agent loop" and "agentic"; avoid "harness" — it is community shorthand Anthropic's public docs don't use.
- **The kit** — configuration on Claude Code's own extension points (**project memory** / `CLAUDE.md`, **skills** that load on demand, **hooks** at lifecycle events like Stop and SessionStart), plus the OKF knowledge. It is not a separate engine or agent — it is a configuration-and-scaffolding kit (with some deterministic utilities inside it: the hooks, the `scripts/okf` CLI, the installers). Frame its value as packaging the goal-driven-development setup you would otherwise assemble by hand, not as a productivity metric (the evidence is still early).

Name where behavior is **agentic** (Claude's dynamic, self-directed tool use — the milestone loop, spec/ADR authoring) versus **deterministic** (the hooks, which run as fixed code paths — Anthropic's "workflow" end of the spectrum). Other terms to use as Anthropic does: **tools**, **context window**, **sessions**, **subagents**, `/goal` (a session-scoped completion condition). Don't call the kit's loop a Claude feature it isn't: "continue" drives Claude Code's agent loop over the backlog; it is not the built-in `/goal` command.

# Honesty framing (do not soften)

- Keep the **verified-vs-judgment** distinction the site already draws: the mechanics are real; the content of a spec or decision still needs human review.
- Keep the status labels on the "what is verified" list — `Yes`, `Qualified`, `Mechanical` — and use them accurately.
- Keep the **enforcement boundary** caveat: the only hard gates the kit installs are the docs-sync hooks and the `.env` read-denial; tests, wider security, and destructive-action rules are instruction-level unless the target repo adds CI or branch protection.
- Keep the **"evidence is still early"** note: the tests validate mechanisms and the dogfood repos give concrete findings, but no measured improvement in delivery time or defects is claimed.

# Accuracy rule

Every factual claim about kit behavior must be traceable to a kit ADR, a spec, or a dated `docs/log.md` entry. When kit behavior changes, the corresponding site copy changes with it (see "Keeping the site current"). Do not describe behavior the installed templates do not implement.

# Style constraints

- **Use Compact Theme** (`site/compact-theme.css` + `compact-theme.js`, ADR 0017) and its classes: `compact-shell`; `compact-header`/`compact-brand`/`compact-brand-mark`/`compact-nav`/`compact-header-actions`; `compact-hero`/`compact-title`/`compact-lede`/`compact-eyebrow`; `compact-section`/`compact-section-head`/`compact-section-title`/`compact-section-copy`; `compact-grid`/`compact-card`/`compact-card-title`; `compact-tag`; `compact-button`(`-primary`)/`compact-actions`; `compact-footer`; `compact-skip-link`; and the `compact-theme-toggle`. Compose new content from these — do not add a stylesheet. Express what the theme lacks with its own primitives: cards with a `compact-tag` for callouts and honesty notes, plain ordered lists for steps, and minimal inline styles where genuinely needed (e.g. a `max-width` on a long list, the diagram figure wrapper).
- **Light and dark**: the theme follows `prefers-color-scheme` on first visit, and a header `compact-theme-toggle` sets `data-theme` and stores it in `localStorage`. Every colour must flow through the theme's `--compact-*` tokens so both modes render — never hard-code a colour.
- **Diagrams** use a self-contained inline SVG themed with the theme tokens: a scoped `<style>` inside the `<svg>` referencing `var(--compact-text)`, `var(--compact-accent)`, `var(--compact-accent-soft)`, `var(--compact-bg)`, `var(--compact-muted)`, and `var(--compact-mono)`, so the diagram adapts to light and dark. Keep it responsive (`viewBox`, `width:100%`, `height:auto`) inside an `overflow-x:auto` wrapper, with `role="img"` and a `<title>`/`<desc>`. The `index.html` "the loop" diagram is the reference example.
- **Relative paths only** (ADR 0016): asset, navigation, and redirect targets are relative so the same files render at both the apex and the project base; `compact-theme.css` and its `./fonts/` references are relative. Absolute `canonical`, Open Graph, and schema.org URLs point at the apex.
- Fonts are IBM Plex Sans (body) and IBM Plex Mono (display), self-hosted under the SIL Open Font License (`fonts/LICENSE.txt`). Retain the theme's BSD-2-Clause terms in `compact-theme-LICENSE.txt` and `compact-theme-COPYRIGHT.txt` and the SPDX headers in the CSS/JS.
- Keep the author metadata and visible footer naming Lila Brooks; the home page carries `SoftwareSourceCode` schema, the dogfood page `TechArticle`. When the dogfood page changes, update its `dateModified` and `article:modified_time`.

# Keeping the site current

- A `VERSION` bump means installed behavior changed, which is exactly when the site can go stale. Treat "re-read every site claim against the change and update `site/`" as a required step of any release that bumps `VERSION` (packaging spec).
- `docs/okf-map.yml` maps `site/index.html` alongside the behavior-defining templates (`templates/CLAUDE.md`, `templates/skills/**`) so `check-stale` surfaces the site when those change. This is a reminder, not a hard gate — `check-stale` is satisfied by any one mapped-doc change or a `docs/log.md` note — so the release step above is the real assurance.
- Publishing is two steps: edit `site/` here (the project-base Pages redeploys), then bump the apex submodule in the `lilabrooks.github.io` repo (ADR 0016).
