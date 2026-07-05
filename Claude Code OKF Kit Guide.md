# Stating a goal Claude Code can iterate on

Reference for this repo. Specs live in `/docs/specs`, ADRs in `/docs/adr`. Fact-checked and corrected on 2026-07-04 (see "What changed" at the bottom).

---

## 1. The goal statement

A goal Claude Code can iterate on is one it can check itself against. "Migrate our Express APIs to GraphQL" is a direction. The agent can't tell when it's done or whether the last change moved it closer.

A workable goal statement has 4 parts:

**Current state.** One or two sentences on what exists today. This anchors the diff.

**Target state.** What the repo looks like when finished. Concrete nouns: which modules exist, which are gone, which contracts hold.

**Constraints.** What must stay true along the way. Point at the governing ADRs by filename instead of restating them.

**Definition of done.** Criteria the agent can verify mechanically: a test command that passes, an endpoint that responds, a directory that no longer exists, a benchmark number.

### Example

Weak:

> Migrate our legacy Express REST APIs to a clean-architecture GraphQL layer.

Iterable:

> Current state: Express REST API in `[current API path]`, ~40 endpoints, session auth per `/docs/adr/0007-session-auth.md`.
> Target state: GraphQL layer in `[target API path]` covering all 40 endpoints; the legacy REST path deleted.
> Constraints: follow `/docs/adr/0007-session-auth.md` and `/docs/specs/api-contracts.md`. No new runtime dependencies without a new ADR.
> Done when: `npm test` passes, the GraphQL schema resolves every operation listed in `/docs/specs/api-contracts.md`, and nothing imports from the legacy REST path.

The second version lets Claude Code measure its own progress each iteration and stop arguing with you about what "done" means.

---

## 2. Put it in CLAUDE.md, don't paste it

Claude Code reads the repo's `CLAUDE.md` automatically at session start. A pasted "master prompt" evaporates when the session ends; CLAUDE.md is always loaded. Drop the section below into your repo root `CLAUDE.md` and fill the brackets.

```markdown
## Master objective
Current state: [what exists today]
Target state: [what done looks like]
Constraints: [governing ADRs/specs by path]
Done when: [verifiable criteria: test command, contract coverage, removals]

## Grounding rules (docs are the source of truth)
- Before planning any change, read `/docs/specs/index.md` and `/docs/adr/index.md`,
  then the specific spec or ADR governing the files you'll touch.
- When code and docs disagree, flag the mismatch. Don't silently pick a side.
- If a task conflicts with an existing ADR, stop and ask before writing code.
  Superseding an ADR is my decision, made via a new ADR file.
- Architectural changes start with a new ADR in `/docs/adr/` for my review,
  before any implementation.

## Workflow for each task
1. Impact analysis: name the specs and ADRs that govern the target files.
2. Implement. Run [test command] and make it pass.
3. Knowledge alignment: if behavior or a contract changed, update the governing
   spec or ADR to match. Add a dated entry to /docs/log.md, newest first.

## Verification commands
- Tests: [command]
- Lint/typecheck: [command]
```

Fill in the real commands. "Ensure all tests pass" means nothing to an agent that has to guess whether you run pytest, vitest, or make.

---

## 3. Per-task prompts

With CLAUDE.md carrying the objective and rules, per-task prompts stay short and point at files:

**New feature against existing specs:**

> Review the product goal in `/docs/specs/user_billing.md` and the constraints in `/docs/adr/0012-data-retention.md`. Implement the missing Stripe webhook handler in `[billing module path]` complying with both.

**Refactor toward an ADR:**

> `[auth module path]` has drifted from `/docs/adr/0007-session-auth.md`. Refactor the middleware to match that ADR.

**Architecture change (ADR first, code second):**

> We want Redis caching on the API. First write a new ADR at `/docs/adr/0015-cache-strategy.md` covering topology and invalidation. After I approve it, implement the connection wrapper.

For larger changes, run the first prompt in plan mode so you can review the approach before any file changes.

---

## 4. Keeping docs evergreen

The Stage 3 rule (update the spec after the code changes) is the piece that keeps this loop honest. Two guardrails so it doesn't rot:

Update a spec or ADR only when behavior or a contract actually changed. Rewriting docs after every commit produces churn that buries real changes.

Keep `/docs/log.md` as a dated changelog, newest first. That filename and convention come straight from the OKF spec, so it stays portable across agents.

For larger repos, add the tiny repo-local `scripts/okf` Bash helper included in this kit. It is not an official OKF CLI, not a global command, and not a prompt. It has three commands:

```bash
bash scripts/okf check-stale
bash scripts/okf draft [paths...]
bash scripts/okf adr-suggest
```

`check-stale` is the highest-signal check. It reads `/docs/okf-map.yml`, where source globs point at their governing specs and ADRs. If `path/to/module/**` changed but `/docs/specs/module.md` did not, the command reports stale knowledge even if some unrelated doc changed.

`draft` is for bootstrap and repair. It writes generated files under `/docs/specs/_drafts/` from observable module facts: file tree, exports, routes, schemas, tests, and mapped docs. Drafts are scaffolding. Review them, rewrite them into commitments, then promote them into `/docs/specs/`.

`adr-suggest` should stay conservative. It proposes ADRs only for decision-shaped changes: new dependencies, persistence models, cache or queue behavior, workers, auth/security/privacy, public API contracts, deployment topology, or ownership boundaries. It should stay quiet for local refactors, test-only changes, and bug fixes that don't create a standing decision.

