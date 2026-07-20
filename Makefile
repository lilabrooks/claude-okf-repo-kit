SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

KIT_DIR := $(CURDIR)

.PHONY: help test check-docs syntax shellcheck json scan links smoke smoke-source smoke-install smoke-existing smoke-idempotent smoke-brownfield smoke-candidates smoke-mirrors smoke-paths smoke-scripts smoke-helpers smoke-hooks smoke-okf smoke-harvest

help:
	@printf '%s\n' \
		'Available targets:' \
		'  make test            Run all validation checks.' \
		'  make check-docs      Fast gate for documentation-only changes.' \
		'  make syntax          Check script syntax.' \
		'  make shellcheck      Run ShellCheck when installed.' \
		'  make json            Validate JSON files.' \
		'  make scan            Search for stale repo references and local paths.' \
		'  make links           Check local Markdown links.' \
		'  make smoke           Run temp-repo smoke tests.' \
		'  make smoke-source    Test helper commands in this source-kit layout.' \
		'  make smoke-install   Simulate a new-repo install.' \
		'  make smoke-existing  Simulate installing into an existing repo.' \
		'  make smoke-idempotent Test repeated existing-repo updates.' \
		'  make smoke-brownfield Test adoption of a repo with its own docs layout.' \
		'  make smoke-candidates Test stale-candidate refresh across kit releases.' \
		'  make smoke-scripts   Test kit-managed script provenance across releases.' \
		'  make smoke-helpers    Test install, verify, and placeholder helpers.' \
		'  make smoke-hooks     Test Stop hook block/pass behavior.' \
		'  make smoke-okf       Test draft and ADR helper behavior.' \
		'  make smoke-harvest   Test the dogfood harvest registry and report.'

test: syntax shellcheck json scan links smoke

# Fast gate for documentation-only changes (ADR status flips, log-only edits):
# the checks that actually cover docs/ prose, without the installer and hook
# smoke simulations that a doc edit cannot affect. Not a replacement for `make
# test` — changes touching scripts, templates, settings, or VERSION need it.
check-docs: scan links
	@bash scripts/okf check-stale >/dev/null
	@bash scripts/okf pending >/dev/null
	@printf 'check-docs ok\n'

syntax:
	@bash -n scripts/okf
	@bash -n scripts/check-docs-sync.sh
	@bash -n scripts/check-okf-version.sh
	@bash -n scripts/create-new-repo
	@bash -n scripts/update-existing-repo
	@bash -n scripts/install-kit
	@bash -n scripts/verify-install
	@bash -n scripts/check-placeholders
	@bash -n scripts/harvest-dogfood
	@python3 -c 'from pathlib import Path; compile(Path("scripts/check-md-links.py").read_text(), "scripts/check-md-links.py", "exec")'
	@grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$' VERSION
	@printf 'syntax ok\n'

shellcheck:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck scripts/okf scripts/check-docs-sync.sh scripts/check-okf-version.sh scripts/create-new-repo scripts/update-existing-repo scripts/install-kit scripts/verify-install scripts/check-placeholders scripts/harvest-dogfood; \
		printf 'shellcheck ok\n'; \
	else \
		printf 'shellcheck skipped (not installed)\n'; \
	fi

json:
	@python3 -m json.tool settings.json >/dev/null
	@printf 'json ok\n'

scan:
	@if command -v rg >/dev/null 2>&1; then \
		scan_search() { rg -n "$$@"; }; \
	else \
		scan_search() { grep -rnEI "$$@"; }; \
	fi; \
	status=0; \
	scan_search 'OUTPUTS|Master Objective Prompt|src/|Delete the sample|output kit|No docs/okf-map|scripts as draft|/[U]sers/|/[Hh]ome/|Documents/' README.md CLAUDE.md 'Claude Code OKF Kit Guide.md' docs scripts templates site okf-map.yml settings.json .gitignore LICENSE .github || status=$$?; \
	if [ "$$status" -eq 0 ]; then \
		printf 'stale reference or local path scan failed\n' >&2; \
		exit 1; \
	fi; \
	if [ "$$status" -ne 1 ]; then \
		printf 'stale reference scan could not run (exit %s)\n' "$$status" >&2; \
		exit 1; \
	fi; \
	printf 'scan ok\n'

links:
	@python3 scripts/check-md-links.py README.md 'Claude Code OKF Kit Guide.md' CLAUDE.md docs
	@printf 'links ok\n'

smoke: smoke-source smoke-install smoke-existing smoke-idempotent smoke-brownfield smoke-candidates smoke-mirrors smoke-paths smoke-scripts smoke-helpers smoke-hooks smoke-okf smoke-harvest

smoke-source:
	@bash scripts/okf check-stale >/dev/null
	@bash scripts/okf adr-suggest >/dev/null
	@printf 'source-kit smoke ok\n'

smoke-install:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	target="$$tmp/new"; \
	output=$$(bash "$(KIT_DIR)/scripts/create-new-repo" "$$target"); \
	[[ "$$output" == *'Claude Code OKF kit repo created'* ]]; \
	[[ "$$output" == *'Created:'* ]]; \
	[[ "$$output" == *'Updated:'* ]]; \
	[[ "$$output" == *'Skipped:'* ]]; \
	[[ "$$output" == *'Verification run:'* ]]; \
	cd "$$target"; \
	test -f CLAUDE.md; \
	grep -q 'Claude Code repo instructions' CLAUDE.md; \
	! grep -q 'Claude Code OKF kit repo instructions' CLAUDE.md; \
	grep -q '^@docs/GOAL.md' CLAUDE.md; \
	grep -q '^@docs/specs/index.md' CLAUDE.md; \
	grep -q '^@docs/adr/index.md' CLAUDE.md; \
	test -f .claude/settings.json; \
	test -f .claude/hooks/check-docs-sync.sh; \
	test -f .claude/hooks/check-okf-version.sh; \
	test -f scripts/okf; \
	test -f docs/index.md; \
	grep -q 'kit_version:' docs/index.md; \
	grep -q '\[Log\](log.md)' docs/index.md; \
	grep -q '\[Source map\](okf-map.yml)' docs/index.md; \
	test -f docs/GOAL.md; \
	grep -q '# Milestones' docs/GOAL.md; \
	test -f docs/log.md; \
	test -f docs/specs/index.md; \
	test -f docs/adr/index.md; \
	test -f docs/okf-map.yml; \
	: 'site and maintainer-only artifacts must never reach a target repo (site-content spec, ADR 0009/0016)'; \
	! test -e site; \
	! test -e .github/workflows/pages.yml; \
	! test -e VERSION; \
	! test -e Makefile; \
	! test -e docs/specs/site-content.md; \
	! test -e docs/adr/0009-github-pages-website.md; \
	! test -e docs/adr/0016-apex-mirror-editorial-site.md; \
	! grep -q 'site/' docs/okf-map.yml; \
	grep -qFx '.DS_Store' .gitignore; \
	grep -qFx '.env' .gitignore; \
	grep -qFx '.env.*' .gitignore; \
	grep -qFx '!.env.example' .gitignore; \
	python3 -m json.tool .claude/settings.json >/dev/null; \
	grep -qF 'Read(./.env)' .claude/settings.json; \
	grep -qF 'Read(./**/.env)' .claude/settings.json; \
	test -f .okf-kit-backups/candidate-manifest; \
	[ "$$(wc -l < .okf-kit-backups/candidate-manifest | tr -d ' ')" -eq 9 ]; \
	grep -q 'scripts/okf' .okf-kit-backups/candidate-manifest; \
	grep -q '.claude/hooks/check-docs-sync.sh' .okf-kit-backups/candidate-manifest; \
	grep -q '.claude/hooks/check-okf-version.sh' .okf-kit-backups/candidate-manifest; \
	for skill in okf-goal-interview okf-acceptance-pass okf-adr-review okf-kit-upgrade okf-adopt okf-second-agent; do \
		test -f ".claude/skills/$$skill/SKILL.md"; \
		grep -q "^name: $$skill" ".claude/skills/$$skill/SKILL.md"; \
		grep -q "$$skill" .okf-kit-backups/candidate-manifest; \
	done; \
	grep -q 'okf-goal-interview' CLAUDE.md; \
	grep -q 'okf-acceptance-pass' CLAUDE.md; \
	grep -q 'okf-adr-review' CLAUDE.md; \
	grep -q 'okf-kit-upgrade' CLAUDE.md; \
	grep -q 'okf-adopt' CLAUDE.md; \
	grep -q 'okf-second-agent' CLAUDE.md; \
	bash scripts/okf check-stale >/dev/null; \
	bash scripts/okf draft >/dev/null; \
	bash scripts/okf adr-suggest >/dev/null; \
	printf 'new-repo install smoke ok\n'

