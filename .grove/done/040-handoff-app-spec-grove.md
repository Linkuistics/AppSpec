# 040-handoff-app-spec-grove

**Kind:** work

## Goal
Stand up the separate grove that will carry the remaining app-spec-v1 work, and
forward the three pending-work observations from `memory.yaml` to it.

## Context
Decisions: Q2 (migration-only scope), Q3 (`grove start finish-app-spec-v1`
now), Q5 (forward entries 1, 3, status-half-of-2).

Two parts:

1. **Create the grove.** Run `grove start finish-app-spec-v1` to materialize its
   worktree + branch off the default branch. NOTE: `grove start` opens a
   bootstrap session — that grove's task tree is grilled *there*, in its own
   session, not in this one. If running `grove start` from inside a session is
   awkward (it may launch an interactive harness), instead instruct the operator
   to run it in a fresh terminal; the inbox forwards below do not depend on the
   grove existing yet (`inbox-add` addresses future groves too).

2. **Forward the pending-work observations** via
   `grove-llm inbox-add --to=finish-app-spec-v1 --body=...` (one call each):
   - **F13–F19 keymap gate.** `vncdotool`+RoyalVNCKit sends XK_F18 correctly but
     TestAnyware's PlatformKeymap covered only f1–f12; keys ≥F13 are dropped
     before CGEvent. Extend PlatformKeymap to f13–f19 and rebuild the testanyware
     release binary. Gates Task 26 Step 6 (live-VM shake-down). (memory entry
     `vnc-extended-f-keys-need-testanyware-keymap-extension`)
   - **`launch-impl-again!` driver verb not implemented.** Single-instance
     scenario 03 uses a 1.5s idle pid-stability proxy; the definitive test
     (spawn second invocation, assert no duplicate `[lifecycle] startup`) needs a
     new `launch-impl-again!` driver verb. Post-v1 hardening. (entry
     `launch-impl-again-driver-verb-not-yet-implemented`)
   - **Status pointer.** app-spec-v1 Tasks 1–24 complete; Tasks 25–26 remaining.
     Plan now at `docs/plans/2026-04-18-app-spec-v1.md`; design at
     `docs/specs/2026-04-18-app-spec-design.md`. Also the `spec-v1-log-tailer`
     blocker (from `backlog.yaml`): real log-tailer for the spec runner, gates
     Task 26 live-VM. (status half of entry `app-spec-is-at-spec-...` +
     `backlog.yaml` task `spec-v1-log-tailer`)

## Done when
- The `finish-app-spec-v1` grove exists (worktree + branch), OR the operator has
  been clearly handed the one command to create it.
- Three observations are queued in the `finish-app-spec-v1` inbox (verify with
  `grove inbox show finish-app-spec-v1`).

## Notes
Must land before leaf 050 — the forwards capture content from `memory.yaml` /
`backlog.yaml`, which leaf 050 then deletes. Also depends on leaf 030 having
moved the plan to `docs/plans/` so the status forward points at a live path.
