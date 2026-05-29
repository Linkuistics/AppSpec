# migrate-LLM_STATE-to-grove — brief

## Goal
Replace the repo's legacy `LLM_STATE/` state convention (the "superpowers"
plan/state system: `phase.md`, `backlog.yaml`, `memory.yaml`,
`related-plans.md`) with grove. The live work in `backlog.yaml` becomes a
`.grove/` task tree; anything durable in `memory.yaml` / `related-plans.md` is
salvaged into standard artifacts (`CONTEXT.md`, ADRs, the brief chain); then
`LLM_STATE/` is deleted. The repo is grove-driven from here on.

## Done when
- Durable knowledge salvaged into standard artifacts: `CONTEXT.md`, four ADRs,
  `docs/notes/racket-gotchas.md`, README relationships (leaves 010–030).
- The remaining app-spec-v1 work handed to a separate `finish-app-spec-v1` grove
  (leaf 040), not absorbed here.
- `LLM_STATE/` deleted in a focused commit (leaf 050).
- `.grove/` deleted and the branch merged at Finish.

## Decomposition
Five work leaves, sequenced so every salvage/forward completes before the source
is deleted (050 is the point of no return):
- **010** — salvage decisions: `CONTEXT.md` glossary + ADRs 0001–0004.
- **020** — salvage gotchas: `docs/notes/racket-gotchas.md` + run.sh comment.
- **030** — migrate `docs/superpowers/` → `docs/specs/` + `docs/plans/`; fold
  `related-plans.md` into README. Must precede 040 (new grove reads the plan).
- **040** — `grove start finish-app-spec-v1` + forward 3 pending-work
  observations via `inbox-add`. Must precede 050 (forwards source from LLM_STATE).
- **050** — delete `LLM_STATE/`; verify no dangling references. Last.

All leaves are **work** tasks — the grilling (this bootstrap session) already
settled every mapping decision; nothing downstream needs further grilling.

## Pointers
- Legacy state being migrated: `LLM_STATE/core/{phase,related-plans}.md`,
  `LLM_STATE/core/{backlog,memory}.yaml`
- Old planning artifacts: `docs/superpowers/plans/2026-04-18-app-spec-v1.md`,
  `docs/superpowers/specs/2026-04-18-app-spec-design.md`

## Decisions (running log)
- **End state = full replace.** grove supersedes LLM_STATE. Translate live work
  from `backlog.yaml` into the tree, salvage durable knowledge into standard
  artifacts, then delete `LLM_STATE/` entirely. (Q1, 2026-05-29)
- **Scope = migration-only.** This grove does the migration and finishes
  cleanly; the remaining app-spec-v1 work (Tasks 25–26 + `spec-v1-log-tailer`
  blocker) goes into a *separate* grove rather than being absorbed here — it is
  gated on external TestAnyware work and would block this grove from merging.
  (Q2, 2026-05-29)
- **App-spec hand-off = `grove start finish-app-spec-v1` now.** Materialize the
  new grove (worktree + branch) as part of this migration; its tree is grilled
  in its own bootstrap session, not here. Implies the app-spec plan doc must
  survive in a form that grove's bootstrap can read. (Q3, 2026-05-29)
- **memory.yaml salvage = tiered.** Real decisions → ADRs (sparing); pure
  gotchas → one design-notes doc; a small fresh `CONTEXT.md` glossary of the
  ubiquitous language; pending-work entries forwarded to finish-app-spec-v1 via
  `inbox-add`; obsolete location pointer dropped. Per-entry table pending
  confirmation. (Q4, 2026-05-29)
- **memory.yaml per-entry table approved as-is.** 4 ADRs (0001 self-contained
  `#lang` registration; 0002 scenarios-as-source; 0003 spec-harness/driver
  architecture folding entries 4+5+9+10; 0004 three-tiered verification); one
  notes doc `docs/notes/racket-gotchas.md` (entries 11–14, + a run.sh
  flag-order comment); fresh `CONTEXT.md` glossary; forward entries 1, 3, and
  the status half of 2 to finish-app-spec-v1; drop the location half of 2.
  (Q5, 2026-05-29)
- **docs/superpowers migrated out of legacy naming.** `specs/` →
  `docs/specs/`, `plans/` → `docs/plans/`; drop the `docs/superpowers/`
  directory; fix internal cross-references. finish-app-spec-v1 reads the plan
  from `docs/plans/`. (Q6, 2026-05-29)
- **related-plans.md folded into README.md.** Merge Parents/Consumers into
  README's Architecture/Prerequisites; resolve the `{{DEV_ROOT}}` template var
  to plain prose. No new file. (Q7, 2026-05-29)
