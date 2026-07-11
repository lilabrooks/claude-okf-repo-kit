#!/usr/bin/env bash
# Destination in your repo: .claude/hooks/check-docs-sync.sh
# No chmod needed: settings.json invokes this via `bash`.
#
# Stop hook: when the agent tries to finish a turn, this first checks whether
# implementation files changed without anything under docs/ being touched. If
# scripts/okf is installed, it then checks whether the touched source areas have
# matching mapped docs or a log.md rationale. Honors stop_hook_active from the
# hook stdin payload: after a prior block in the same stop cycle it warns on
# stderr instead of blocking again, so a turn that cannot update docs (e.g. a
# read-only sandbox) never loops. Manual runs without a stdin payload behave
# exactly as before.

ROOT="${CLAUDE_PROJECT_DIR:-${CODEX_PROJECT_DIR:-.}}"

STOP_ACTIVE=0
if [ ! -t 0 ]; then
  hook_input=$(cat 2>/dev/null || true)
  if printf '%s' "$hook_input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    STOP_ACTIVE=1
  fi
fi

changed=$( { git -C "$ROOT" diff --name-only HEAD; git -C "$ROOT" ls-files --others --exclude-standard; } 2>/dev/null | sort -u )

# Directory entries keep prefix semantics; file entries are end-anchored so
# e.g. LICENSE-MIT or CLAUDE.md.bak count as code instead of silently skipping
# the docs check. .codex/ and AGENTS.md are agent config, not implementation,
# for repos that also run a second agent against the same checkout.
code_changed=$(printf '%s\n' "$changed" \
  | grep -vE '^(docs/|\.claude/|\.codex/|CLAUDE\.md$|CLAUDE\.local\.md$|AGENTS\.md$|README\.md$|CHANGELOG\.md$|LICENSE$|\.gitignore$|\.editorconfig$|scripts/okf$)' \
  | grep -v '^$' \
  | head -n 1)
docs_changed=$(printf '%s\n' "$changed" | grep -E '^docs/' | head -n 1)

if [ -n "$code_changed" ] && [ -z "$docs_changed" ]; then
  if [ "$STOP_ACTIVE" = "1" ]; then
    echo "check-docs-sync: docs still out of sync after a prior block; allowing the stop to avoid a loop." >&2
    exit 0
  fi
  cat <<'EOF'
{"decision": "block", "reason": "Code changed this session but nothing under /docs was updated. Per the repo playbook (CLAUDE.md; AGENTS.md if present): if behavior or a contract changed, update the governing file in /docs/specs or /docs/adr and add a dated entry to /docs/log.md. If no doc change is warranted, add a one-line entry to /docs/log.md saying why."}
EOF
  exit 0
fi

if [ -n "$code_changed" ] && [ -f "$ROOT/scripts/okf" ]; then
  stale_result=$(OKF_HOOK=1 OKF_ROOT="$ROOT" bash "$ROOT/scripts/okf" check-stale 2>/dev/null)
  if [ -n "$stale_result" ]; then
    if [ "$STOP_ACTIVE" = "1" ]; then
      echo "check-docs-sync: OKF stale check still failing after a prior block; allowing the stop to avoid a loop." >&2
      exit 0
    fi
    printf '%s\n' "$stale_result"
    exit 0
  fi
fi

exit 0
