# Scenarios are authored as `#lang app-spec` source, not data

Each scenario is a Racket source file in `#lang app-spec`, not a YAML/JSON data
file interpreted by the runner. We chose source-as-spec because scenarios need
the full expressive range of a language — bindings, helpers, composition, relative
`require`s — which a static data format cannot give without reinventing one.
Scenarios live with their app under
`APIAnyware-MacOS/knowledge/apps/<app>/scenarios/`.

## Consequences

- A scenario can `require` shared helpers and be run directly with `racket
  file.rkt` (see ADR-0001 for collection-path resolution).
- The `#lang` reader/expander is the spec's contract surface; changing scenario
  capabilities means changing the language, not a schema.

_Source: `LLM_STATE/core/memory.yaml` entry `app-spec-scenarios-use-lang-app-spec`._
