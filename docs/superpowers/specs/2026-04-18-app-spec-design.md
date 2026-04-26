# App-Spec: Cross-Implementation Operational Specification — Design

**Date**: 2026-04-18 (extracted to top-level `AppSpec/` on 2026-04-26)
**Status**: Implemented — Tasks 1–24 complete; spec system extracted to top-level `AppSpec/` per `~/Development/0-docs/designs/2026-04-26-apianyware-reorganise.md`

> **Post-hoc rename note (2026-04-26) — Spec-system extraction:** Paths
> and identifiers in this design have been rewritten for the move to
> top-level `AppSpec/`. The `app-spec` collection is now
> `app-spec`; `Modaliser-Racket/spec/` is now top-level `AppSpec/`;
> the modaliser app's scenarios live at
> `APIAnyware-MacOS/knowledge/apps/modaliser/scenarios/`; the modaliser
> impl now lives under
> `APIAnyware-MacOS/generation/targets/racket-oo/apps/modaliser/`.
> Dates, statuses, and numerics are unchanged.

## Context

The modaliser app (originally `Modaliser-Racket`, now folded into
`APIAnyware-MacOS/generation/targets/racket-oo/apps/modaliser/`) is a
second implementation of Modaliser (after the original Swift app).
Future implementations targeting additional languages supported by
APIAnyware are expected. The current test surface (`tests/test-*.rkt`,
28 files in the modaliser app) is rackunit-based and necessarily
Racket-specific; it cannot verify a Swift or future-language implementation.

The user has requested **full automated live VM verification of every
feature**, at behavioural depth (every user-visible behaviour, including UX
details like overlay auto-dismiss, chooser ESC-dismiss, MRU persistence
across restarts, single-instance guard).

This design establishes **App-Spec** as the single authoritative
operational specification of Modaliser's behaviour — designed to be
reusable across every implementation. Originally incubated inside
Modaliser-Racket as a `spec/` subdirectory; extracted on 2026-04-26 to
top-level `AppSpec/` (peer of TestAnyware). Per-app scenario content
colocates with the app inside APIAnyware-MacOS
(`knowledge/apps/<app>/scenarios/`); the spec-system tool is the
language-agnostic runtime shared across consumers.

## Goals

1. One test suite verifies any Modaliser implementation end-to-end in a
   live macOS VM.
2. Adding a new implementation's verification is zero scenario/runner
   code change — only a new `impls/<name>.rkt` module describing the
   binary and how to launch it.
3. Adding a feature test is a single new scenario file; every
   implementation picks it up on next repo pull.
4. The spec doubles as the porting-guide source of truth: conformance
   contracts (log format, observable state, test config) double as the
   documentation future implementers read first.

## Non-Goals

- **Headless / unit testing** of implementations. That remains each
  impl's local concern (Modaliser-Racket keeps its rackunit suite).
- **Performance benchmarking.** Scenarios assert correctness, not
  latency.
- **Multi-platform conformance** (Windows, Linux). Modaliser is
  macOS-bound by design (Cocoa, Accessibility, CGEvent).
- **A public / third-party stable API.** App-Spec is infrastructure
  shared between first-party implementations; no external consumer
  compatibility obligations.

## Approach

**Separate the spec from the runner.**

- **Scenarios are Racket programs.** Each scenario file is `#lang
  app-spec` — a full Racket dialect with domain-specific forms
  (`scenario`, `press`, `expect-log`, `expect-ocr`, …) layered on
  `racket/base`. Authors have the language's full power: `for` loops to
  parameterise, `cond` / `when` for conditional assertions, `define` for
  local helpers, `require` for shared helpers across scenario files.
  The DSL is the domain vocabulary — it makes the code read right — not
  a straitjacket. "Declarative where it can be, procedural where it
  must."
- **Runner is one tool in one language** (Racket). It reads scenarios,
  boots/attaches to a VM via `guivision`, executes the implementation
  under test per `impls/<name>.rkt`, runs the steps, reports pass/fail.
  Invocation in v1 is `racket AppSpec/runner/main.rkt run … --impl …`
  (wrapped by `AppSpec/run.sh`); post-extraction it becomes
  `raco app-spec run …` against an installed package — structure
  and flags unchanged.