If you want your `/docs` tree to be OKF-compliant, each spec file needs YAML frontmatter with at least a `type:` field, and each directory gets an `index.md` listing its contents. That index is what lets an agent survey the bundle cheaply before reading whole documents. A folder literally named `.okf/` is optional; the spec cares about file conventions, and `/docs` works fine.

---

## 5. Installing this kit

This repo is a source kit. Its files sit at the root so you can review them. When you install it into another repo, copy them to their intended paths:

```text
templates/CLAUDE.md   -> CLAUDE.md
settings.json         -> .claude/settings.json
scripts/check-docs-sync.sh    -> .claude/hooks/check-docs-sync.sh
scripts/check-okf-version.sh  -> .claude/hooks/check-okf-version.sh
scripts/okf                   -> scripts/okf
okf-map.yml           -> docs/okf-map.yml
```

For a new repo:

1. Run `bash /path/to/kit/scripts/create-new-repo /path/to/new-repo`.
2. Fill in every bracket in `CLAUDE.md`.
3. Replace the placeholder in `docs/okf-map.yml` with real source-to-doc mappings.
4. Commit the installed files.
5. Open the repo in Claude Code.

The new-repo script creates the target directory if needed, but it refuses a non-empty target except for an optional `.git/` directory.

For an existing repo:

1. Run `bash /path/to/kit/scripts/update-existing-repo /path/to/existing-repo`.
2. Review the printed summary. It lists created, updated, skipped, backed-up, and review-needed files.
3. Review `.okf-kit-backups/<timestamp>/` for replaced-file backups.
4. Review same-folder numbered candidates such as `CLAUDE.2.md` and `docs/okf-map.2.yml`.
5. Merge any candidate content that belongs in the existing repo files.
6. Confirm `.gitignore` kept existing entries and gained the kit's required local-file ignores.
7. Add or update `docs/okf-map.yml` gradually, starting with the modules Claude changes most.
8. Run `bash scripts/okf check-stale` and `bash scripts/okf adr-suggest` from the target repo root.
9. Fill any remaining brackets in `CLAUDE.md`, then commit once the checks are clean.

The existing-repo script is intentionally conservative: it appends `.gitignore`, merges Claude settings, backs up replaced kit-managed scripts, and writes same-folder numbered candidates for same-name Markdown/map files.

Read `README.md` for copy-paste commands.

In this source repo, root `CLAUDE.md` is filled in for maintaining the kit itself. Target repos receive `templates/CLAUDE.md` as their installable `CLAUDE.md`.

To validate this source kit before publishing it, run `make test` from the kit repo. The Makefile is for this repo's own checks; it does not need to be installed in target repos.

After installing the kit into a target repo, verify that repo from its root:

```bash
python3 -m json.tool .claude/settings.json >/dev/null
bash -n scripts/okf
bash -n .claude/hooks/check-docs-sync.sh
bash -n .claude/hooks/check-okf-version.sh
bash scripts/okf check-stale
bash scripts/okf adr-suggest
git status --short --ignored
```

Then open the target repo in Claude Code and make a small mapped source change. The Stop hook should block a turn with no `/docs` update, and it should also block a mapped source change paired only with an unrelated doc edit.

If local files exist, `git status --ignored` should show `.claude/settings.local.json`, `CLAUDE.local.md`, and `.okf-kit-backups/` as ignored.

---

## What changed in this revision (fact check, 2026-07-04)

**OKF is real.** Open Knowledge Format v0.1 was published by Google Cloud on 2026-06-12: markdown concepts with YAML frontmatter (`type` required; `title`, `description`, `resource`, `tags`, `timestamp` optional), `index.md` and `log.md` as reserved filenames. Spec: [GoogleCloudPlatform/knowledge-catalog](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md), site: [okf.md](https://okf.md/), announcement: [Google Cloud blog](https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing/). The spec is 3 weeks old, so conventions around it may shift; check SPEC.md before restructuring `/docs`.

**"ARD" corrected to ADR.** The original called them "Architectural Requirement Documents." The established term, and your folder name, is ADR: Architecture Decision Record.

**Citations stripped.** Most of the original's links didn't support the claims they were attached to (a Kubernetes deployment guide cited for "self-healing repositories," a Codex feature writeup cited for Claude Code behavior). They looked auto-stitched by an answer engine. Only primary sources remain.

**Token-savings claim softened.** Reading small indexed docs instead of raw code does cut context cost, and it's why the `index.md` progressive-disclosure pattern exists. But "incredibly fast" and implied cost figures had no benchmark behind them.

**"Confirm you understand" closer removed.** It burns a turn on a compliance recital. CLAUDE.md loading automatically makes it pointless.

**Paths localized.** `.okf/specs/` and `.okf/architecture/` became your actual `/docs/specs` and `/docs/adr`.

**OKF helper commands added.** The repo kit now includes `scripts/okf` and `docs/okf-map.yml` so Claude can catch stale mapped specs, generate review-only spec drafts, and suggest ADRs only when a change has decision shape.

**Safe installers added.** New-repo setup refuses non-empty targets. Existing-repo setup appends `.gitignore`, preserves existing Markdown/map files, writes numbered candidates for conflicts, and prints a clear summary of what changed.
