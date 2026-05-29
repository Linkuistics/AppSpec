# 010-gitignore-verification

**Kind:** work

## Goal
Complete plan Task 25: ensure the spec/impl per-run artifact directories are
git-ignored so a scenario run never dirties `git status`. Inbox note flagged
this as "likely a no-op (modaliser `artifacts/` already covered)" — verify, and
add only what's missing.

## Context
- Plan Task 25 (`docs/plans/2026-04-18-app-spec-v1.md`).
- Patterns the plan expects:
  - `APIAnyware-MacOS/.gitignore`: `knowledge/apps/modaliser/artifacts/`
  - `AppSpec/.gitignore`: `.scenario-run-*/`
- Note the worktree layout: `AppSpec/` is this repo's root; the
  `APIAnyware-MacOS/` artifacts ignore lives in *that* repo's `.gitignore`.

## Done when
- `AppSpec/.gitignore` ignores `.scenario-run-*/` (and the modaliser
  `artifacts/` dir is confirmed ignored in its own repo).
- A dry-run that creates an artifact dir leaves `git status` clean (the
  artifact dir does not appear as untracked).

## Notes
Smallest leaf; likely a one-line append or a pure confirmation. If already
fully covered, record that finding and retire with no code change.

## Outcome (2026-05-29)
Plan Task 25's expected patterns were **stale** — verified against the code:
- **Spec side:** the runner writes failure-capture artifacts to
  `spec/artifacts/<name>-<ts>/` (`runner/lifecycle.rkt`
  `default-artifact-root`), *not* the plan's `.scenario-run-*/`. Added the real
  pattern `spec/artifacts/` to `AppSpec/.gitignore`. Verified: a runner-shaped
  artifact dir no longer dirties `git status`; `git check-ignore` matches at
  `.gitignore:6`.
- **Impl side:** `APIAnyware-MacOS/.gitignore` already ignores
  `knowledge/apps/*/artifacts/` (broader than the plan's
  `knowledge/apps/modaliser/artifacts/`). No change needed; it's a separate
  repo, out of this grove's scope. The plan's idea of adding an
  `APIAnyware-MacOS/...` line to *AppSpec*'s gitignore assumed a combined tree
  that doesn't exist — correctly skipped.