smoke-existing:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	target="$$tmp/existing"; \
	mkdir -p "$$target"; \
	cd "$$target"; \
	git init -q; \
	printf '%s\n' '# Existing CLAUDE' > CLAUDE.md; \
	mkdir -p .claude; \
	printf '%s\n' '{"custom":true,"hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo existing"}]}]},"permissions":{"deny":["Read(./custom-secret)"]}}' > .claude/settings.json; \
	mkdir -p docs/specs docs/adr; \
	printf '%s\n' '# Existing docs index' > docs/index.md; \
	printf '%s\n' '# Existing goal' > docs/GOAL.md; \
	printf '%s\n' '# Existing log' > docs/log.md; \
	printf '%s\n' '# Existing specs index' > docs/specs/index.md; \
	printf '%s\n' '# Existing ADR index' > docs/adr/index.md; \
	printf '%s\n' 'mappings: []' > docs/okf-map.yml; \
	printf '%s\n' 'custom-ignore/' > .gitignore; \
	printf '%s\n' 'hello' > app.txt; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m init; \
	output=$$(bash "$(KIT_DIR)/scripts/update-existing-repo" "$$target"); \
	[[ "$$output" == *'Claude Code OKF kit update complete'* ]]; \
	: 'summary labels are a stable output contract (ADR 0023)'; \
	[[ "$$output" == *'Created:'* ]]; \
	[[ "$$output" == *'Updated:'* ]]; \
	[[ "$$output" == *'Skipped:'* ]]; \
	[[ "$$output" == *'Backed up:'* ]]; \
	[[ "$$output" == *'Needs review:'* ]]; \
	[[ "$$output" == *'Verification run:'* ]]; \
	test -f CLAUDE.md; \
	grep -q '# Existing CLAUDE' CLAUDE.md; \
	test -f CLAUDE.2.md; \
	grep -q 'Claude Code repo instructions' CLAUDE.2.md; \
	! grep -q 'Claude Code OKF kit repo instructions' CLAUDE.2.md; \
	test -f .claude/settings.json; \
	grep -q 'echo existing' .claude/settings.json; \
	grep -q 'check-docs-sync.sh' .claude/settings.json; \
	grep -q 'check-okf-version.sh' .claude/settings.json; \
	grep -qF 'Read(./custom-secret)' .claude/settings.json; \
	grep -qF 'Read(./.env)' .claude/settings.json; \
	grep -qF 'Read(./**/.env)' .claude/settings.json; \
	test -f scripts/okf; \
	test -f .claude/hooks/check-docs-sync.sh; \
	test -f .claude/hooks/check-okf-version.sh; \
	grep -q '# Existing docs index' docs/index.md; \
	grep -q '# Existing goal' docs/GOAL.md; \
	test -f docs/GOAL.2.md; \
	grep -q '# Milestones' docs/GOAL.2.md; \
	grep -q '# Existing log' docs/log.md; \
	grep -q '# Existing specs index' docs/specs/index.md; \
	grep -q '# Existing ADR index' docs/adr/index.md; \
	grep -q 'mappings: \[\]' docs/okf-map.yml; \
	grep -q 'custom-ignore/' .gitignore; \
	grep -q '.claude/settings.local.json' .gitignore; \
	grep -q 'CLAUDE.local.md' .gitignore; \
	grep -q '.okf-kit-backups/' .gitignore; \
	grep -qFx '.DS_Store' .gitignore; \
	grep -qFx '.env' .gitignore; \
	grep -qFx '.env.*' .gitignore; \
	grep -qFx '!.env.example' .gitignore; \
	test -f docs/index.2.md; \
	grep -q 'kit_version:' docs/index.2.md; \
	: 'heading-only starters write no candidates beside existing files (ADR 0018)'; \
	test ! -f docs/log.2.md; \
	test ! -f docs/specs/index.2.md; \
	test ! -f docs/adr/index.2.md; \
	test -f docs/okf-map.2.yml; \
	! grep -q '^layout:' docs/okf-map.2.yml; \
	python3 -m json.tool .claude/settings.json >/dev/null; \
	bash scripts/okf check-stale >/dev/null; \
	: 'site and maintainer-only artifacts must never reach an existing target repo'; \
	! test -e site; \
	! test -e .github/workflows/pages.yml; \
	! test -e docs/specs/site-content.md; \
	! test -e docs/adr/0009-github-pages-website.md; \
	! test -e docs/adr/0016-apex-mirror-editorial-site.md; \
	! grep -q 'site/' docs/okf-map.yml; \
	! grep -q 'site/' docs/okf-map.2.yml; \
	: 'unresolved candidates surface at session start and in verify-install'; \
	output=$$(CLAUDE_PROJECT_DIR="$$target" bash .claude/hooks/check-okf-version.sh </dev/null); \
	[[ "$$output" == *'Kit candidate review:'* ]]; \
	[[ "$$output" == *'CLAUDE.2.md'* ]]; \
	python3 -c 'import json,sys; json.loads(sys.stdin.read())' <<<"$$output"; \
	output=$$(bash "$(KIT_DIR)/scripts/verify-install" "$$target"); \
	[[ "$$output" == *'unresolved numbered kit candidate'* ]]; \
	rm CLAUDE.2.md docs/GOAL.2.md docs/index.2.md docs/okf-map.2.yml; \
	output=$$(CLAUDE_PROJECT_DIR="$$target" bash .claude/hooks/check-okf-version.sh </dev/null); \
	[[ "$$output" != *'Kit candidate review:'* ]]; \
	: 'a stamped bundle root gets kit_version in place, not a candidate (ADR 0019)'; \
	starget="$$tmp/stamped"; \
	mkdir -p "$$starget/docs"; \
	cd "$$starget"; \
	git init -q; \
	printf '%s\n' '---' 'okf_version: "0.1"' 'title: Docs index' '---' '' '# Documentation' '' 'Owner prose stays.' > docs/index.md; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m init; \
	bash "$(KIT_DIR)/scripts/update-existing-repo" "$$starget" >/dev/null; \
	test ! -f docs/index.2.md; \
	grep -q '^okf_version: "0.1"' docs/index.md; \
	grep -q "^kit_version: \"$$(cat "$(KIT_DIR)/VERSION")\"" docs/index.md; \
	grep -q '^title: Docs index' docs/index.md; \
	grep -q 'Owner prose stays.' docs/index.md; \
	[ "$$(head -1 docs/index.md)" = '---' ]; \
	bash "$(KIT_DIR)/scripts/update-existing-repo" "$$starget" >/dev/null; \
	test ! -f docs/index.2.md; \
	[ "$$(grep -c '^kit_version:' docs/index.md)" -eq 1 ]; \
	printf 'existing-repo install smoke ok\n'

