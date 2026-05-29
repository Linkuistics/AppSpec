# 030-migrate-docs-and-readme

**Kind:** work

## Goal
Move the design/plan docs out of the legacy `docs/superpowers/` naming into
grove-standard homes, and fold `related-plans.md`'s project relationships into
`README.md`.

## Context
Decisions: Q6 (docs/superpowers migration) and Q7 (related-plans fold) in the
root brief's running log.

Docs migration:
- `git mv docs/superpowers/specs/2026-04-18-app-spec-design.md docs/specs/`
- `git mv docs/superpowers/plans/2026-04-18-app-spec-v1.md docs/plans/`
- Remove the now-empty `docs/superpowers/` directory.
- Fix internal cross-references: the spec and plan reference each other and
  themselves by old `docs/superpowers/...` paths; rewrite to the new
  `docs/specs/` and `docs/plans/` locations. `grep -rn "superpowers"` across the
  repo afterward must come back clean (except inside `.grove/` history if any).

README fold (`related-plans.md` → `README.md`):
- Merge the Parents (TestAnyware — VM driver/agent/vision pipeline consumed by
  testanyware-sdk) and Consumers (APIAnyware-MacOS — hosts per-app scenario
  suites + per-impl config) relationships into README's Architecture and/or
  Prerequisites sections.
- Resolve the `{{DEV_ROOT}}` template variable to plain prose (e.g. "a sibling
  checkout on disk, per the standard Linkuistics layout" — README already uses
  this framing for APIAnyware-MacOS).

## Done when
- `docs/specs/2026-04-18-app-spec-design.md` and
  `docs/plans/2026-04-18-app-spec-v1.md` exist; `docs/superpowers/` is gone.
- All internal references to the moved docs point at the new paths;
  `grep -rn superpowers` (outside `.grove/`) is clean.
- README.md states the upstream/downstream project relationships with no
  `{{DEV_ROOT}}` template var remaining.

## Notes
finish-app-spec-v1's bootstrap will read the plan from `docs/plans/`, so this
leaf must land before the hand-off (040). `related-plans.md` itself is deleted
with LLM_STATE in leaf 050 — only its *content* is salvaged here.
