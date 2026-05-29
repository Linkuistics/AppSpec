# 020-spec-log-tailer

**Kind:** work

## Goal
Implement a **real log tailer** for the spec runner — the blocker that gates
Task 26's live-VM shake-down. The live runner currently has no way to observe
the impl's `events.log` on the VM, so log-assertion verbs (`expect-log`,
`wait-for-log`, `expect-not-log`) have nothing real to read against a live impl.

## Context
- Driver injection seam: ADR-0003 (`docs/adr/0003-spec-harness-driver-architecture.md`).
  Harness verbs already consume a driver-injected `log-tail` field, so this is
  purely additive — **unit tests are unaffected**; only the live runner (Task 26)
  needs the real tailer.
- Relevant runner files (per the plan's File Structure):
  - `runner/harness-logs.rkt` — `expect-log` / `wait-for-log` / `expect-not-log`,
    which use the driver-injected `log-tail`.
  - `runner/driver.rkt` — the driver struct + `current-driver`; this is where a
    new `driver-log-tail` field is installed.
  - `testanyware-sdk/exec.rkt` — `gv-exec` (runs `testanyware exec` against the VM).
- Design from the migrated inbox note: a background **place** (or thread via
  `ffi/unsafe/os-thread`) that tails `events.log` on the VM via `testanyware
  exec`, accumulates lines into a shared buffer, and exposes a
  `make-log-tail-fn` constructor the runner driver installs as `driver-log-tail`.

## Done when
- A `make-log-tail-fn` constructor exists and the runner driver installs its
  result as `driver-log-tail`.
- It tails the VM's `events.log` (via `testanyware exec`), accumulating lines
  into a shared buffer that the log-assertion verbs read.
- Unit coverage for the tailer's line-accumulation/buffer logic (hermetic — no
  VM), following the repo's TDD pattern (failing test first).
- `tests/run-all.sh` stays green.

## Notes
- TDD (`superpowers:test-driven-development`): the live tail loop itself is
  VM-gated, but the buffer/accumulation/`make-log-tail-fn` wiring is unit-testable
  with a stubbed `gv-exec` runner — mirror the `current-testanyware-runner`
  injection pattern used in `testanyware-sdk/exec.rkt`'s tests.
- Decide `place` vs `ffi/unsafe/os-thread` during the work — capture the choice
  (and why) as an ADR only if it proves hard to reverse or surprising.