smoke-idempotent:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	target="$$tmp/existing"; \
	mkdir -p "$$target"; \
	cd "$$target"; \
	git init -q; \
	printf '%s\n' '# Existing CLAUDE' > CLAUDE.md; \
	mkdir -p .claude docs/specs docs/adr; \
	printf '%s\n' '{"custom":true,"hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo existing"}]}]},"permissions":{"deny":["Read(./custom-secret)"]}}' > .claude/settings.json; \
	printf '%s\n' '# Existing docs index' > docs/index.md; \
	printf '%s\n' '# Existing log' > docs/log.md; \
	printf '%s\n' '# Existing specs index' > docs/specs/index.md; \
	printf '%s\n' '# Existing ADR index' > docs/adr/index.md; \
	printf '%s\n' 'mappings: []' > docs/okf-map.yml; \
	printf '%s\n' 'custom-ignore/' > .gitignore; \
	bash "$(KIT_DIR)/scripts/update-existing-repo" "$$target" >/dev/null; \
	bash "$(KIT_DIR)/scripts/update-existing-repo" "$$target" >/dev/null; \
	test -f CLAUDE.2.md; \
	test ! -f CLAUDE.3.md; \
	test -f docs/GOAL.md; \
	test ! -f docs/GOAL.2.md; \
	test -f docs/index.2.md; \
	test ! -f docs/index.3.md; \
	test ! -f docs/log.2.md; \
	test ! -f docs/specs/index.2.md; \
	test ! -f docs/adr/index.2.md; \
	test -f docs/okf-map.2.yml; \
	test ! -f docs/okf-map.3.yml; \
	[ "$$(grep -cFx '.claude/settings.local.json' .gitignore)" -eq 1 ]; \
	[ "$$(grep -cFx 'CLAUDE.local.md' .gitignore)" -eq 1 ]; \
	[ "$$(grep -cFx '.okf-kit-backups/' .gitignore)" -eq 1 ]; \
	[ "$$(grep -cFx '.DS_Store' .gitignore)" -eq 1 ]; \
	[ "$$(grep -cFx '.env' .gitignore)" -eq 1 ]; \
	[ "$$(grep -cFx '.env.*' .gitignore)" -eq 1 ]; \
	[ "$$(grep -cFx '!.env.example' .gitignore)" -eq 1 ]; \
	python3 -c 'import json; s=json.load(open(".claude/settings.json")); cmds=[hook.get("command", "") for entries in s.get("hooks", {}).values() for group in entries for hook in group.get("hooks", [])]; assert cmds.count("echo existing") == 1; assert cmds.count("bash \"$${CLAUDE_PROJECT_DIR}/.claude/hooks/check-docs-sync.sh\"") == 1; assert cmds.count("bash \"$${CLAUDE_PROJECT_DIR}/.claude/hooks/check-okf-version.sh\"") == 1; deny=s.get("permissions", {}).get("deny", []); assert deny.count("Read(./custom-secret)") == 1; assert deny.count("Read(./.env)") == 1; assert deny.count("Read(./**/.env)") == 1'; \
	printf 'existing-repo idempotency smoke ok\n'

