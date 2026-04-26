#!/usr/bin/env bash
# AppSpec/run.sh — Convenience wrapper for running the App-Spec
# scenario suite. The default `--impl` path assumes APIAnyware-MacOS
# is a sibling of AppSpec/ on disk (the standard Linkuistics layout);
# pass `--impl <path>` to override.
#
# `racket/cmdline` parses flags left-to-right and stops at the first
# positional arg, so `--impl ...` must appear before `run <scenarios>`.
# Caller-supplied extras are inserted between the default `--impl`
# flag and the `run` command so e.g. `./run.sh --vm v1 --filter modal`
# composes correctly.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

default_impl="$here/../APIAnyware-MacOS/generation/targets/racket-oo/apps/modaliser/modaliser-impl.rkt"
default_scenarios="$here/../APIAnyware-MacOS/knowledge/apps/modaliser/scenarios/"

exec racket "$here/runner/main.rkt" \
  --impl "$default_impl" \
  "$@" \
  run "$default_scenarios"
