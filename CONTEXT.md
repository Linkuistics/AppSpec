# App-Spec

App-Spec is the single authoritative operational specification of an app's
behaviour, written once and verified against every implementation of that app
end-to-end in a live macOS VM.

## Language

**App** (e.g. *Modaliser*):
A native UI application whose behaviour App-Spec specifies, independent of how
it is built.

**Implementation** (*impl*):
A concrete build of an app in some language/runtime (e.g. Modaliser-Racket,
a future Modaliser-Swift). The thing under test. Selected with `--impl`.
_Avoid_: target, variant, build (when you mean the impl under test).

**Scenario**:
One verifiable behaviour of an app, authored as a `#lang app-spec` source file.
Scenarios are implementation-agnostic — the same scenario verifies any impl.
_Avoid_: test case, spec file (reserve "test" for an impl's own unit tests).

**Scenario suite**:
The set of scenarios for one app, colocated with the app under
`APIAnyware-MacOS/knowledge/apps/<app>/scenarios/`.

**Driver**:
The installed set of operations a scenario runs through — input, control,
observation, and state verbs — that connect the abstract scenario to a concrete
impl and environment. Swapping the driver is how one scenario runs against any
impl, and how unit tests run without a VM.
_Avoid_: adapter, backend.

**Harness**:
The App-Spec runtime that loads scenarios, installs a driver, and executes them.
The language-agnostic tool shared across all apps and impls.
_Avoid_: framework, engine.

**Runner**:
The harness entry point (`runner/main.rkt`, wrapped by `run.sh`) that registers
`#lang app-spec`, selects an impl, and runs a scenario suite.

**Contract**:
A conformance requirement every impl must satisfy to be verifiable — structured
log format, observable state, and test-config compatibility. Per-app contract
docs (`logging-contract.md`, `observable-state.md`) double as the porting guide
for new impls.

**Three-tiered verification**:
The named verification strategy: hermetic unit tests, then null-impl
meaningful-failure smoke tests, then live-VM shake-down. (The tiers' mechanics
live in ADR-0004, not here.)

## grove

This repo is driven as a grove (a git-tracked tree of task files). The
cross-grove coordination terms:

**Inbox**:
A grove's queue of pending observations captured by other groves, drained at the
start of every session. Lives on the `grove-meta` branch.

**Seed**:
A captured observation written *to* another grove's inbox (via `grove-llm
inbox-add --to=<name>`) when you notice something belonging to a different
workstream.

**Drain**:
The bootstrap step that reads and triages a grove's inbox — incorporate, defer,
or reject — clearing it in one commit.

**grove-meta branch**:
The orphan `grove-meta` branch holding all groves' inboxes
(`inboxes/<name>/<entry>.md`), kept off the working branches so capture and drain
never touch project history directly.

## Example dialogue

> **Dev:** The chooser-ESC-dismiss scenario fails on the Racket impl but passes
> the null impl. Bug in the harness?
>
> **Domain expert:** No — passing the null impl is the point of the second tier,
> it proves the scenario fails meaningfully when nothing's implemented. A real
> failure on a real impl means the *driver* saw the wrong observable state, or
> the impl genuinely doesn't dismiss. Check the observable-state contract before
> you touch the harness.
