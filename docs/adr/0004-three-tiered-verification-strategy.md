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

_Source: `LLM_STATE/core/memory.yaml` entry `app-spec-verification-is-three-tiered`._
