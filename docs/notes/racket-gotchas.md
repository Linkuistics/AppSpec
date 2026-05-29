# Racket gotchas

A re-mistake guard for App-Spec's Racket code. Each entry: the gotcha, where it
bites, and the workaround. Not prose — keep it terse.

## Strict left-to-right flag parsing (`racket/cmdline`)

`racket/cmdline` parses flags left-to-right and stops at the first positional
argument. A flag placed *after* a positional arg fails to parse.

- **Bites:** `run.sh` invoking `racket runner/main.rkt --impl <impl> run
  <scenarios>`. `--impl` must precede the `run` subcommand.
- **Workaround:** caller-supplied extras slot *between* the default `--impl`
  value and the `run` subcommand. See the comment in `run.sh`.

## Relative requires for direct execution

Files in `AppSpec/tests/` and scenario `helpers/` directories use relative-path
`require`, not collection paths.

- **Bites:** anywhere you want to run a single file with plain `racket file.rkt`.
- **Workaround:** relative requires let those files run directly with no
  collection-path manipulation or `raco` setup. (The `#lang app-spec` resolution
  for scenarios is separate — see ADR-0001.)

## Config DSL has no `action` form

`config.scm` DSL provides only `(key K LABEL THUNK)`, `(group K LABEL …)`, and
`(selector K LABEL 'prop val …)`.

- **Bites:** porting plan-doc snippets that use `(action LAMBDA 'label …)` — that
  form does not exist; the plan examples were aspirational.
- **Workaround:** port the *intent*, not the literal text. Express actions via
  `key` THUNKs.

## `activate-app` (not `launch-app`) triggers `[launch]` log events

`util.rkt` emits `[launch] bundle` / `[launch] path` events through the
`activate-app` code path.

- **Bites:** scenarios expecting `[launch]` events won't get them from a bare
  `launch-app`.
- **Workaround:** the `launch-bundle` / `launch-path` helpers in
  `config/test-config.scm` call `activate-app` with the appropriate arg to
  exercise both event variants (per the modaliser `logging-contract.md`).
