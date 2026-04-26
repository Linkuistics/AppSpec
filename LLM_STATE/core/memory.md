# Memory

## VNC extended F-keys need TestAnyware keymap extension
`vncdotool`+RoyalVNCKit sends XK_F18 (0xFFCF) correctly, but
TestAnyware's PlatformKeymap covered only f1–f12. Keys ≥F13 are
silently dropped before reaching CGEvent. Extend PlatformKeymap to
f13–f19 and rebuild the testanyware release binary to enable extended F-key
testing in the VM.

## App-Spec is at top-level `AppSpec/` (extracted 2026-04-26 from Modaliser-Racket)
Automated cross-implementation VM verification suite for every app feature.
Design doc: `AppSpec/docs/superpowers/specs/2026-04-18-app-spec-design.md`.
Implementation plan at `AppSpec/docs/superpowers/plans/2026-04-18-app-spec-v1.md`
(26 tasks); Tasks 1–24 complete; Tasks 25–26 queued; next is Task 25
(.gitignore audit — likely verify-only). 12 registered scenarios across
modal/, choosers/, launch/, windows/. Task 26 live-VM shake-down gated on
TestAnyware Task 8 and spec-v1-log-tailer.

## `launch-impl-again!` driver verb not yet implemented
Single-instance scenario 03 uses 1.5 s idle pid-stability as an indirect
proxy. Definitive test (spawn second invocation, assert no duplicate
`[lifecycle] startup` log entry) requires `launch-impl-again!` — not yet
exposed in the spec driver.

## `#%module-begin` cannot inject identifiers into user scope
Racket hygiene prevents custom `#%module-begin` from making `define-syntax`
forms visible to user code in the same module. Cross-file registration uses a
shared parameter (`scenario-registry`) with `get-scenarios`/`reset-scenarios!`
accessors instead.

## `current-testanyware-runner` isolates unit tests from VM
All testanyware-sdk modules route operations through `current-testanyware-runner`.
Unit tests substitute a test double; only the live-VM tier uses the real driver.

## App-Spec verification is three-tiered
Unit tests with mock drivers → null-impl meaningful-failure smoke tests →
live-VM. Extended F-keys (VNC F13–F19) gate only the live-VM tier (Task 26
Step 6); all upstream tasks execute independently.

## `#lang app-spec` registered via `current-library-collection-paths`
Push approach: no global `raco pkg install`. Keeps `AppSpec/` self-contained
and packaging-ready when a non-APIAnyware consumer pulls on the seam.

## App-Spec scenarios use `#lang app-spec`
Each scenario is a Racket source file, not YAML/data. Per-app suites live
under `APIAnyware-MacOS/knowledge/apps/<app>/scenarios/`. Modaliser's were
extracted from the original `Modaliser-Racket/spec/scenarios/` location on
2026-04-26.

## Spec driver defaults asymmetric by verb type
`make-driver` defaults input verbs (`press`, `type`, `chord`, `click-at`,
`move-mouse`) and control verbs (`kill-impl!`, `restart-impl!`) to "unset"
raisers — calling them without installing a driver is a fast-fail error.
Observation and state fns (`log-tail`, `ocr-fn`, `ax-fn`, `read-mru`,
`read-file`, etc.) default to inert no-op returns — safe to omit in unit tests
that only exercise a subset of the harness.

## Spec harness polling routes through `driver-wait-fn`
All polling verbs (`wait-for-log`, `wait-for-ocr`) delegate to the
`driver-wait-fn` field rather than calling `sleep` directly. Unit tests stub
`driver-wait-fn` to a no-op; the live runner supplies a real poll loop.

## `racket/cmdline` parses flags left-to-right strictly
`--impl` flag must precede the `run <scenarios>` subcommand in `AppSpec/run.sh`.
Placing a flag after a positional argument causes a parse failure. Caller-supplied
extras must slot between the default `--impl` value and the `run` subcommand.

## Spec files use relative requires
`AppSpec/tests/` and `APIAnyware-MacOS/knowledge/apps/modaliser/scenarios/helpers/` files use relative-path `require`
(not collection paths), enabling plain `racket file.rkt` execution without
collection-path manipulation or `raco` setup.

## Config DSL has no `action` form
`config.scm` DSL (the user-facing app config language, e.g. for Modaliser) uses
`(key K LABEL THUNK)`, `(group K LABEL …)`, and `(selector K LABEL 'prop val …)`.
There is no `(action LAMBDA 'label …)` form — plan doc examples were aspirational.
Port intent, not literal text, when adapting plan snippets.

## `activate-app` (not `launch-app`) triggers `[launch]` log events
`util.rkt` (in the modaliser impl) emits `[launch] bundle`/`[launch] path`
events through the `activate-app` path. `AppSpec/config/test-config.scm` uses
`launch-bundle` and `launch-path` helpers that call `activate-app` with the
appropriate arg to exercise both event variants as required by
`APIAnyware-MacOS/knowledge/apps/modaliser/logging-contract.md`.
