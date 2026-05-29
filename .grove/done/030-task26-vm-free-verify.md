# 030-task26-vm-free-verify

**Kind:** work

## Goal
Run the VM-free portion of plan Task 26 (success-criteria verification): the
checks that need neither a live VM nor the log-tailer. Confirm each passes, fix
any that don't.

## Context
Plan Task 26 (`docs/plans/2026-04-18-app-spec-v1.md`). The VM-free steps:
- **Step 1** — no upward `require` from the spec collection into impl source
  (`rg 'require\s+"\.\./\.\.' ...` returns nothing; only the modaliser impl
  config may reference modaliser paths, via `find-system-path`).
- **Step 2** — `tests/run-all.sh` all green (rc=0, every test file OK).
- **Step 3** — null impl produces a *readable* meaningful-failure (error names
  `/does/not/exist/NullModaliser.app` or VM-unreachable, not an undefined-variable
  stack trace). This is the tier-2 check of the three-tiered strategy (ADR-0004).
- **Step 5** — the modaliser app's own full suite still green (run from
  `APIAnyware-MacOS/`: `./generation/targets/racket-oo/apps/modaliser/tests/run-all.sh`).
- Step 4 (mechanical extraction) is already done (2026-04-26); Step 6 (live-VM)
  is leaf `040`.

## Done when
- Step 1 reports `OK: no upward require`.
- Step 2: `tests/run-all.sh` rc=0, all OK.
- Step 3: null-impl run fails with a user-readable message (not a raw stack trace).
- Step 5: modaliser app suite all green.

## Notes
Pure verification — ideally no code changes. If a check fails, that failure is
the work: triage and fix, then re-verify. Depends on `020` only if a self-test
covers the new log-tailer wiring (otherwise independent of `020`).
