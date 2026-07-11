#!/usr/bin/env bash
# Destination in your repo: .claude/hooks/check-okf-version.sh
# No chmod needed: settings.json invokes this via `bash`.
#
# SessionStart hook: compares the OKF version this repo declares in docs/index.md
# against the latest spec version published on the OKF main branch, and the
# kit_version this repo declares against the kit's published VERSION file. When
# either differs, it injects a note into Claude's context; the "OKF version
# policy" and "Kit version policy" sections in the repo playbook tell the agent
# what to do. It also counts ADRs still status: proposed so the owner's review
# inbox stays visible at session start (offline, local scan only).
# Fails silent (exit 0, no output) when offline, when docs/index.md carries no
# kit_version stamp, or if the upstream layouts change.

SPEC_URL="https://raw.githubusercontent.com/GoogleCloudPlatform/knowledge-catalog/main/okf/SPEC.md"
KIT_VERSION_URL="https://raw.githubusercontent.com/lilabrooks/claude-okf-repo-kit/main/VERSION"
ROOT="${CLAUDE_PROJECT_DIR:-${CODEX_PROJECT_DIR:-.}}"

notes=""

append_note() {
  if [ -n "$notes" ]; then
    notes="$notes $1"
  else
    notes="$1"
  fi
}

latest=$(curl -fsSL --max-time 5 "$SPEC_URL" 2>/dev/null \
  | grep -m1 -oE 'Version [0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+')
declared=$(grep -m1 -oE 'okf_version:[[:space:]]*"?[0-9]+\.[0-9]+"?' "$ROOT/docs/index.md" 2>/dev/null \
  | grep -oE '[0-9]+\.[0-9]+')

if [ -n "$latest" ] && [ "$latest" != "$declared" ]; then
  append_note "OKF version check: the latest OKF spec version on the official main branch is $latest. This repo's docs/index.md declares okf_version ${declared:-(none)}. The OKF version policy in the repo playbook (CLAUDE.md; AGENTS.md if present) applies."
fi

kit_declared=$(grep -m1 -oE 'kit_version:[[:space:]]*"?[0-9]+\.[0-9]+\.[0-9]+"?' "$ROOT/docs/index.md" 2>/dev/null \
  | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

if [ -n "$kit_declared" ]; then
  kit_latest=$(curl -fsSL --max-time 5 "$KIT_VERSION_URL" 2>/dev/null \
    | grep -m1 -oE '[0-9]+\.[0-9]+\.[0-9]+')
  if [ -n "$kit_latest" ] && [ "$kit_latest" != "$kit_declared" ]; then
    append_note "Kit version check: this repo was installed from claude-okf-repo-kit $kit_declared and the published kit version is $kit_latest. The Kit version policy in the repo playbook (CLAUDE.md; AGENTS.md if present) applies."
  fi
fi

# ADR review inbox: count ADRs whose first status line is `proposed`, skipping
# the index and installer-written numbered review candidates — the same files
# `scripts/okf pending` lists.
pending_count=0
for adr in "$ROOT"/docs/adr/*.md; do
  [ -e "$adr" ] || continue
  case "$(basename "$adr")" in
    index.md|*.[0-9].md|*.[0-9][0-9].md) continue ;;
  esac
  status=$(grep -m1 -E '^status:' "$adr" 2>/dev/null | sed -E 's/^status:[[:space:]]*//; s/[[:space:]]+$//')
  [ "$status" = "proposed" ] && pending_count=$((pending_count + 1))
done

if [ "$pending_count" -gt 0 ]; then
  append_note "ADR review inbox: $pending_count ADR(s) are status: proposed awaiting the owner's review. List them with: bash scripts/okf pending. The decision policy in the repo playbook applies."
fi

if [ -n "$notes" ]; then
  cat <<EOF
{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "$notes"}}
EOF
fi

exit 0
