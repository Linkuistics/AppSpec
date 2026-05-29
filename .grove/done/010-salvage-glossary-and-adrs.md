# 010-salvage-glossary-and-adrs

**Kind:** work

## Goal
Salvage the durable *decision* knowledge from `LLM_STATE/core/memory.yaml` into
grove-standard artifacts: a fresh `CONTEXT.md` glossary of the ubiquitous
language, and four ADRs under `docs/adr/`.

## Context
Source: `LLM_STATE/core/memory.yaml`. Disposition table approved in the root
brief's running log (Q5). This leaf handles the glossary + ADR tier only;
gotchas go to leaf 020, forwards to leaf 040.

ADRs to author (use `.claude/skills/grove/ADR-FORMAT.md`):
- **ADR-0001 — `#lang app-spec` self-contained registration.** Registered via a
  `current-library-collection-paths` push at runner startup, *not* `raco pkg
  install`. Trade-off: keeps `AppSpec/` self-contained and extraction-ready vs.
  global package install. (memory entry `lang-app-spec-registered-...`)
- **ADR-0002 — Scenarios authored as `#lang app-spec` source, not data.** Each
  scenario is a Racket source file, not YAML/data. (entry
  `app-spec-scenarios-use-lang-app-spec`)
- **ADR-0003 — Spec harness / driver architecture.** Folds four memory entries:
  driver = struct of functions + `current-driver` parameter; cross-file
  scenario registration via a shared `scenario-registry` parameter (forced by
  Racket hygiene — `#%module-begin` cannot inject identifiers into user scope);
  unit-test isolation routed through `current-testanyware-runner`; asymmetric
  verb defaults (input/control verbs fail-fast "unset" raisers, observation/
  state verbs inert no-ops); polling verbs delegate to `driver-wait-fn` rather
  than calling `sleep`. (entries `module-begin-...`,
  `current-testanyware-runner-...`, `spec-driver-defaults-asymmetric-...`,
  `spec-harness-polling-routes-through-driver-wait-fn`)
- **ADR-0004 — Three-tiered verification strategy.** Unit tests (mock drivers,
  VM-free) → null-impl meaningful-failure smoke (VM-free) → live-VM shake-down.
  Extended F-keys (VNC F13–F19) gate only the live-VM tier. (entry
  `app-spec-verification-is-three-tiered`)

`CONTEXT.md` (use `.claude/skills/grove/CONTEXT-FORMAT.md`): author a small
glossary of the actual ubiquitous language — terms like *scenario*, *impl*,
*driver*, *harness*, and *three-tiered verification* (the named concept; tiers'
detail belongs in ADR-0004, not here). Glossary stays free of implementation
detail. Optionally add the canonical grove `Inbox`/`Seed`/`Drain`/`grove-meta
branch` entries since this repo now uses the convention.

## Done when
- `CONTEXT.md` exists at repo root with the ubiquitous-language glossary.
- `docs/adr/0001`–`0004-*.md` exist, each citing its source memory entry as
  rationale.
- These memory entries are accounted for (they will be deleted with LLM_STATE in
  leaf 050; do not delete here).

## Notes
These are *retroactive* ADRs documenting already-built code (Tasks 1–24). Their
value is preserving the "why" before `LLM_STATE/` is deleted — write the
rationale sections from the memory-entry bodies, which already state the
trade-offs.