smoke-brownfield:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	target="$$tmp/brown"; \
	mkdir -p "$$target"; \
	cd "$$target"; \
	git init -q; \
	mkdir -p docs/architecture/specification docs/adr docs/runbooks schemas; \
	printf '%s\n' '# Agent instructions' '' 'Playbook lives here.' > AGENTS.md; \
	printf '%s\n' '@AGENTS.md' '@docs/GOAL.md' > CLAUDE.md; \
	printf '%s\n' '# ADR-001: First decision' '' '- Status: Accepted' '' '## Context' 'x' > docs/adr/001-first-decision.md; \
	printf '%s\n' '# ADR-002: Second decision' '' '## Status' '' 'Proposed' '' '## Context' 'y' > docs/adr/002-second-decision.md; \
	printf '%s\n' '# System overview' 'text' > docs/architecture/specification/01-overview.md; \
	printf '%s\n' '# Operations runbook' > docs/runbooks/operations.md; \
	printf '%s\n' '{"x":1}' > schemas/config.schema.json; \
	printf '%s\n' '# Goal' '' 'Kind: service' '' 'Problem: real text.' '' '# Milestones' '' '- [x] Baseline. Verify: true.' > docs/GOAL.md; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m init; \
	output=$$(bash "$(KIT_DIR)/scripts/update-existing-repo" "$$target"); \
	: 'AGENTS.md-first staging: shim preserved, playbook candidate beside AGENTS.md'; \
	grep -qx '@AGENTS.md' CLAUDE.md; \
	test ! -f CLAUDE.2.md; \
	test -f AGENTS.2.md; \
	grep -q 'Claude Code repo instructions' AGENTS.2.md; \
	grep -q '^@docs/architecture/specification/index.md' AGENTS.2.md; \
	grep -q '^@docs/adr/index.md' AGENTS.2.md; \
	[[ "$$output" == *'AGENTS.md (kit playbook; this repo is AGENTS.md-first) exists; wrote candidate AGENTS.2.md'* ]]; \
	: 'detected layout recorded; no parallel tree; seeded indexes'; \
	grep -q '^layout:' docs/okf-map.yml; \
	grep -q 'specs_dir: docs/architecture/specification' docs/okf-map.yml; \
	test ! -d docs/specs; \
	test -d docs/architecture/specification/_drafts; \
	grep -q '01-overview.md' docs/architecture/specification/index.md; \
	grep -q 'System overview' docs/architecture/specification/index.md; \
	grep -q '001-first-decision.md' docs/adr/index.md; \
	grep -q '002-second-decision.md' docs/adr/index.md; \
	: 'filled goal gets no template candidate; bundle links the real homes'; \
	test ! -f docs/GOAL.2.md; \
	test -f docs/log.md; \
	grep -q '\[Specs\](architecture/specification/index.md)' docs/index.md; \
	grep -q '\[Runbooks\](runbooks/)' docs/index.md; \
	grep -q '\[Schemas\](../schemas/)' docs/index.md; \
	bash "$(KIT_DIR)/scripts/verify-install" "$$target" >/dev/null; \
	: 'helper follows the layout: tolerant pending, continued numbering, drafts'; \
	output=$$(bash scripts/okf pending); \
	[[ "$$output" == *'002-second-decision.md'* ]]; \
	[[ "$$output" != *'001-first-decision.md'* ]]; \
	[[ "$$output" != *'no status field'* ]]; \
	bash scripts/okf new-adr third-thing "Third thing" >/dev/null; \
	test -f docs/adr/003-third-thing.md; \
	grep -q '003 Third thing' docs/adr/index.md; \
	bash scripts/okf draft schemas >/dev/null; \
	test -f docs/architecture/specification/_drafts/schemas.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$target" bash .claude/hooks/check-okf-version.sh </dev/null); \
	[[ "$$output" == *'ADR review inbox: 2 ADR(s)'* ]]; \
	: 'second run stays idempotent'; \
	bash "$(KIT_DIR)/scripts/update-existing-repo" "$$target" >/dev/null; \
	test ! -f AGENTS.3.md; \
	test ! -f docs/GOAL.2.md; \
	test ! -f docs/adr/index.2.md; \
	test ! -f docs/architecture/specification/index.2.md; \
	: 'a commented @-import shim still counts as a shim (ADR 0022)'; \
	ctarget="$$tmp/brown-commented"; \
	mkdir -p "$$ctarget"; \
	cd "$$ctarget"; \
	git init -q; \
	printf '%s\n' '# Agent instructions' '' 'Playbook lives here.' > AGENTS.md; \
	printf '%s\n' 'Repository instructions live in AGENTS.md, shared with a second agent.' 'Edit AGENTS.md, not this file.' '' '@AGENTS.md' > CLAUDE.md; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m init; \
	bash "$(KIT_DIR)/scripts/update-existing-repo" "$$ctarget" >/dev/null; \
	test ! -f CLAUDE.2.md; \
	test -f AGENTS.2.md; \
	grep -q 'Edit AGENTS.md, not this file.' CLAUDE.md; \
	: 'a shim carrying the preloaded-context block under a heading is a shim (ADR 0025)'; \
	htarget="$$tmp/brown-heading-shim"; \
	mkdir -p "$$htarget"; \
	cd "$$htarget"; \
	git init -q; \
	printf '%s\n' '# Agent instructions' '' 'Playbook lives here.' > AGENTS.md; \
	printf '%s\n' 'Repository instructions live in AGENTS.md, shared with Codex — the master' 'objective, grounding rules, decision policy, guardrails, and task workflow.' 'Edit AGENTS.md, not this file.' '' '@AGENTS.md' '' '# Preloaded context' '' 'These imports resolve when Claude Code loads this file, so the goal and the' 'knowledge indexes are in context at session start without a read step.' '' '@docs/GOAL.md' '@docs/specs/index.md' '@docs/adr/index.md' > CLAUDE.md; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m init; \
	bash "$(KIT_DIR)/scripts/update-existing-repo" "$$htarget" >/dev/null; \
	test ! -f CLAUDE.2.md; \
	test -f AGENTS.2.md; \
	grep -q 'Edit AGENTS.md, not this file.' CLAUDE.md; \
	: 'a real playbook that merely imports AGENTS.md keeps the CLAUDE.2.md path'; \
	ptarget="$$tmp/brown-playbook"; \
	mkdir -p "$$ptarget"; \
	cd "$$ptarget"; \
	git init -q; \
	printf '%s\n' '# Agent instructions' > AGENTS.md; \
	printf '%s\n' '# Real playbook' '' 'Rules here.' '' '@AGENTS.md' > CLAUDE.md; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m init; \
	bash "$(KIT_DIR)/scripts/update-existing-repo" "$$ptarget" >/dev/null; \
	test -f CLAUDE.2.md; \
	test ! -f AGENTS.2.md; \
	printf 'brownfield adoption smoke ok\n'

smoke-candidates:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	kit="$$tmp/kit"; \
	mkdir -p "$$kit/scripts" "$$kit/templates"; \
	cp "$(KIT_DIR)/scripts/update-existing-repo" "$(KIT_DIR)/scripts/check-docs-sync.sh" "$(KIT_DIR)/scripts/check-okf-version.sh" "$(KIT_DIR)/scripts/okf" "$$kit/scripts/"; \
	cp -R "$(KIT_DIR)/templates/." "$$kit/templates/"; \
	cp "$(KIT_DIR)/settings.json" "$(KIT_DIR)/okf-map.yml" "$(KIT_DIR)/VERSION" "$$kit/"; \
	target="$$tmp/target"; \
	mkdir -p "$$target"; \
	printf '%s\n' '# Owner CLAUDE' > "$$target/CLAUDE.md"; \
	bash "$$kit/scripts/update-existing-repo" "$$target" >/dev/null; \
	test -f "$$target/CLAUDE.2.md"; \
	printf '%s\n' 'TEMPLATE V2 MARKER' >> "$$kit/templates/CLAUDE.md"; \
	output=$$(bash "$$kit/scripts/update-existing-repo" "$$target"); \
	[[ "$$output" == *'refreshed stale candidate CLAUDE.2.md'* ]]; \
	grep -q 'TEMPLATE V2 MARKER' "$$target/CLAUDE.2.md"; \
	test ! -f "$$target/CLAUDE.3.md"; \
	printf '%s\n' 'owner edit' >> "$$target/CLAUDE.2.md"; \
	printf '%s\n' 'TEMPLATE V3 MARKER' >> "$$kit/templates/CLAUDE.md"; \
	bash "$$kit/scripts/update-existing-repo" "$$target" >/dev/null; \
	grep -q 'owner edit' "$$target/CLAUDE.2.md"; \
	! grep -q 'TEMPLATE V3 MARKER' "$$target/CLAUDE.2.md"; \
	test -f "$$target/CLAUDE.3.md"; \
	grep -q 'TEMPLATE V3 MARKER' "$$target/CLAUDE.3.md"; \
	printf 'candidate refresh smoke ok\n'