**Racket all the way down.** Scenarios are `#lang app-spec`
programs; impl configs are `#lang app-spec/impl` modules using
the `impl` DSL form. No YAML, no `.rktd` data files — one syntax
family, consistent editing/reading experience, and impl configs can
compute values (path construction, env-dependent defaults) when needed.
- **Three conformance contracts** every implementation must satisfy:
  1. **Structured log format** (documented in `docs/logging-contract.md`).
  2. **Externally observable state** (MRU file format/location, lock
     file, XDG paths — documented in `docs/observable-state.md`).
  3. **Test config compatibility** — the `config.scm` in
     `config/test-config.scm` must load and exercise every feature
     correctly.

**Rationale for Racket as runner language**: Modaliser's test surface is
almost entirely `press → expect log → expect OCR → assert state`
sequences. Racket's `#lang` / macro facilities produce a tiny declarative
DSL that still has full language power when needed (loops, parameterised
scenarios, composable predicates). Python would work but requires
syntactic ceremony for the same patterns. The runner language does not
privilege any implementation's language — it talks to the impl under test
only through external interfaces (VNC, logs, AX, files).

## Directory Layout

Post-extraction (2026-04-26), App-Spec lives at top-level `AppSpec/`;
per-app spec content colocates with each app inside `APIAnyware-MacOS/`:

```
AppSpec/                              # NEW top-level repo (the spec-system tool)
├── README.md                         # Intent, impl conformance process
├── info.rkt                          # collection: app-spec
├── run.sh
├── config/
│   └── test-config.scm               # Exercises every feature; every impl loads this
├── app-spec/                         # collection root
│   ├── main.rkt                      # scenario DSL surface
│   ├── lang/reader.rkt               # `#lang app-spec`
│   └── impl/                         # impl DSL sub-collection
│       ├── main.rkt
│       └── lang/reader.rkt           # `#lang app-spec/impl`
├── runner/
│   ├── main.rkt                      # Entry point: racket AppSpec/runner/main.rkt run
│   ├── harness-{inputs,logs,observations,state}.rkt
│   ├── lifecycle.rkt                 # per-scenario setup/teardown, artifact capture
│   ├── driver.rkt
│   └── impl-config.rkt               # loader: binary path, log tap, env
├── testanyware-sdk/                  # Racket library — wrappers + platform helpers
│   ├── exec.rkt                      # gv-exec via testanyware
│   ├── input.rkt                     # gv-press / gv-type / gv-chord
│   ├── screenshot.rkt                # gv-screenshot, gv-ocr
│   ├── agent.rkt                     # gv-upload, gv-ax-snapshot, gv-health
│   └── macos-helpers.rkt             # grant-accessibility!, reset-tcc!, …
└── tests/                            # spec-system self-tests
    ├── impls/
    │   └── null.rkt                  # meaningful-failure stub
    └── test-*.rkt

APIAnyware-MacOS/
├── knowledge/apps/modaliser/         # spec content (language-agnostic)
│   ├── logging-contract.md
│   ├── observable-state.md
│   ├── scenarios/                    # `#lang app-spec` programs
│   │   ├── helpers/                  #   shared Racket modules (app lists, common setups)
│   │   ├── modal/
│   │   ├── choosers/
│   │   ├── windows/
│   │   ├── launch/
│   │   └── lifecycle/
│   └── artifacts/                    # gitignored — per-run captures
└── generation/targets/racket-oo/apps/modaliser/
    ├── main.rkt core/ ui/ ffi/ services/ lib/   # impl
    ├── tests/                                   # existing rackunit suite (headless)
    └── modaliser-impl.rkt                       # `#lang app-spec/impl` — runner config
```

**Design constraint: `AppSpec/` has no upward dependency on the
implementation under test's own source tree.** Scenarios don't
`require` impl-side code; the runner doesn't `require` anything outside
`AppSpec/`. Each implementation is treated as a black box driven
through its `<app>-impl.rkt` config file (e.g.,
`apps/modaliser/modaliser-impl.rkt`). This is what made the extraction
mechanical.

**Vendoring decision**: `testanyware-sdk/` ships inside `AppSpec/`.
Eventual further extraction to its own library + CLI surface is a
later decision driven by a second consumer, not now.

**Extraction (2026-04-26, complete)**: the spec system was extracted
from `Modaliser-Racket/spec/` to top-level `AppSpec/` via the
APIAnyware reorg (filesystem moves, not `git subtree split`; git
history was not preserved by explicit user decision). The reference
impl config (`modaliser-impl.rkt`) moved with the modaliser app into
APIAnyware-MacOS's apps tree. See
`~/Development/0-docs/designs/2026-04-26-apianyware-reorganise.md`.

**Deferred from v1** (added when a second implementation exists):

- `AppSpec/docs/architecture.md`
- `AppSpec/docs/porting-guide.md`

README links to both as "added when the second implementation lands" so
the gap is visible.

## Scenario DSL — shape and primitives

Each scenario file is `#lang app-spec`, a full Racket dialect with
domain verbs layered on `racket/base`.

