---
okf_version: "0.2"
owner: Lila Brooks
deciders: [Lila Brooks]
---

# Knowledge bundle

This bundle governs the Claude Code OKF repo kit.

- [Goal](GOAL.md)
- [Specs](specs/index.md)
- [ADRs](adr/index.md)
- [Change log](log.md)
- [Source map](okf-map.yml)

## Why this bundle root declares no `kit_version`

The kit's release version lives in the root [`VERSION`](../VERSION) file, and
that is its only authority (ADR 0010). `kit_version` records *the kit release
that produced an install*, so it belongs in repos installed **from** this kit,
where both installers write it — never here. This repo was not produced by an
install, so the field would have nothing true to say.

Please do not add it back. It carried `0.3.0` for fourteen releases before anyone
noticed, precisely because no tool reads it here: the installers read the
*target's* stamp, `verify-install` only ever runs against an install target, and
the SessionStart hook stays silent when the field is absent. A second copy of the
release number is a drift surface with no reader. `make test` now asserts its
absence.

## The `status:` field in this bundle

`status:` here carries **ADR workflow state, not OKF 0.2 §5.4's lifecycle
vocabulary** (`draft` / `stable` / `deprecated`). ADRs use `proposed` and
`accepted` — the values `bash scripts/okf pending` and the SessionStart hook
both read, in this repo and in every repo installed from it.

This divergence is deliberate. It does not affect conformance: §11 requires only
parseable frontmatter, a non-empty `type`, and reserved filenames matching §8 and
§9, and `status` is in none of them. It is declared here because §5.4 defines its
vocabulary without saying how to treat a value outside it, so a consumer
filtering on lifecycle should not read `accepted` as "not stable".

Should machine-readable lifecycle ever be wanted alongside it, the non-breaking
route is a separate additive key — extra keys are what §4.1 protects — rather
than renaming these values and breaking the pending scan and the hook in every
installed repo.
