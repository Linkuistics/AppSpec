# 020-salvage-gotchas-notes

**Kind:** work

## Goal
Salvage the pure *gotcha* knowledge from `memory.yaml` — the facts that prevent
re-mistakes but are neither decisions (ADRs) nor domain terms (glossary) — into
one design-notes doc, plus one code comment at the site where the sharpest
gotcha bites.

## Context
Source: `LLM_STATE/core/memory.yaml`, entries 11–14 in the root brief's
disposition table (Q5).

Create `docs/notes/racket-gotchas.md` capturing:
- **Strict left-to-right flag parsing** (`racket/cmdline`): `--impl` must precede
  the `run <scenarios>` subcommand; a flag after a positional argument fails to
  parse. Caller extras slot between the default `--impl` value and `run`. (entry
  `racket-cmdline-parses-flags-left-to-right-strictly`)
- **Relative requires** in `tests/` and scenario `helpers/`: relative-path
  `require` (not collection paths) enables plain `racket file.rkt` without
  collection-path setup. (entry `spec-files-use-relative-requires`)
- **Config DSL has no `action` form**: `config.scm` uses `(key K LABEL THUNK)`,
  `(group K LABEL …)`, `(selector K LABEL 'prop val …)` only. Plan-doc `action`
  examples were aspirational — port intent, not literal text. (entry
  `config-dsl-has-no-action-form`)
- **`activate-app` (not `launch-app`) triggers `[launch]` events**: `util.rkt`
  emits `[launch] bundle`/`[launch] path` via the `activate-app` path; the
  `launch-bundle`/`launch-path` helpers call `activate-app`. (entry
  `activate-app-not-launch-app-triggers-launch-log-events`)

Then add a brief comment in `run.sh` near the `--impl … run …` invocation noting
the strict flag-ordering constraint, so it's visible at the site that depends on
it.

## Done when
- `docs/notes/racket-gotchas.md` exists with the four gotchas above.
- `run.sh` carries a one-line comment about strict `--impl`-before-`run`
  ordering.

## Notes
Keep the notes doc terse — it's a re-mistake guard, not prose. Each entry: the
gotcha, where it bites, and the workaround.