**Example — straight-line scenario:**

```racket
#lang app-spec

(scenario "find-apps-via-leader"
  #:description "F18 f a → type query → Enter launches the app"

  (press 'F18)
  (expect-log #px"\\[modal\\] enter tree=global")

  (press "f")
  (expect-log #px"\\[modal\\] group key=f")

  (press "a")
  (expect-log #px"\\[chooser\\] open selector=\"Find Apps\"")
  (expect-ocr "Find app…")

  (type "safari")
  (expect-ocr "Safari")

  (press 'Return)
  (expect-log #px"\\[launch\\] bundle=com\\.apple\\.Safari")
  (expect-running-app "com.apple.Safari"))
```

**Example — parameterised scenario using a `for` loop:**

```racket
#lang app-spec

(require "../helpers/quick-launch.rkt")  ; defines quick-launch-bindings

(for ([binding (in-list quick-launch-bindings)])
  (define key      (binding-key binding))
  (define bundle   (binding-bundle binding))
  (define label    (binding-label binding))

  (scenario (format "quick-launch-~a" label)
    #:description (format "F18 ~a launches ~a" key label)
    (press 'F18)
    (press key)
    (expect-log (pregexp (format "\\[launch\\] bundle=~a" (regexp-quote bundle))))
    (expect-running-app bundle)))
```

**Example — conditional assertion:**

```racket
#lang app-spec

(require "../helpers/platform.rkt")

(scenario "chooser-dismiss-on-escape"
  (open-find-apps!)                    ; helper from another scenario file
  (expect-ocr "Find app…")

  (press 'Escape)
  (expect-log #px"\\[chooser\\] close reason=cancel")

  ;; Tahoe changed window-close animation timing; only assert the
  ;; post-animation invariant on supported versions.
  (when (at-least-macos? 26)
    (expect-no-ax #:role 'AXWindow #:title "Find app…")))
```

**Shared helpers** live under `APIAnyware-MacOS/knowledge/apps/modaliser/scenarios/helpers/` as plain
`#lang racket/base` modules that `(require "../../runner/harness.rkt")`
(or a narrower helper-API entry point). This is where app lists,
binding tables, common setup sequences, and reusable checks go.
Scenarios stay thin; helpers absorb repetition.

**DSL verbs** (v1 — extensible):

- **Input** — `press`, `type`, `chord` (e.g., `(chord 'cmd "space")`),
  `click-at`, `move-mouse`
- **Observation** — `expect-log`, `expect-ocr`, `expect-ax`,
  `expect-running-app`, `expect-file`, `expect-no-ax`,
  `expect-not-log` (bounded-time negative assertion)
- **Time / sync** — `wait-for-log`, `wait-for-ocr`, `wait` (explicit
  delay; discouraged in favour of wait-for-*)
- **State** — `read-mru`, `read-file`, `kill-impl!`, `restart-impl!`
  (for persistence-across-restart scenarios)
- **Grouping** — `scenario`, `scenario-group`, `before-each`,
  `after-each`

The verb set is deliberately small. Because scenarios are Racket
programs, growth pressure belongs in helpers and local `define`s, not
in the DSL itself. New verbs get added only when they can't be
expressed as a helper (e.g., anything crossing the runner/VM boundary).

## Conformance Contract 1 — Structured Log Format

Every Modaliser implementation MUST emit events to a known file in a
line-based format.

**File path**: `~/.cache/modaliser/events.log` (XDG; override via
`MODALISER_EVENTS_LOG` env var for testing convenience).

**Startup**: truncated on impl startup (lock file ensures single writer).

**Line format**: `[<module>] <event-name> <key>=<value> <key>=<value>\n`.

