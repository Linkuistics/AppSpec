# finish-app-spec-v1 — brief

## Goal
Finish App-Spec v1: complete the final remaining tasks of the 26-task plan
(`docs/plans/2026-04-18-app-spec-v1.md`). Tasks 1–24 are done; this grove
delivers Task 25, the **spec-v1-log-tailer** blocker that gates the live-VM
shake-down, and Task 26's verification (VM-free and live-VM).

## Done when
- Task 25 — `.gitignore` covers the spec/impl per-run artifact dirs (verified;
  likely already covered).
- The spec runner has a **real log tailer** installed as `driver-log-tail`,
  with unit coverage.
- Task 26 VM-free verification (steps 1, 2, 3, 5) is green.
- Task 26 live-VM shake-down (step 6) passes — gated externally on TestAnyware
  F13–F19 keymap (TestAnyware Task 8) landing.

## Decomposition
Flat, dependency-ordered (chosen at bootstrap over a nested Task-26 node — the
remaining work is small and linear):
- `010` gitignore verification — Task 25; independent, likely a no-op.
- `020` spec log-tailer — the blocker; must land before any live-VM step.
- `030` Task-26 VM-free verification — steps 1, 2, 3, 5; no VM, no log-tailer.
- `040` Task-26 live-VM shake-down — step 6; depends on `020` **and** the
  external TestAnyware keymap gate.

## Pointers
- ADRs a session here must read: `docs/adr/0003-spec-harness-driver-architecture.md`
  (driver injection — the log-tailer plugs in here as `driver-log-tail`),
  `docs/adr/0004-three-tiered-verification-strategy.md` (the three tiers Task 26
  verifies). `0001`/`0002` are background on the `#lang app-spec` design.
- Glossary terms in play: Harness, Driver, Runner, Three-tiered verification,
  Contract (see `CONTEXT.md`).
- Plan: `docs/plans/2026-04-18-app-spec-v1.md` (Tasks 25–26).
- Design: `docs/specs/2026-04-18-app-spec-design.md`.

## Notes
- **External gate (Task 26 step 6 only):** `vncdotool` + RoyalVNCKit sends
  XK_F18 correctly, but TestAnyware's `PlatformKeymap` covered only F1–F12 —
  keys ≥F13 are silently dropped before reaching CGEvent. Fix is in TestAnyware
  (filed there as Task 8, 2026-04-18): extend `PlatformKeymap` to F13–F19 and
  rebuild the release binary. All upstream leaves (`010`–`030`) run
  independently of this gate.
- **Post-v1 deferral:** the `launch-impl-again!` driver verb (the definitive
  single-instance test — spawn a second invocation, assert no duplicate
  `[lifecycle] startup`) does not exist yet. Single-instance scenario 03 uses a
  1.5s idle pid-stability window as an indirect proxy for v1. Re-captured to the
  `app-spec-post-v1-hardening` grove inbox; out of scope here.
