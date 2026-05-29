# Three-tiered verification strategy

Verification runs in three escalating tiers: (1) **unit tests** with mock drivers,
(2) **null-impl meaningful-failure smoke tests**, and (3) **live-VM shake-down**.
We tier it this way so that the fast, hermetic checks (tiers 1–2) run anywhere with
no VM and catch most regressions, while the slow, environment-heavy live-VM tier
runs last and gates only the things that genuinely require a real machine.

## Consequences

- Tiers 1–2 are VM-free and run independently of any external environment; they
  rely on the driver/runner indirection in ADR-0003 to substitute test doubles.
- The null-impl tier verifies that scenarios *fail meaningfully* against an
  implementation that does nothing — guarding against scenarios that pass
  vacuously.
- Extended F-keys (VNC F13–F19) gate **only** the live-VM tier; all upstream
  tasks execute regardless of F-key support.
- **Tier 3 has no surviving subject as of v1 (2026-05-29).** App-Spec v1 ships
  verified at tiers 1–2 only. The sole example implementation it was authored
  against — the Racket Modaliser — was abandoned and deleted on 2026-05-22
  (`APIAnyware-MacOS` commit `fab954b`); its impl, test suite, and `#lang
  app-spec` scenarios no longer exist, and the restart at `~/Development/Modaliser`
  is a Swift app with no scenarios yet. The harness itself is complete and green
  at tiers 1–2; re-establishing tier-3 coverage requires authoring scenarios and
  an impl-config for a live app and is deferred to a future workstream.

_Source: `LLM_STATE/core/memory.yaml` entry `app-spec-verification-is-three-tiered`._