smoke-mirrors:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	kit="$$tmp/kit"; \
	mkdir -p "$$kit/scripts" "$$kit/templates"; \
	cp "$(KIT_DIR)/scripts/update-existing-repo" "$(KIT_DIR)/scripts/check-docs-sync.sh" "$(KIT_DIR)/scripts/check-okf-version.sh" "$(KIT_DIR)/scripts/okf" "$$kit/scripts/"; \
	cp -R "$(KIT_DIR)/templates/." "$$kit/templates/"; \
	cp "$(KIT_DIR)/settings.json" "$(KIT_DIR)/okf-map.yml" "$(KIT_DIR)/VERSION" "$$kit/"; \
	target="$$tmp/target"; \
	mkdir -p "$$target"; \
	cd "$$target"; \
	git init -q; \
	bash "$$kit/scripts/update-existing-repo" "$$target" >/dev/null; \
	: 'no mirrors declared: no second-agent directories appear (ADR 0021)'; \
	test ! -e .codex; \
	: 'undeclared byte-identical mirror draws the advisory, never a sync'; \
	mkdir -p .codex/hooks; \
	cp .claude/hooks/check-docs-sync.sh .claude/hooks/check-okf-version.sh .codex/hooks/; \
	output=$$(bash "$(KIT_DIR)/scripts/verify-install" "$$target"); \
	[[ "$$output" == *'undeclared kit hook mirror at .codex/hooks'* ]]; \
	output=$$(CLAUDE_PROJECT_DIR="$$target" bash .claude/hooks/check-okf-version.sh </dev/null); \
	[[ "$$output" == *'Second-agent mirror check:'* ]]; \
	[[ "$$output" == *'.codex/hooks'* ]]; \
	python3 -c 'import json,sys; json.loads(sys.stdin.read())' <<<"$$output"; \
	printf '%s\n' '' 'mirrors:' '  - .codex/hooks' >> docs/okf-map.yml; \
	output=$$(bash "$$kit/scripts/update-existing-repo" "$$target"); \
	[[ "$$output" == *'.codex/hooks/check-docs-sync.sh'* ]]; \
	cmp -s .claude/hooks/check-docs-sync.sh .codex/hooks/check-docs-sync.sh; \
	cmp -s .claude/hooks/check-okf-version.sh .codex/hooks/check-okf-version.sh; \
	output=$$(bash "$(KIT_DIR)/scripts/verify-install" "$$target"); \
	[[ "$$output" == *'mirror .codex/hooks/check-docs-sync.sh matches'* ]]; \
	: 'declared mirror silences both advisories'; \
	[[ "$$output" != *'undeclared kit hook mirror'* ]]; \
	output=$$(CLAUDE_PROJECT_DIR="$$target" bash .claude/hooks/check-okf-version.sh </dev/null); \
	[[ "$$output" != *'Second-agent mirror check:'* ]]; \
	: 'idempotent rerun writes no mirror candidates'; \
	bash "$$kit/scripts/update-existing-repo" "$$target" >/dev/null; \
	test ! -e .codex/hooks/check-docs-sync.2.sh; \
	: 'kit release: unedited mirror refreshed in place alongside the original'; \
	printf '%s\n' '# kit vNEXT marker' >> "$$kit/scripts/check-docs-sync.sh"; \
	bash "$$kit/scripts/update-existing-repo" "$$target" >/dev/null; \
	grep -q 'kit vNEXT marker' .claude/hooks/check-docs-sync.sh; \
	grep -q 'kit vNEXT marker' .codex/hooks/check-docs-sync.sh; \
	test ! -e .codex/hooks/check-docs-sync.2.sh; \
	: 'owner-edited mirror preserved with a candidate; verify-install warns'; \
	printf 'owner edit\n' >> .codex/hooks/check-okf-version.sh; \
	printf '%s\n' '# kit vNEXT2 marker' >> "$$kit/scripts/check-okf-version.sh"; \
	bash "$$kit/scripts/update-existing-repo" "$$target" >/dev/null; \
	grep -q 'owner edit' .codex/hooks/check-okf-version.sh; \
	test -f .codex/hooks/check-okf-version.2.sh; \
	grep -q 'kit vNEXT2 marker' .codex/hooks/check-okf-version.2.sh; \
	output=$$(bash "$(KIT_DIR)/scripts/verify-install" "$$target"); \
	[[ "$$output" == *'differs from .claude/hooks/check-okf-version.sh'* ]]; \
	: 'mappings after a mirrors block stay clean in check-stale'; \
	bash scripts/okf check-stale >/dev/null; \
	printf 'second-agent mirror smoke ok\n'

smoke-paths:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	: 'installer and verifier survive glob characters and spaces in the target path'; \
	target="$$tmp/kit [new] target"; \
	bash "$(KIT_DIR)/scripts/create-new-repo" "$$target" >/dev/null; \
	test -f "$$target/CLAUDE.md"; \
	test -f "$$target/scripts/okf"; \
	test -f "$$target/.claude/hooks/check-docs-sync.sh"; \
	bash "$(KIT_DIR)/scripts/verify-install" "$$target" >/dev/null; \
	etarget="$$tmp/kit [existing] target"; \
	mkdir -p "$$etarget"; \
	cd "$$etarget"; \
	git init -q; \
	printf '%s\n' '# Owner CLAUDE' > CLAUDE.md; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m init; \
	bash "$(KIT_DIR)/scripts/update-existing-repo" "$$etarget" >/dev/null; \
	test -f "$$etarget/CLAUDE.2.md"; \
	bash "$(KIT_DIR)/scripts/update-existing-repo" "$$etarget" >/dev/null; \
	test ! -f "$$etarget/CLAUDE.3.md"; \
	bash "$(KIT_DIR)/scripts/verify-install" "$$etarget" >/dev/null; \
	bash scripts/okf check-stale >/dev/null; \
	output=$$(CLAUDE_PROJECT_DIR="$$etarget" bash .claude/hooks/check-okf-version.sh </dev/null); \
	[[ "$$output" == *'Kit candidate review:'* ]]; \
	printf 'special-character path smoke ok\n'

