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
