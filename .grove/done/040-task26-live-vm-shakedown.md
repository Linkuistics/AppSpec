# 040-task26-live-vm-shakedown

**Kind:** work

## Goal
Run plan Task 26 Step 6: the tier-3 live-VM shake-down (ADR-0004). Bundle the
Modaliser-Racket impl, upload it to a live macOS VM, and run a real scenario
end-to-end against it through the runner — proving the whole stack (driver,
log-tailer, testanyware-sdk, scenario DSL) works against a real impl.

## Context
- Plan Task 26 Step 6 (`docs/plans/2026-04-18-app-spec-v1.md`) — the exact
  command sequence (vm-start, bundle, upload, `run.sh --filter lifecycle-startup`).
- **Depends on `020`** (the log-tailer must be installed as `driver-log-tail`
  before live log assertions can pass).
- **External gate — TestAnyware F13–F19 keymap (TestAnyware Task 8):**
  TestAnyware's `PlatformKeymap` covered only F1–F12; keys ≥F13 (e.g. XK_F18)
  are silently dropped before reaching CGEvent. Any modal/leader-key scenario
  needs this. The fix lives in the TestAnyware project (extend `PlatformKeymap`
  to F13–F19, rebuild the release binary). **Do not start this leaf's
  leader-key scenarios until that has landed.** A lifecycle-startup scenario
  (no F-keys) can be shaken down first to de-risk the rest of the pipeline.

## Done when
- The runner runs at least the `lifecycle-startup` scenario green against a live
  VM impl (validates bundle → upload → launch → log-tail → assertion).
- Once the TestAnyware keymap gate has landed, a leader-key/modal scenario also
  passes (or the gate is confirmed still open and this is split into a follow-up).

## Notes
- This is the only VM-gated leaf; environment setup (tart VM, `TESTANYWARE_VM_ID`,
  accessibility grants) is part of the work.
- If the keymap gate is still open when this leaf is picked, shake down the
  non-F-key scenarios, record the gate as still-blocking, and leave a follow-up
  leaf for the F-key scenarios rather than blocking the whole grove on TestAnyware.
