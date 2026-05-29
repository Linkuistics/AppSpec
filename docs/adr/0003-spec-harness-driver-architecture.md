# Spec harness / driver architecture

The spec harness is built around a **driver**: a struct of functions installed
via the `current-driver` parameter, so scenarios are written once and run against
any implementation by swapping the driver. Four interlocking decisions give the
harness its shape, recorded here together because they only make sense as a set.

## Decisions

- **Cross-file scenario registration via a shared parameter.** Scenarios in
  separate files register into a shared `scenario-registry` parameter, accessed
  through `get-scenarios` / `reset-scenarios!`. This is forced by Racket hygiene:
  a custom `#%module-begin` *cannot* inject `define-syntax` bindings into user
  code in the same module, so a parameter-threaded registry replaces the
  identifier-injection approach that would otherwise be natural.

- **Unit-test isolation through `current-testanyware-runner`.** Every
  testanyware-sdk operation routes through the `current-testanyware-runner`
  parameter. Unit tests substitute a test double; only the live-VM tier installs
  the real runner. This is what lets the upper verification tiers run VM-free
  (see ADR-0004).

- **Asymmetric verb defaults by verb type.** `make-driver` defaults *input* verbs
  (`press`, `type`, `chord`, `click-at`, `move-mouse`) and *control* verbs
  (`kill-impl!`, `restart-impl!`) to "unset" raisers — calling them without an
  installed driver is a fast-fail error. *Observation* and *state* verbs
  (`log-tail`, `ocr-fn`, `ax-fn`, `read-mru`, `read-file`, …) default to inert
  no-ops. Rationale: a test that drives input but never installed a driver is a
  bug and should fail loudly, whereas a test exercising only a subset of
  observations should be able to omit the rest safely.

- **Polling delegates to `driver-wait-fn`, never `sleep`.** All polling verbs
  (`wait-for-log`, `wait-for-ocr`) delegate to the driver's `driver-wait-fn`
  field rather than calling `sleep` directly. Unit tests stub it to a no-op for
  instant, deterministic runs; the live runner supplies a real poll loop.

_Sources: `LLM_STATE/core/memory.yaml` entries
`module-begin-cannot-inject-identifiers-into-user-scope`,
`current-testanyware-runner-isolates-unit-tests-from-vm`,
`spec-driver-defaults-asymmetric-by-verb-type`,
`spec-harness-polling-routes-through-driver-wait-fn`._
