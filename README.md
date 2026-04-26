# App-Spec

Cross-implementation operational specification and live-VM scenario
runner for native UI applications. Every app's implementations
(e.g. Modaliser-Racket today, future Modaliser-Swift, etc.) are
verified end-to-end against scenario suites authored in
`#lang app-spec`.

## Running

From AppSpec root, with APIAnyware-MacOS as a sibling on disk
(the standard Linkuistics layout):

```
./run.sh                                       # all modaliser scenarios, default impl
./run.sh --filter lifecycle                    # only matching scenarios
./run.sh --impl /path/to/your-impl.rkt run /path/to/your/scenarios/
```

Under the hood the wrapper invokes:
`racket runner/main.rkt --impl <impl-config> run <scenarios-dir>`.
The runner adds the AppSpec root to `current-library-collection-paths`
so `#lang app-spec` resolves without global package installation.

## Contracts

Every implementation under test MUST satisfy:

1. **Structured log format** — see the per-app `logging-contract.md`
   colocated with that app's scenarios (e.g.
   `APIAnyware-MacOS/knowledge/apps/modaliser/logging-contract.md`).
2. **Observable state** — see the per-app `observable-state.md`
   colocated likewise.
3. **Test config compatibility** — `config/test-config.scm` must load
   unchanged.

## Architecture

App-Spec was extracted from `Modaliser-Racket/spec/` into a top-level
peer of TestAnyware on 2026-04-26. Per-app scenario suites and
contract docs live with each app under
`APIAnyware-MacOS/knowledge/apps/<app>/`; per-impl `--impl` config
files live with each implementation (for the Racket-OO target, under
`APIAnyware-MacOS/generation/targets/racket-oo/apps/<app>/`). AppSpec
itself contains only the language, runner, SDK helpers, config schema,
and self-tests.

## Prerequisites

- Racket CS 8+
- `testanyware` CLI (TestAnyware) on `$PATH`
- macOS VM image registered with `tart` (see TestAnyware README)
- TestAnyware extended F-keys (F13–F19) support landed — required for
  any modal/leader-key scenario.
