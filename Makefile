SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

KIT_DIR := $(CURDIR)

.PHONY: help test syntax shellcheck json scan links smoke smoke-source smoke-install smoke-existing smoke-idempotent smoke-candidates smoke-scripts smoke-helpers smoke-hooks smoke-okf smoke-harvest

help:
	@printf '%s\n' \
		'Available targets:' \
		'  make test            Run all validation checks.' \
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
		'  make smoke-candidates Test stale-candidate refresh across kit releases.' \
		'  make smoke-scripts   Test kit-managed script provenance across releases.' \
		'  make smoke-helpers    Test install, verify, and placeholder helpers.' \
		'  make smoke-hooks     Test Stop hook block/pass behavior.' \
		'  make smoke-okf       Test draft and ADR helper behavior.' \
		'  make smoke-harvest   Test the dogfood harvest registry and report.'

test: syntax shellcheck json scan links smoke

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

smoke: smoke-source smoke-install smoke-existing smoke-idempotent smoke-candidates smoke-scripts smoke-helpers smoke-hooks smoke-okf smoke-harvest

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
	grep -qFx '.DS_Store' .gitignore; \
	grep -qFx '.env' .gitignore; \
	grep -qFx '.env.*' .gitignore; \
	grep -qFx '!.env.example' .gitignore; \
	python3 -m json.tool .claude/settings.json >/dev/null; \
	grep -qF 'Read(./.env)' .claude/settings.json; \
	grep -qF 'Read(./**/.env)' .claude/settings.json; \
	test -f .okf-kit-backups/candidate-manifest; \
	[ "$$(wc -l < .okf-kit-backups/candidate-manifest | tr -d ' ')" -eq 3 ]; \
	grep -q 'scripts/okf' .okf-kit-backups/candidate-manifest; \
	grep -q '.claude/hooks/check-docs-sync.sh' .okf-kit-backups/candidate-manifest; \
	grep -q '.claude/hooks/check-okf-version.sh' .okf-kit-backups/candidate-manifest; \
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
	[[ "$$output" == *'Created:'* ]]; \
	[[ "$$output" == *'Updated:'* ]]; \
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
	test -f docs/log.2.md; \
	test -f docs/specs/index.2.md; \
	test -f docs/adr/index.2.md; \
	test -f docs/okf-map.2.yml; \
	python3 -m json.tool .claude/settings.json >/dev/null; \
	bash scripts/okf check-stale >/dev/null; \
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
	test -f docs/log.2.md; \
	test ! -f docs/log.3.md; \
	test -f docs/specs/index.2.md; \
	test ! -f docs/specs/index.3.md; \
	test -f docs/adr/index.2.md; \
	test ! -f docs/adr/index.3.md; \
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

smoke-candidates:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	kit="$$tmp/kit"; \
	mkdir -p "$$kit/scripts" "$$kit/templates"; \
	cp "$(KIT_DIR)/scripts/update-existing-repo" "$(KIT_DIR)/scripts/check-docs-sync.sh" "$(KIT_DIR)/scripts/check-okf-version.sh" "$(KIT_DIR)/scripts/okf" "$$kit/scripts/"; \
	cp "$(KIT_DIR)/templates/CLAUDE.md" "$(KIT_DIR)/templates/GOAL.md" "$$kit/templates/"; \
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

smoke-scripts:
	@set -eu; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	kit="$$tmp/kit"; \
	mkdir -p "$$kit/scripts" "$$kit/templates"; \
	cp "$(KIT_DIR)/scripts/create-new-repo" "$(KIT_DIR)/scripts/update-existing-repo" "$(KIT_DIR)/scripts/check-docs-sync.sh" "$(KIT_DIR)/scripts/check-okf-version.sh" "$(KIT_DIR)/scripts/okf" "$$kit/scripts/"; \
	cp "$(KIT_DIR)/templates/CLAUDE.md" "$(KIT_DIR)/templates/GOAL.md" "$$kit/templates/"; \
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
	printf '%s\n' 'mappings:' '  - source: "app/**"' '    docs:' '      - "docs/specs/app.md"' > docs/okf-map.yml; \
	printf '%s\n' '---' 'type: Spec' '---' > docs/specs/app.md; \
	printf '%s\n' '# Log' > docs/log.md; \
	printf '%s\n' 'export function app() { return 1; }' > app/main.js; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m init; \
	printf '%s\n' 'export function app() { return 2; }' > app/main.js; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh); \
	[[ "$$output" == *'Code changed this session but nothing under /docs was updated'* ]]; \
	printf '%s\n' 'unrelated' > docs/notes/other.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh); \
	[[ "$$output" == *'OKF stale mapping check failed'* ]]; \
	printf '%s\n' 'mapped change' >> docs/specs/app.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh); \
	[[ -z "$$output" ]]; \
	git add .; \
	git -c user.email=a@example.com -c user.name=A commit -q -m mapped-doc-update; \
	printf '%s\n' '# Readme' > README.md; \
	git add README.md; \
	git -c user.email=a@example.com -c user.name=A commit -q -m readme; \
	printf '%s\n' '# changed' > README.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh); \
	[[ -z "$$output" ]]; \
	printf '%s\n' 'export function app() { return 3; }' > app/main.js; \
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
	mkdir -p .codex; \
	printf '%s\n' '{}' > .codex/hooks.json; \
	printf '%s\n' '# Agents' > AGENTS.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-docs-sync.sh </dev/null); \
	[[ -z "$$output" ]]; \
	cp "$(KIT_DIR)/scripts/check-okf-version.sh" .claude/hooks/check-okf-version.sh; \
	printf '%s\n' '---' 'status: proposed' 'title: One' '---' > docs/adr/0001-one.md; \
	printf '%s\n' '---' 'status: accepted' 'title: Two' '---' > docs/adr/0002-two.md; \
	printf '%s\n' '---' 'status: proposed' 'title: Three' '---' > docs/adr/0003-three.md; \
	cp docs/adr/0001-one.md docs/adr/0001-one.2.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-okf-version.sh </dev/null); \
	[[ "$$output" == *'ADR review inbox: 2 ADR(s)'* ]]; \
	printf '%s' "$$output" | python3 -m json.tool >/dev/null; \
	sed -i.bak 's/^status: proposed/status: accepted/' docs/adr/0001-one.md docs/adr/0003-three.md; \
	rm -f docs/adr/0001-one.md.bak docs/adr/0003-three.md.bak docs/adr/0001-one.2.md; \
	output=$$(CLAUDE_PROJECT_DIR="$$tmp" bash .claude/hooks/check-okf-version.sh </dev/null); \
	[[ "$$output" != *'ADR review inbox'* ]]; \
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
	printf 'okf command smoke ok\n'
