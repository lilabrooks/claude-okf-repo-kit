---
type: ADR
title: GitHub Pages website from main via Actions
description: Publish the kit's website from a site/ folder on main with the official GitHub Actions Pages deployment.
tags: [website, github-pages, deployment]
generated: { by: claude-code/fable-5, at: 2026-07-08T00:00:00Z }
owner: Lila Brooks
deciders: [Lila Brooks]
status: accepted
---

# Status

Accepted

# Context

The kit needs a website — hosted by GitHub, with its source maintained in this repo — that explains what the kit installs and, in detail, how Claude Code works with an installed repo.

GitHub Pages offers two publication models. The classic "deploy from branch" mode serves either a branch root (the `gh-pages` pattern) or a `/docs` folder. Both fit this repo badly: `docs/` is already the OKF knowledge bundle, and an orphan `gh-pages` branch puts the site outside the history that the Stop hook, `check-stale`, and pull requests govern, while keeping it deployed typically relies on force-pushes.

The modern model deploys from a GitHub Actions workflow, which can publish any folder on `main`.

# Decision

- The website source lives in `site/` on `main`: static HTML and CSS, self-contained, no build step and no dependency manifests, consistent with the kit's Bash-only tooling constraint.
- `.github/workflows/pages.yml` deploys it with the official actions (`configure-pages`, `upload-pages-artifact`, `deploy-pages`) on pushes to `main` that touch `site/` or the workflow itself, plus manual dispatch. `.github/dependabot.yml` already keeps these action versions current weekly.
- `site/**` and the workflow are mapped in `docs/okf-map.yml`, and `site` joins the Makefile stale-reference scan, so the website is a governed source area like everything else in the repo.
- The site is source-only: installers never copy it into target repos.
- Publishing requires one server-side toggle — repository Settings -> Pages -> Source: GitHub Actions — which leaves no trace in a clone and is therefore recorded in the README "Repository settings" section with a restore command. Enabling it is the owner's action, per the guardrail on outward-facing operations.

Alternatives considered:

- `gh-pages` orphan branch. Rejected: splits the repo into two histories, escapes the docs-sync and stale-map guardrails, and conflicts with the no-history-rewrite guardrail for keeping it updated.
- Deploy-from-branch `/docs` folder. Rejected: `docs/` is the OKF knowledge bundle; publishing it as the website or renaming the bundle are both unacceptable.
- External hosting (Netlify, Vercel, and similar). Rejected: adds an account and configuration outside the repo for a static page GitHub hosts natively.

# Consequences

Site changes ride normal commits and pull requests on `main`, and each deployment is an inspectable workflow run.

Once the owner enables the Pages toggle, any push to `main` touching `site/` publishes automatically; site edits are outward-facing from that point on. Until the toggle is enabled, the workflow's deploy step fails visibly, which is expected.

The site's descriptions of kit behavior can drift from the installed templates; the okf-map entry ties `site/**` to the packaging spec so `check-stale` flags site edits that change described behavior without a knowledge update, and vice versa the log records template changes the site must follow.
