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

Claude Code reads the repo's `CLAUDE.md` automatically at session start. A pasted "master prompt" evaporates when the session ends; CLAUDE.md is always loaded.

CLAUDE.md can also import other files: a line like `@docs/GOAL.md` inlines that file's content at load time (imports resolve recursively, up to five hops). The installed template uses this to preload the goal file and the spec/ADR indexes, so every session starts with the goal, the milestone state, and a map of the knowledge bundle already in context — no read step, no relying on the agent choosing to look. Keep the imported files small; full specs and ADRs stay on disk until a task needs them, which is what keeps the context window available for the actual work.

Drop the section below into your repo root `CLAUDE.md` and fill the brackets.

```markdown
@docs/GOAL.md
@docs/specs/index.md
@docs/adr/index.md

## Master objective
Current state: [what exists today]
Target state: [what done looks like]
Constraints: [governing ADRs/specs by path]
Done when: [verifiable criteria: test command, contract coverage, removals]

## Grounding rules (docs are the source of truth)
- Before planning any change, read `/docs/specs/index.md` and `/docs/adr/index.md`,
  then the specific spec or ADR governing the files you'll touch.
- When code and docs disagree, flag the mismatch. Don't silently pick a side.
- If a task conflicts with an accepted ADR, stop and ask before writing code.
  Superseding an accepted ADR is my decision, made via a new ADR file.
- Architectural changes start with a new ADR in `/docs/adr/`, marked
  `status: proposed`, before any implementation. Implement against it and
  leave it flagged for my review.

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

The kit also installs `docs/GOAL.md` from `templates/GOAL.md`. That file carries the full goal definition the Master objective summarizes: the repo kind (app, service, or utility), the problem, the target state, verifiable success criteria, non-goals, constraints, and an ordered milestone backlog. The milestone list is what makes "continue" mean something across sessions — Claude Code takes the first unchecked milestone, verifies it against its stated check, checks it off, logs the progress in `docs/log.md`, and moves to the next milestone until the backlog is done or a decision reserved for you comes up. Keep the Master objective as the one-screen summary and let `docs/GOAL.md` carry the detail.

The installed template goes further than this excerpt. It splits ownership explicitly — you provide the goal; Claude Code makes decision-shaped changes through `status: proposed` ADRs you review later, while goal edits and accepted-ADR supersession stay yours — and it holds standing guardrails in every session: tests must pass before a milestone is checked off, failing tests can't be deleted or weakened to force green, secrets stay out of tracked files, security-sensitive changes get an `adr-suggest` check, and destructive or outward-facing actions wait for your explicit go-ahead. If the goal file still contains template brackets, Claude Code runs a short goal interview to fill them with you before iterating: what you're building and for whom, the concrete done state, the example interactions users will actually give it (including a messy or wrong one — those become spec examples and test cases), the mechanical verification, non-goals, which stack choices are fixed versus left to proposed ADRs, and the first shippable slice; the drafted backlog ends with a README-quickstart milestone by default, and any verification step naming a tool the repo doesn't provide is confirmed installed up front or marked owner-gated so the loop expects the pause. In an existing codebase it proposes answers from the code first and lets you correct them. Interrupted sessions resume cleanly too: at session start, uncommitted changes are treated as in-flight work from the cut-off session and reconciled against the milestone backlog and the newest `docs/log.md` entry — finished or backed out — before any new milestone starts. And the loop has an ending: when every milestone is checked and the success criteria pass, Claude Code runs a first-time-user acceptance pass (clean checkout, README quickstart, realistic and wrong inputs — tests prove the contract, this proves the experience), then reports the goal met, lists any ADRs still awaiting your review, and proposes candidate next milestones — from log known-items, ADR revisit triggers, acceptance-pass findings, standard repo hygiene still missing (license, CI, dependency updates, badges), and extensions inside your non-goals — adding nothing until you choose. A session-start note also keeps counting proposed ADRs until you review them, so pending decisions can't quietly pile up. You accept a pending ADR by flipping its `status: proposed` to accepted, or by telling Claude Code to make the edit; rejecting one reverts the work per its rollback trigger. That combination is what lets "continue until the goal is met" run unattended without giving up the safety rails. To keep the always-loaded playbook small, the four episodic procedures — the goal interview, the acceptance pass, ADR review mechanics, and the kit-upgrade walkthrough — ship as installed skills (`.claude/skills/okf-*/`) that load only when their moment arrives; `CLAUDE.md` keeps binding one-line versions that still work on their own if a skill doesn't fire.

Know the limit of those rails: they are instructions, not enforcement. The kit's mechanical enforcement is the docs-sync hooks plus a settings rule that denies Claude Code reading local `.env` files — nothing else; the test, wider security, and destructive-action guardrails depend on Claude Code following `CLAUDE.md`. When a rule must be guaranteed rather than followed — tests green before merge, no secrets in commits — put it in your repo's own CI and branch protection, on top of this kit.

---

## 3. Per-task prompts

With CLAUDE.md carrying the objective and rules, per-task prompts stay short and point at files:

**New feature against existing specs:**

> Review the product goal in `/docs/specs/user_billing.md` and the constraints in `/docs/adr/0012-data-retention.md`. Implement the missing Stripe webhook handler in `[billing module path]` complying with both.

**Refactor toward an ADR:**

> `[auth module path]` has drifted from `/docs/adr/0007-session-auth.md`. Refactor the middleware to match that ADR.

**Architecture change (ADR first, code second):**

> We want Redis caching on the API. First write a new ADR at `/docs/adr/0015-cache-strategy.md` covering topology and invalidation. After I approve it, implement the connection wrapper.

That prompt gates implementation on your approval, which is worth it when you're watching. When you're not, the installed decision policy is the default instead: Claude Code writes the ADR as `status: proposed`, implements against it, and leaves it flagged for your review.

For larger changes, run the first prompt in plan mode so you can review the approach before any file changes.

---

## 4. Keeping docs evergreen

The Stage 3 rule (update the spec after the code changes) is the piece that keeps this loop honest. Two guardrails so it doesn't rot:

Update a spec or ADR only when behavior or a contract actually changed. Rewriting docs after every commit produces churn that buries real changes.

Keep `/docs/log.md` as a dated changelog, newest first. That filename and convention come straight from the OKF spec, so it stays portable across agents. That portability is deliberate: if you optionally point a second agent (Codex CLI, for example) at an installed repo for chores like CI or dependency automation, the shipped hooks treat its config (`.codex/`, `AGENTS.md`) as agent config rather than code, and the README's "Using a second agent for repo chores" section covers the rest — the goal loop itself stays with Claude Code.

For larger repos, add the tiny repo-local `scripts/okf` Bash helper included in this kit. It is not an official OKF CLI, not a global command, and not a prompt. It has three commands:

```bash
bash scripts/okf check-stale
bash scripts/okf draft [paths...]
bash scripts/okf adr-suggest
```

`check-stale` is the highest-signal check. It reads `/docs/okf-map.yml`, where source globs point at their governing specs and ADRs. If `path/to/module/**` changed but `/docs/specs/module.md` did not, the command reports stale knowledge even if some unrelated doc changed.

`draft` is for bootstrap and repair. It writes generated files under `/docs/specs/_drafts/` from observable module facts: file tree, exports, routes, schemas, tests, and mapped docs. Drafts are scaffolding. Review them, rewrite them into commitments, then promote them into `/docs/specs/`.

`adr-suggest` should stay conservative. It proposes ADRs only for decision-shaped changes: new dependencies, persistence models, cache or queue behavior, workers, auth/security/privacy, public API contracts, deployment topology, or ownership boundaries. It should stay quiet for local refactors, test-only changes, and bug fixes that don't create a standing decision.

The paths above are the defaults. A repo that already keeps its knowledge elsewhere — chaptered specs under `docs/architecture/specification/`, three-digit ADRs with `- Status:` bullets instead of frontmatter — points the kit at it with a small `layout:` block in `/docs/okf-map.yml` (`specs_dir`, `adr_dir`, `stamp_file`), and the helper, hooks, and installers follow it. `new-adr` continues whatever numbering already exists (including alpha-prefixed conventions like `adr-0001-*`), and the status scans read the body conventions too, so nothing has to be renamed or moved to adopt the kit in a brownfield repo.

Why the mechanics live in scripts and hooks rather than judgment: the kit deliberately splits the work four ways. Hooks carry what must never be skipped — the session-start inbox and the stop-time docs gate run as fixed code paths in the harness, so Claude can't forget them at the end of a long session. The helper carries what must never vary — the next ADR number, the index entry, the staleness computation are code, so Claude Code in an installed repo runs one command instead of recalculating the mechanics each time, at zero model tokens and with no improvised numbering on a bad day. The preloaded imports (section 2) carry what every session must know. Claude's judgment is reserved for the content: what a spec commits to, what an ADR argues, what code satisfies a milestone. And when a helper meets a shape it doesn't recognize, it declines visibly instead of guessing wrong; Claude works around it in the open, and that workaround is a defect signal to carry back into the kit — the dogfood loop that produced the brownfield tolerances above. A silent workaround would hide the misfire and re-pay its cost in every session; harvesting it pays once.

If you want your `/docs` tree to be OKF-compliant, each spec file needs YAML frontmatter with at least a `type:` field, and each directory gets an `index.md` listing its contents. That index is what lets an agent survey the bundle cheaply before reading whole documents. A folder literally named `.okf/` is optional; the spec cares about file conventions, and `/docs` works fine.

---

## 5. Installing this kit

This repo is a source kit. Its files sit at the root so you can review them. When you install it into another repo, copy them to their intended paths:

```text
templates/CLAUDE.md   -> CLAUDE.md
templates/GOAL.md     -> docs/GOAL.md
templates/skills/okf-*/SKILL.md -> .claude/skills/okf-*/SKILL.md
settings.json         -> .claude/settings.json
scripts/check-docs-sync.sh    -> .claude/hooks/check-docs-sync.sh
scripts/check-okf-version.sh  -> .claude/hooks/check-okf-version.sh
scripts/okf                   -> scripts/okf
okf-map.yml           -> docs/okf-map.yml
```

For a new repo:

1. Run `bash /path/to/kit/scripts/create-new-repo /path/to/new-repo`.
2. Fill in every bracket in `docs/GOAL.md`: repo kind, problem, target state, success criteria, and milestones.
3. Fill in every bracket in `CLAUDE.md`.
4. Replace the placeholder in `docs/okf-map.yml` with real source-to-doc mappings.
5. Commit the installed files.
6. Open the repo in Claude Code and ask it to continue toward the goal, or give it a specific task.

Steps 2 and 3 can be delegated: open the repo in Claude Code straight after installing and the goal interview fills both files with you before the first task.

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
9. Fill any remaining brackets in `CLAUDE.md` and `docs/GOAL.md`, then commit once the checks are clean.

The existing-repo script is intentionally conservative: it appends `.gitignore`, merges Claude settings, and writes same-folder numbered candidates for same-name Markdown/map files, skipping the candidate when the existing file already matches the kit content. Kit-managed scripts are refreshed in place (after a backup) only when a digest manifest proves they are the kit's own unedited output; a script you edited is preserved, with the kit version staged beside it as a numbered candidate for review.

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