smoke-scripts:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	kit="$$tmp/kit"; \
	mkdir -p "$$kit/scripts" "$$kit/templates"; \
	cp "$(KIT_DIR)/scripts/create-new-repo" "$(KIT_DIR)/scripts/update-existing-repo" "$(KIT_DIR)/scripts/check-docs-sync.sh" "$(KIT_DIR)/scripts/check-okf-version.sh" "$(KIT_DIR)/scripts/okf" "$$kit/scripts/"; \
	cp -R "$(KIT_DIR)/templates/." "$$kit/templates/"; \
	cp "$(KIT_DIR)/settings.json" "$(KIT_DIR)/okf-map.yml" "$(KIT_DIR)/VERSION" "$$kit/"; \
	target="$$tmp/target"; \
	bash "$$kit/scripts/create-new-repo" "$$target" >/dev/null; \
	bash "$$kit/scripts/update-existing-repo" "$$target" >/dev/null; \
	test ! -f "$$target/.claude/hooks/check-docs-sync.2.sh"; \
	printf '%s\n' '# kit v2 marker' >> "$$kit/scripts/check-docs-sync.sh"; \
	output=$$(bash "$$kit/scripts/update-existing-repo" "$$target"); \
	grep -q 'kit v2 marker' "$$target/.claude/hooks/check-docs-sync.sh"; \
	test ! -f "$$target/.claude/hooks/check-docs-sync.2.sh"; \
	[[ "$$output" == *'.claude/hooks/check-docs-sync.sh'* ]]; \
	printf '%s\n' '# owner hardening' >> "$$target/.claude/hooks/check-docs-sync.sh"; \
	printf '%s\n' '# kit v3 marker' >> "$$kit/scripts/check-docs-sync.sh"; \
	output=$$(bash "$$kit/scripts/update-existing-repo" "$$target"); \
	grep -q 'owner hardening' "$$target/.claude/hooks/check-docs-sync.sh"; \
	! grep -q 'kit v3 marker' "$$target/.claude/hooks/check-docs-sync.sh"; \
	test -f "$$target/.claude/hooks/check-docs-sync.2.sh"; \
	grep -q 'kit v3 marker' "$$target/.claude/hooks/check-docs-sync.2.sh"; \
	[[ "$$output" == *'check-docs-sync.sh exists; wrote candidate'* ]]; \
	target2="$$tmp/preexisting"; \
	mkdir -p "$$target2/.claude/hooks"; \
	printf '%s\n' '#!/usr/bin/env bash' '# locally modified hook' > "$$target2/.claude/hooks/check-okf-version.sh"; \
	bash "$$kit/scripts/update-existing-repo" "$$target2" >/dev/null; \
	grep -q 'locally modified hook' "$$target2/.claude/hooks/check-okf-version.sh"; \
	test -f "$$target2/.claude/hooks/check-okf-version.2.sh"; \
	printf '%s\n' '# owner-tuned wording' >> "$$target/.claude/skills/okf-adr-review/SKILL.md"; \
	printf '%s\n' '## kit v4 skill marker' >> "$$kit/templates/skills/okf-adr-review/SKILL.md"; \
	printf '%s\n' '## kit v4 skill marker' >> "$$kit/templates/skills/okf-kit-upgrade/SKILL.md"; \
	bash "$$kit/scripts/update-existing-repo" "$$target" >/dev/null; \
	grep -q 'owner-tuned wording' "$$target/.claude/skills/okf-adr-review/SKILL.md"; \
	test -f "$$target/.claude/skills/okf-adr-review/SKILL.2.md"; \
	grep -q 'kit v4 skill marker' "$$target/.claude/skills/okf-adr-review/SKILL.2.md"; \
	grep -q 'kit v4 skill marker' "$$target/.claude/skills/okf-kit-upgrade/SKILL.md"; \
	test ! -f "$$target/.claude/skills/okf-kit-upgrade/SKILL.2.md"; \
	printf 'script provenance smoke ok\n'

smoke-helpers:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	new_target="$$tmp/new"; \
	output=$$(bash "$(KIT_DIR)/scripts/install-kit" "$$new_target"); \
	[[ "$$output" == *'Mode: new repo'* ]]; \
	bash "$(KIT_DIR)/scripts/verify-install" "$$new_target" >/dev/null; \
	if bash "$(KIT_DIR)/scripts/check-placeholders" "$$new_target" >"$$tmp/placeholders.out" 2>&1; then \
		printf 'placeholder check should report template placeholders\n' >&2; \
		exit 1; \
	fi; \
	grep -q 'CLAUDE.md still has the template comment' "$$tmp/placeholders.out"; \
	grep -q 'docs/GOAL.md still has the template comment' "$$tmp/placeholders.out"; \
	printf '%s\n' \
		'---' \
		'type: Playbook' \
		'title: Claude Code repo instructions' \
		'description: Filled test instructions.' \
		'tags: [claude-code]' \
		'timestamp: 2026-07-05T00:00:00Z' \
		'---' \
		'' \
		'# Master objective' \
		'' \
		'Current state: test repo is installed.' \
		'Target state: test repo has filled instructions.' \
		'Constraints: follow docs/specs/index.md.' \
		'Done when: make test passes.' \
		'' \
		'# Workflow for each task' \
		'' \
		'1. Run make test.' \
		'' \
		'# Verification commands' \
		'' \
		'- Tests: make test' \
		'- Lint/typecheck: make lint' \
		'- Build: make build' \
		> "$$new_target/CLAUDE.md"; \
	printf '%s\n' 'mappings:' '  - source: "app/**"' '    docs:' '      - "docs/specs/app.md"' > "$$new_target/docs/okf-map.yml"; \
	printf '%s\n' \
		'---' \
		'type: Goal' \
		'title: Test goal' \
		'---' \
		'' \
		'# Goal' \
		'' \
		'Kind: utility.' \
		'Problem: test repos need a filled goal.' \
		'' \
		'# Success criteria' \
		'' \
		'- make test passes.' \
		'' \
		'# Milestones' \
		'' \
		'- [ ] Ship the first slice. Verify: make test.' \
		> "$$new_target/docs/GOAL.md"; \
	bash "$(KIT_DIR)/scripts/check-placeholders" "$$new_target" >/dev/null; \
	existing_target="$$tmp/existing"; \
	mkdir -p "$$existing_target"; \
	printf '%s\n' 'hello' > "$$existing_target/app.txt"; \
	output=$$(bash "$(KIT_DIR)/scripts/install-kit" "$$existing_target"); \
	[[ "$$output" == *'Mode: existing repo'* ]]; \
	bash "$(KIT_DIR)/scripts/verify-install" "$$existing_target" >/dev/null; \
	printf 'install helper smoke ok\n'

