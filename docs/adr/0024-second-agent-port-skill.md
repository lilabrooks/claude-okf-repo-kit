---
type: ADR
title: Second-agent port as an installed skill
description: Ship the recurring second-agent port procedure as a sixth installed skill, okf-second-agent, with undeclared-mirror advisories in verify-install and the SessionStart hook.
tags: [adr, skills, second-agent, mirrors]
timestamp: 2026-07-20T01:04:05Z
status: accepted
---

# Status

Accepted (2026-07-19)

# Context

All four installed dogfood targets (repo-pulse, skywatch, spec-agent-cli, specdrift) hand-built the same second-agent stack beside Claude Code: a ported `AGENTS.md` playbook, byte-identical hook mirrors under `.codex/hooks/`, adapted `okf-*` skills, and (eventually) a parity guard in the repo's own gate. The canonical procedure lives only in target-repo history — specdrift's log cites "the spec-agent-cli canonical transform" as its reference — so every port re-derives it. ADR 0021 mechanized the sync of *declared* hook mirrors, but a pre-0.3.4 install (specdrift) carries mirror-shaped directories no `mirrors:` list covers, and nothing mechanical surfaced that gap outside an upgrade session. The evidence bar for kit changes (a friction repeated across targets) is met four times over.

# Decision

Two bounded moves:

- Ship the port procedure as a sixth installed skill, `templates/skills/okf-second-agent/SKILL.md` → `.claude/skills/okf-second-agent/SKILL.md`, delivered exactly like the other five (ADRs 0015, 0020): copied by both installers, seeded in the provenance manifest (nine entries), required by `verify-install`, classified by the harvest report, with a binding one-liner resident in the installed playbook's agent-config section. The skill carries: owner scoping, the playbook port (explicit session-start reads replacing `@` imports; guardrails restated honestly as policy-only where unenforced), hook mirroring with the `mirrors:` declaration, owner-managed skill adaptation, the repo-side parity guard, and the commit-and-log step.
- Add an undeclared-mirror advisory to `verify-install` and the SessionStart hook: a directory outside `.claude/hooks/` holding a byte-identical copy of a kit hook that no `mirrors:` entry covers draws a warning (verify-install) or session-start note (hook) recommending the declaration. Byte-identical matches only; detection never drives a sync. This narrows, and does not reverse, ADR 0021's rejection of auto-detection: what 0021 rejected was the *updater acting* on a detected guess, where a wrong guess overwrites real work. Here a wrong guess costs one advisory line, matching the unresolved-candidate reporting precedent (kit 0.3.3).

# Alternatives considered

- **Leave the procedure in the README's second-agent section only.** It already lives there in compressed form, but a README is not in an agent's working context during the port; the four dogfood repos each re-derived the details from another repo's history. The skill delivery exists precisely for episodic procedures too long to keep resident (ADR 0015).
- **Mechanize the port (installer flag that writes `AGENTS.md` and mirrors).** Rejected: the playbook port is judgment work — per-agent phrasing, honest guardrail restatement, the owner's scoping call — the same reason ADR 0020 rejected a scripted adoption converter and ADR 0021 rejected syncing skills.
- **Detect mirrors and sync them without a declaration.** Already rejected in ADR 0021; nothing here reopens it. The advisory keeps declaration as the only path to mechanical sync.
- **Advisory in verify-install only, not the SessionStart hook.** Rejected on evidence: verify-install runs at install/upgrade time, but the gap this closes (specdrift's undeclared mirrors) sits in an already-installed repo where only session start reliably reaches the owner.

# Consequences

- The port procedure becomes kit-owned and versioned; future harvest findings about second-agent friction land in one skill file instead of prose scattered across README, upgrade-skill step 4, and target logs.
- The kit-managed file set grows to nine; installers, `verify-install`, the harvest report, the manifest seed count, and the smoke assertions must stay in sync (same maintenance surface every skill addition has carried).
- Pre-0.3.4 installs with undeclared mirrors now hear about it every session until the mirror is declared or removed — mild nag pressure by design, silenced by one map edit.
- ADR 0021's consequences section gains an amendment noting the detection-for-advice/detection-for-sync distinction so the two decisions read consistently.

# Rollback / revisit trigger

If the advisory misfires in practice (a target's own script legitimately byte-identical to a kit hook in an undeclared directory — not observed in any dogfood repo), tighten the probe or drop the hook-side note, keeping verify-install's. If the skill goes unused by the next two second-agent ports (owners keep re-deriving instead), fold its content back into the README and retire the skill through both installers. Reverting takes removing the skill from the installer/verify/harvest/manifest wiring and deleting the advisory blocks; installed copies in targets are inert files an updater run can retire.
