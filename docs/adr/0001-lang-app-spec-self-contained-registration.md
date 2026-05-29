# `#lang app-spec` registered via `current-library-collection-paths`, not `raco pkg install`

The runner makes `#lang app-spec` resolvable by pushing the AppSpec root onto
`current-library-collection-paths` at startup, rather than installing AppSpec as
a global Racket package. We chose this because it keeps `AppSpec/` self-contained
and extraction-ready: the suite runs from a fresh checkout with no global package
state to install, pin, or clean up, which matters for a directory that was itself
extracted from a parent repo and may be packaged again later.

## Consequences

- `racket runner/main.rkt` works against the checkout in place; `run.sh` performs
  the push so callers never touch collection paths.
- No `raco pkg install` step in setup, CI, or onboarding.

_Source: `LLM_STATE/core/memory.yaml` entry
`lang-app-spec-registered-via-current-library-collection-paths`._