smoke-hooks:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	cd "$$tmp"; \
	git init -q; \
	mkdir -p app docs/specs docs/adr docs/notes scripts .claude/hooks; \
	cp "$(KIT_DIR)/scripts/okf" scripts/okf; \
	cp "$(KIT_DIR)/scripts/check-docs-sync.sh" .claude/hooks/check-docs-sync.sh; \
	: 'phase 1: map present but no active mapping -> the crude prefix gate applies'; \
	printf '%s\n' 'mappings:' > docs/okf-map.yml; \
	printf '%s\n' '---' 'type: Spec' '---' > docs/specs/app.md; \
	printf '%s\n' '# Log' > docs/log.md; \
	printf '%s\n' 'export function app() { return 1; }' > app/main.js; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m init; \
	printf '%s\n' 'export function app() { return 2; }' > app/main.js; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ "$$output" == *'Code changed this session but nothing under /docs was updated'* ]]; \
	output=$$(printf '%s' '{"stop_hook_active": true}' | CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh 2>.claude/loopwarn.txt); \
	[[ -z "$$output" ]]; \
	grep -q 'avoid a loop' .claude/loopwarn.txt; \
	rm -f .claude/loopwarn.txt; \
	output=$$(printf '%s' '{"session_id": "smoke"}' | CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh); \
	[[ "$$output" == *'Code changed this session'* ]]; \
	git checkout -q -- app/main.js; \
	printf '%s\n' 'not a license' > LICENSE-MIT; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ "$$output" == *'Code changed this session'* ]]; \
	rm LICENSE-MIT; \
	printf '%s\n' 'MIT' > LICENSE; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ -z "$$output" ]]; \
	rm LICENSE; \
	printf '%s\n' 'API_URL=' > .env.example; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ -z "$$output" ]]; \
	rm .env.example; \
	mkdir -p .codex; \
	printf '%s\n' '{}' > .codex/hooks.json; \
	printf '%s\n' '# Agents' > AGENTS.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ -z "$$output" ]]; \
	rm -rf .codex AGENTS.md; \
	: 'phase 2: active mappings -> check-stale is the authority (ADR 0018)'; \
	printf '%s\n' 'mappings:' '  - source: "app/**"' '    docs:' '      - "docs/specs/app.md"' '  - source: "lib/**"' '    docs:' '      - "schemas/lib.schema.json"' > docs/okf-map.yml; \
	mkdir -p lib schemas; \
	printf '%s\n' '{}' > schemas/lib.schema.json; \
	printf '%s\n' 'export function lib() { return 1; }' > lib/main.js; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m map; \
	printf '%s\n' 'export function app() { return 2; }' > app/main.js; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ "$$output" == *'OKF stale mapping check failed'* ]]; \
	[[ "$$output" != *'nothing under /docs was updated'* ]]; \
	printf '%s\n' 'unrelated' > docs/notes/other.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ "$$output" == *'OKF stale mapping check failed'* ]]; \
	printf '%s\n' 'mapped change' >> docs/specs/app.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ -z "$$output" ]]; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m mapped-doc-update; \
	: 'a mapped governing doc outside docs/ counts as documentation'; \
	printf '%s\n' 'export function lib() { return 2; }' > lib/main.js; \
	printf '%s\n' '{"v":2}' > schemas/lib.schema.json; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ -z "$$output" ]]; \
	git checkout -q -- lib schemas; \
	: 'unmapped-only changes no longer hard-block once mappings exist'; \
	printf '%s\n' 'not a license' > LICENSE-MIT; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ -z "$$output" ]]; \
	rm LICENSE-MIT; \
	printf '%s\n' '# Readme' > README.md; \
	git add README.md; \
	git -c user.email=a@example.com -c user.name=A commit -q -m readme; \
	printf '%s\n' '# changed' > README.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ -z "$$output" ]]; \
	: 'SessionStart: tolerant inbox, candidate skip, valid JSON, stamp silence'; \
	cp "$(KIT_DIR)/scripts/check-okf-version.sh" .claude/hooks/check-okf-version.sh; \
	printf '%s\n' '---' 'status: proposed' 'title: One' '---' > docs/adr/0001-one.md; \
	printf '%s\n' '---' 'status: accepted' 'title: Two' '---' > docs/adr/0002-two.md; \
	printf '%s\n' '---' 'status: proposed' 'title: Three' '---' > docs/adr/0003-three.md; \
	printf '%s\n' '# ADR-004: Four' '' '- Status: Proposed' > docs/adr/0004-four.md; \
	printf '%s\n' '# ADR-005: Five' '' '## Status' '' 'Accepted (2026-07-13)' > docs/adr/0005-five.md; \
	cp docs/adr/0001-one.md docs/adr/0001-one.2.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-okf-version.sh </dev/null); \
	[[ "$$output" == *'ADR review inbox: 3 ADR(s)'* ]]; \
	[[ "$$output" != *'OKF version check'* ]]; \
	printf '%s' "$$output" | python3 -m json.tool >/dev/null; \
	sed -i.bak 's/^status: proposed/status: accepted/' docs/adr/0001-one.md docs/adr/0003-three.md; \
	sed -i.bak 's/^- Status: Proposed/- Status: Accepted/' docs/adr/0004-four.md; \
	rm -f docs/adr/0001-one.md.bak docs/adr/0003-three.md.bak docs/adr/0004-four.md.bak docs/adr/0001-one.2.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-okf-version.sh </dev/null); \
	[[ "$$output" != *'ADR review inbox'* ]]; \
	: 'map with active mappings stays silent; empty map draws the coverage note'; \
	[[ "$$output" != *'OKF map check:'* ]]; \
	cp docs/okf-map.yml docs/okf-map.keep.yml; \
	printf '%s\n' 'mappings:' '  # - source: "app/**"' > docs/okf-map.yml; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-okf-version.sh </dev/null); \
	[[ "$$output" == *'OKF map check:'* ]]; \
	[[ "$$output" == *'no active mappings'* ]]; \
	python3 -c 'import json,sys; json.loads(sys.stdin.read())' <<<"$$output"; \
	mv docs/okf-map.keep.yml docs/okf-map.yml; \
	printf 'hook smoke ok\n'

smoke-harvest:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	export OKF_DOGFOOD_REGISTRY="$$tmp/registry"; \
	target="$$tmp/dogfood-target"; \
	bash "$(KIT_DIR)/scripts/create-new-repo" "$$target" >/dev/null; \
	git -C "$$target" add -A; \
	git -C "$$target" -c user.email=a@example.com -c user.name=A commit -q -m init; \
	output=$$(bash "$(KIT_DIR)/scripts/harvest-dogfood" add "$$target"); \
	[[ "$$output" == *'Registered dogfood-target'* ]]; \
	if bash "$(KIT_DIR)/scripts/harvest-dogfood" add "$$target" >/dev/null 2>&1; then \
		printf 'duplicate add should fail\n' >&2; exit 1; \
	fi; \
	output=$$(bash "$(KIT_DIR)/scripts/harvest-dogfood"); \
	[[ "$$output" == *'commits since last harvest'*': 0'* ]]; \
	[[ "$$output" == *'matches kit'* ]]; \
	[[ "$$output" == *'No proposed ADRs awaiting review.'* ]]; \
	printf '%s\n' 'print(1)' > "$$target/app.py"; \
	printf '%s\n' '' '## 2026-07-11' '' '- Widget fix; exclusion gap worth upstreaming to claude-okf-repo-kit.' >> "$$target/docs/log.md"; \
	git -C "$$target" add -A; \
	git -C "$$target" -c user.email=a@example.com -c user.name=A commit -q -m widget; \
	printf '%s\n' '# local hardening' >> "$$target/.claude/hooks/check-docs-sync.sh"; \
	output=$$(bash "$(KIT_DIR)/scripts/harvest-dogfood"); \
	[[ "$$output" == *'commits since last harvest'*': 1'* ]]; \
	[[ "$$output" == *'widget'* ]]; \
	[[ "$$output" == *'FLAGGED'* ]]; \
	[[ "$$output" == *'worth upstreaming'* ]]; \
	[[ "$$output" == *'check-docs-sync.sh: OWNER-EDITED'* ]]; \
	[[ "$$output" == *'uncommitted changes: 1'* ]]; \
	bash "$(KIT_DIR)/scripts/harvest-dogfood" mark >/dev/null; \
	output=$$(bash "$(KIT_DIR)/scripts/harvest-dogfood"); \
	[[ "$$output" == *'commits since last harvest'*': 0'* ]]; \
	output=$$(bash "$(KIT_DIR)/scripts/harvest-dogfood" list); \
	[[ "$$output" == *'dogfood-target'* ]]; \
	output=$$(bash "$(KIT_DIR)/scripts/harvest-dogfood" query 'worth upstreaming'); \
	[[ "$$output" == *'dogfood-target [log]'* ]]; \
	[[ "$$output" == *'worth upstreaming'* ]]; \
	output=$$(bash "$(KIT_DIR)/scripts/harvest-dogfood" query '^dogfood-target.goal.*Problem'); \
	[[ "$$output" == *'[goal] docs/GOAL.md'* ]]; \
	if bash "$(KIT_DIR)/scripts/harvest-dogfood" query 'zz-no-such-term-zz' >/dev/null 2>&1; then \
		printf 'query with no matches should exit nonzero\n' >&2; exit 1; \
	fi; \
	printf 'dogfood harvest smoke ok\n'

