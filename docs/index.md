---
okf_version: "0.1"
kit_version: "0.3.0"
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