- Values with spaces or special chars: double-quoted,
  backslash-escaped (`"` → `\"`, `\` → `\\`, newline → `\n`).
- Numeric values: unquoted decimal.
- Boolean values: `true` / `false`.
- Flush after each line (no buffering).

**Required events** (non-exhaustive, full list in `logging-contract.md`):

- `[modal] enter tree=<name>`
- `[modal] exit reason=<user|watchdog|focus-loss>`
- `[modal] group key=<key>`
- `[chooser] open selector="<label>"`
- `[chooser] push query="<text>" results=<n>`
- `[chooser] close reason=<select|cancel|secondary-action>`
- `[launch] bundle=<bundle-id>`
- `[launch] url="<url>"`
- `[window] focus pid=<n> title="<text>"`
- `[window] move x=<n> y=<n> w=<n> h=<n>`
- `[mru] record key=<remember-key> id="<id>"`
- `[config] load path="<path>"`
- `[lifecycle] startup`
- `[lifecycle] shutdown reason=<signal|menu|error>`

The set is additive: new events may be introduced as features are added;
existing events are considered stable and breaking-change-controlled.

**For Modaliser-Racket specifically** (not contract, just implementation
note): the current `eprintf`-scattered style needs consolidation into a
logging module (`lib/events.rkt` or equivalent) that emits to the file
per contract. This is in-scope for the implementation plan.

## Conformance Contract 2 — Observable State

Documented in `docs/observable-state.md`. Summary:

- **MRU file**: `~/.config/modaliser/mru.dat`. Format currently: Racket
  `write`/`read` serialisation. Swift impl will need to match by
  implementing a compatible reader/writer OR the format gets lifted to
  a language-neutral form (JSON lines keyed by remember-key). **Open
  question for implementation plan**: which?
- **Lock file**: path and contents (PID) TBD — Modaliser-Racket's
  current behaviour needs to be documented.
- **Config path**: `~/.config/modaliser/config.scm` (XDG).

App-Spec scenarios access these paths directly via
`guivision exec` + `cat`/`stat`, so format changes are observable
breakages.

## Conformance Contract 3 — Test Config

A single `config/test-config.scm` in App-Spec exercises every
feature tested. Scenarios reference bindings from this config
(e.g., "after F18 s, Safari is frontmost"). Every implementation must
load this file at impl startup (via `MODALISER_CONFIG` env var or a
`--config` flag — **open question**, to be resolved in implementation
plan).

The file is Scheme / s-expression syntax consumed by the LispKit-style
flat-namespace loader Modaliser uses. This is existing Modaliser-Racket
behaviour; Swift Modaliser already did this with LispKit. Future impls
must continue to do so — this is part of what "being a Modaliser
implementation" means.

## Runner Behaviour

**Invocation** (from Modaliser-Racket's root, during v1):

```
racket AppSpec/runner/main.rkt run APIAnyware-MacOS/knowledge/apps/modaliser/scenarios/ \
    --impl APIAnyware-MacOS/generation/targets/racket-oo/apps/modaliser/modaliser-impl.rkt [--vm <id>] [--filter <pattern>]
```

A small `AppSpec/run.sh` wrapper reduces the line length for day-to-day use.
Post-extraction the invocation becomes `raco app-spec run …` against
an installed package; structure and flags unchanged.

**`APIAnyware-MacOS/generation/targets/racket-oo/apps/modaliser/modaliser-impl.rkt`**:

```racket
#lang app-spec/impl

(impl
  #:name       "Modaliser-Racket"
  #:binary     (build-path (find-system-path 'home-dir)
                           "Development/Modaliser-Racket"
                           "build/Modaliser.app")
  #:config-env "MODALISER_CONFIG"
  #:log-env    "MODALISER_EVENTS_LOG"
  #:bundle-id  "dev.antony.Modaliser-Racket"
  #:launch-via 'open)            ; 'open | 'launchctl | 'direct
```

`#lang app-spec/impl` is a small Racket dialect exposing one
form (`impl`) that validates required keywords and `provide`s a
canonical config value. The runner loads an impl by `dynamic-require`
on the file path and reads the provided value; validation errors
surface at load time with source locations. This mirrors how
scenarios use `#lang app-spec` — consistent surface, consistent
error ergonomics.

Additional `impls/<name>.rkt` files get added as new implementations
land (still in-tree during incubation; one-per-repo after extraction).

**VM lifecycle** (v1 default, user-approved):

- Shared VM across a single runner invocation.
- Per-scenario setup: quit any running Modaliser; truncate
  `events.log` and `mru.dat`; regrant accessibility to the test-build
  bundle via platform helper.
- Per-scenario execution: launch impl, run steps.
- Per-scenario teardown on failure: capture screenshot + tail of the
  events log; save under a per-scenario artifact directory.
- Per-scenario teardown on success: quit impl.
- End-of-run: print pass/fail summary; exit non-zero if any failed.

Escalation path: if flakiness emerges, fresh VM per scenario-group
category (e.g., one VM for choosers, one for windows) is the next step.
Full-VM-reset-per-scenario is the nuclear option.

**F18 / F17 emission**: via `guivision input key --vnc … f18` after
GUIVisionVMDriver Task 8 lands (already filed; extends PlatformKeymap to
f13–f19). No osascript fallback in the Racket SDK — a single code path
is worth the cross-project dependency.

## Cross-Project Dependencies

- **GUIVisionVMDriver Task 8** (filed 2026-04-18): Extended F-keys
  (F13–F19) must reach CGEvent. Required before any modal/leader-key
  scenario can run in the VM. Sole external dependency.

In-project work (Modaliser-Racket implementation plan scope):

- Consolidate scattered `eprintf` calls into a structured `lib/events.rkt`
  emitter that conforms to the logging contract.
- Add a startup path that honours `MODALISER_CONFIG` and
  `MODALISER_EVENTS_LOG` env vars, so the runner can point the impl at
  `AppSpec/config/test-config.scm` and a per-scenario log file.

## Open Questions — To Resolve In Implementation Plan

1. **MRU file format**: keep Racket `write`/`read` serialisation, or
   lift to JSON (language-neutral)? Keeping current format pushes the
   burden onto Swift and future impls; lifting requires a one-time
   migration in Modaliser-Racket.
2. **Config path resolution**: env var (`MODALISER_CONFIG`), CLI flag,
   or both? Needs uniform story across impls.
3. **Lock file**: what does Modaliser-Racket actually write today?
   Contract-document it as-is or standardise?
4. **Agent `/health` semantics**: the guivision agent exposes `/health`
   but runner may want a Modaliser-specific "am I ready for input"
   probe (e.g., via reading the last `[lifecycle] startup` log line).
   Decide in implementation plan.

## Success Criteria (v1)

- The modaliser app's every config binding passes the scenario suite in
  the VM.
- `AppSpec/` has no upward dependency on the impl-under-test's source
  tree. Grep-verifiable: `rg "require\\s+\"\\.\\./\\.\\." AppSpec/`
  returns nothing (or only references within `AppSpec/` itself).
- A new impl can be wired in by writing a ~10-line
  `apps/<app>/<app>-impl.rkt` (under APIAnyware-MacOS) and running the
  same suite — verified by `AppSpec/tests/impls/null.rkt`, a stub that
  fails meaningfully.
- Adding a new feature test is one new `.rkt` scenario file under
  `APIAnyware-MacOS/knowledge/apps/<app>/scenarios/` — no runner code
  change.
- All three conformance contract docs exist (in
  `APIAnyware-MacOS/knowledge/apps/modaliser/`) and are internally
  consistent with the scenarios and the modaliser-racket impl.
- Mechanical extraction (achieved 2026-04-26 via the APIAnyware reorg):
  spec system extracted to top-level `AppSpec/`; per-app spec content
  colocates with each app inside APIAnyware-MacOS.

## Implementation Outline (high level, to be detailed in plan)

1. **Scaffold `spec/` (subsequently extracted to `AppSpec/`)**:
   directories, README stub, empty contract docs, empty
   `apps/modaliser/modaliser-impl.rkt` (`#lang app-spec/impl` stub).
2. **Write the logging contract** and land the `lib/events.rkt`
   consolidator in the modaliser app that conforms to it.
3. **Build `AppSpec/testanyware-sdk/` Racket wrappers** over the
   `testanyware` CLI + agent HTTP.
4. **Build the runner + DSL** (`#lang app-spec`, step verbs).
5. **Author scenarios** covering modal, choosers, launch, windows,
   lifecycle — behavioural depth.
6. **Write `AppSpec/config/test-config.scm`** that exercises everything
   scenarios assert.
7. **Wire up `APIAnyware-MacOS/generation/targets/racket-oo/apps/modaliser/modaliser-impl.rkt`** and shake down against
   a live VM once TestAnyware Task 8 lands.
8. **Update `.gitignore`** for per-scenario artifact directories
   (screenshots, log snapshots) that the runner emits on failure.
