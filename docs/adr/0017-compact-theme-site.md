---
type: ADR
title: Adopt Compact Theme for the website
description: Rebuild the site on the vendored Compact Theme (compact-theme.css/.js) for a maintained design system with light/dark modes, replacing the bespoke styles.css.
tags: [website, theme, dark-mode, styling]
generated: { by: claude-code/opus-4.8, at: 2026-07-12T00:00:00Z }
owner: Lila Brooks
deciders: [Lila Brooks]
status: accepted
---

# Status

Accepted

# Context

The site was a bespoke stylesheet (`site/styles.css`) with a single warm-paper-and-cobalt light palette and many custom component classes. The owner separately maintains **Compact Theme** ([lilabrooks/compact-theme](https://github.com/lilabrooks/compact-theme), BSD-2-Clause) — a portable, tested, framework-free HTML/CSS/JS theme built with the same IBM Plex fonts and the same visual language, but adding **light and dark palettes**, a system-preference default with a persistent toggle, code-block copy controls, and a lean component vocabulary.

Because both share a design language (same author), the light palettes are nearly identical, so adopting the theme mainly buys a maintained design system and a real dark mode rather than a new look. The owner chose a full re-skin onto the theme rather than only borrowing its palette.

# Decision

- **Vendor Compact Theme into `site/`**: `compact-theme.css`, `compact-theme.js`, its `compact-theme-LICENSE.txt` and `compact-theme-COPYRIGHT.txt`, reusing the IBM Plex fonts already in `site/fonts/`. Remove the bespoke `site/styles.css`.
- **Rebuild every page on the theme's classes** — `index.html`, `how-it-works/`, `dogfood/`, `404.html`, and the redirect stubs use `compact-shell`, `compact-header`/`compact-brand`/`compact-nav`, `compact-hero`, `compact-section`/`compact-section-head`, `compact-grid`/`compact-card`, `compact-tag`, `compact-button`, `compact-footer`, and the `compact-theme-toggle`.
- **Light/dark**: the first visit follows `prefers-color-scheme`; a header toggle sets `data-theme` and stores it in `localStorage` (via `compact-theme.js`). All colours flow through the theme's `--compact-*` tokens, so the flow-diagram SVG (retokened from the old palette to `--compact-*`) and every component adapt to both modes.
- **Relative paths (ADR 0016) are preserved**: `compact-theme.css`/`.js` and the stylesheet's `./fonts/` references resolve at both the apex and the project base, so the submodule mirror keeps working.
- **Page-specific needs the theme doesn't cover** — numbered adoption steps, honesty callouts, the flow diagram — are expressed with the theme's own primitives (cards with `compact-tag`, plain ordered lists constrained inline, an inline-styled `<figure>`) plus minimal inline styles. No new stylesheet is introduced.
- **Licences retained** per the theme's terms: its BSD-2-Clause `LICENSE`/`COPYRIGHT`, the SPDX headers in the CSS/JS, and the SIL OFL `fonts/LICENSE.txt`.

Alternatives considered:

- Adopt only the theme's palette and dark-mode tokens onto the existing `styles.css`, keeping the bespoke components. Rejected by the owner in favour of the maintained theme, accepting the loss of some custom layouts.
- Palette swap with no dark mode. Rejected: nearly a no-op, since the light palettes already match.

# Consequences

- A maintained design system with light/dark, at the cost of flattening some bespoke components (the dark "what is verified" table, the numbered route styling, the path cards) into the theme's leaner card/section vocabulary.
- Theme updates now come from the compact-theme repo; refresh by re-vendoring `compact-theme.css`/`.js` and the licence files.
- The site-content spec's style rules now target Compact Theme rather than `styles.css`. Extends ADR 0009 (the site) and ADR 0016 (the apex mirror and relative-path rule); both still hold.
- No `VERSION` bump: `site/` is source-only and never installed into target repos.