smoke-okf:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	cd "$$tmp"; \
	git init -q; \
	mkdir -p app docs/specs docs/adr scripts; \
	cp "$(KIT_DIR)/scripts/okf" scripts/okf; \
	printf '%s\n' 'mappings:' '  - source: "app/**"' '    docs:' '      - "docs/specs/app.md"' > docs/okf-map.yml; \
	printf '%s\n' 'export function handler() { return true; }' > app/main.js; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m init; \
	bash scripts/okf draft app >/dev/null; \
	test -f docs/specs/_drafts/app.md; \
	grep -q 'Public surface clues' docs/specs/_drafts/app.md; \
	printf '%s\n' '{"dependencies":{}}' > package.json; \
	git add package.json; \
	git -c user.email=a@example.com -c user.name=A commit -q -m package; \
	printf '%s\n' '{"dependencies":{"redis":"1.0.0"}}' > package.json; \
	output=$$(bash scripts/okf adr-suggest); \
	[[ "$$output" == *'Runtime dependency or package manager change'* ]]; \
	[[ "$$output" == *'Scaffold: bash scripts/okf new-adr'* ]]; \
	output=$$(bash scripts/okf check-stale); \
	[[ "$$output" == *'OKF mappings are current.'* ]]; \
	[[ "$$output" == *'no okf-map.yml mapping'* ]]; \
	[[ "$$output" == *'package.json'* ]]; \
	mkdir -p .codex; \
	printf '%s\n' '{}' > .codex/hooks.json; \
	printf '%s\n' '# Agents' > AGENTS.md; \
	output=$$(bash scripts/okf check-stale); \
	[[ "$$output" == *'package.json'* ]]; \
	[[ "$$output" != *'AGENTS.md'* ]]; \
	[[ "$$output" != *'.codex'* ]]; \
	rm -rf .codex AGENTS.md; \
	bash scripts/okf new-adr cache-layer "Cache layer" >/dev/null; \
	test -f docs/adr/0001-cache-layer.md; \
	grep -q 'status: proposed' docs/adr/0001-cache-layer.md; \
	grep -q '0001 Cache layer' docs/adr/index.md; \
	bash scripts/okf new-adr second-decision >/dev/null; \
	test -f docs/adr/0002-second-decision.md; \
	grep -q '0002 Second decision' docs/adr/index.md; \
	output=$$(bash scripts/okf pending); \
	[[ "$$output" == *'0001-cache-layer.md'* ]]; \
	[[ "$$output" == *'0002-second-decision.md'* ]]; \
	sed -i.bak 's/^status: proposed/status: accepted/' docs/adr/0001-cache-layer.md; \
	rm -f docs/adr/0001-cache-layer.md.bak; \
	printf '%s\n' '---' 'type: ADR' 'title: Legacy' '---' > docs/adr/0009-legacy.md; \
	printf '%s\n' '# ADRs' > docs/adr/index.2.md; \
	cp docs/adr/0002-second-decision.md docs/adr/0002-second-decision.2.md; \
	output=$$(bash scripts/okf pending); \
	[[ "$$output" != *'0001-cache-layer.md'* ]]; \
	[[ "$$output" == *'0002-second-decision.md'* ]]; \
	[[ "$$output" != *'index.2.md'* ]]; \
	[[ "$$output" != *'0002-second-decision.2.md'* ]]; \
	[[ "$$output" == *'no status field'* ]]; \
	[[ "$$output" == *'0009-legacy.md'* ]]; \
	bash scripts/okf new-spec payments-contract "Payments contract" >/dev/null; \
	test -f docs/specs/payments-contract.md; \
	grep -q 'type: Spec' docs/specs/payments-contract.md; \
	grep -q 'Payments contract' docs/specs/index.md; \
	: 'a sole alpha-prefixed convention is continued, not forked (ADR 0019)'; \
	prefdir="$$tmp/prefixed"; \
	mkdir -p "$$prefdir/docs/specs" "$$prefdir/docs/adr" "$$prefdir/scripts"; \
	cp "$(KIT_DIR)/scripts/okf" "$$prefdir/scripts/okf"; \
	cd "$$prefdir"; \
	git init -q; \
	printf '%s\n' '---' 'title: First' 'status: accepted' '---' > docs/adr/adr-0001-first.md; \
	printf '%s\n' '---' 'title: Ninth' 'status: accepted' '---' > docs/adr/adr-0009-ninth.md; \
	printf '%s\n' '# ADRs' '' '- [0001 First](adr-0001-first.md): x' > docs/adr/index.md; \
	printf '%s\n' '---' 'title: Objective' '---' > docs/specs/spec-000-objective.md; \
	printf '%s\n' '---' 'title: Core' '---' > docs/specs/spec-008-core.md; \
	printf '%s\n' '| ID | Spec |' '| --- | --- |' '| SPEC-000 | [Objective](spec-000-objective.md) |' '' 'Prose after the table stays last.' > docs/specs/index.md; \
	bash scripts/okf new-adr tenth-thing "Tenth thing" >/dev/null; \
	test -f docs/adr/adr-0010-tenth-thing.md; \
	grep -q '0010 Tenth thing' docs/adr/index.md; \
	grep -q 'adr-0010-tenth-thing.md' docs/adr/index.md; \
	output=$$(bash scripts/okf new-spec new-surface "New surface"); \
	test -f docs/specs/spec-009-new-surface.md; \
	[[ "$$output" == *'table layout'* ]]; \
	[[ "$$output" == *'spec-009-new-surface.md'* ]]; \
	! grep -q 'spec-009-new-surface.md' docs/specs/index.md; \
	[ "$$(tail -1 docs/specs/index.md)" = 'Prose after the table stays last.' ]; \
	: 'bare-numeric names keep precedence when both forms coexist'; \
	mixdir="$$tmp/mixed"; \
	mkdir -p "$$mixdir/docs/adr" "$$mixdir/scripts"; \
	cp "$(KIT_DIR)/scripts/okf" "$$mixdir/scripts/okf"; \
	cd "$$mixdir"; \
	git init -q; \
	printf '%s\n' '---' 'title: Third' 'status: accepted' '---' > docs/adr/003-third.md; \
	printf '%s\n' '---' 'title: Ninth' 'status: accepted' '---' > docs/adr/adr-0009-ninth.md; \
	bash scripts/okf new-adr fourth-thing "Fourth thing" >/dev/null; \
	test -f docs/adr/004-fourth-thing.md; \
	printf 'okf command smoke ok\n'
