# 050-delete-llm-state

**Kind:** work

## Goal
Delete `LLM_STATE/` entirely — the legacy state convention is now fully
superseded — and confirm nothing in the repo still references it.

## Context
Final migration step (Q1 full-replace). All durable knowledge has been salvaged
by leaves 010 (glossary + ADRs), 020 (gotchas notes), 030 (docs + README), and
all pending work forwarded by leaf 040. Only then is it safe to delete the
source.

Pre-delete verification (do these BEFORE removing the directory):
- Confirm leaves 010/020/030/040 have landed (glossary, ADRs, notes doc, moved
  docs, README fold, inbox forwards) — this leaf is the point of no return for
  the source data.
- `grep -rn "LLM_STATE" .` (outside `.grove/`) to find any code/docs/config that
  still reads from `LLM_STATE/` paths; fix or note any hits.

Then `git rm -r LLM_STATE/`.

## Done when
- `LLM_STATE/` no longer exists.
- `grep -rn "LLM_STATE"` (outside `.grove/`) is clean, or remaining hits are
  understood and intentional.
- Committed as the focused "remove legacy LLM_STATE state convention" commit.

## Notes
After this leaf retires, the grove has no live leaves left → **Finish**: promote
anything still in the briefs that should outlive the grove, delete `.grove/` in
one commit, then merge `migrate-LLM_STATE-to-grove` to the default branch. The
default branch never carries a grove's local state.
