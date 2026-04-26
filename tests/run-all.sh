#!/usr/bin/env bash
# tests/run-all.sh — Run App-Spec unit tests.
#
# Pure-Racket tests for the language, runner, and SDK helpers (no
# Cocoa dependency). Per-file timeouts mirror the impl-side runner;
# the default budget is short.

set -u
shopt -s nullglob

cd "$(dirname "$0")/.."

TIMEOUT="${TIMEOUT:-20}"

if command -v timeout >/dev/null 2>&1; then
    TIMEOUT_BIN=timeout
elif command -v gtimeout >/dev/null 2>&1; then
    TIMEOUT_BIN=gtimeout
else
    echo "ERROR: neither 'timeout' nor 'gtimeout' on PATH" >&2
    echo "       brew install coreutils" >&2
    exit 2
fi

LOG=$(mktemp -t app-spec-test.XXXXXX)
trap 'rm -f "$LOG"' EXIT

passed=0
failed=0
fail_list=()

RACKUNIT_FAILURE_RE='^FAILURE$|^name:[[:space:]]+check-'

for f in tests/test-*.rkt; do
    "$TIMEOUT_BIN" -k 1 "$TIMEOUT" racket "$f" >"$LOG" 2>&1
    rc=$?

    if [ $rc -eq 0 ] && grep -qE "$RACKUNIT_FAILURE_RE" "$LOG"; then
        rc=99
    fi

    case "$rc" in
        0)
            printf '[OK]      %s\n' "$f"
            passed=$((passed + 1))
            ;;
        124|137)
            printf '[TIMEOUT] %s (>%ds)\n' "$f" "$TIMEOUT"
            fail_list+=("$f (timeout)")
            ;;
        99)
            printf '[SILENT]  %s\n' "$f"
            fail_list+=("$f (silent)")
            grep -nE "$RACKUNIT_FAILURE_RE|^message:|^actual:|^expected:" "$LOG" \
                | sed 's/^/  /' | head -30
            ;;
        *)
            printf '[FAIL]    %s (rc=%d)\n' "$f" "$rc"
            failed=$((failed + 1))
            fail_list+=("$f (rc=$rc)")
            sed 's/^/  /' "$LOG" | tail -20
            ;;
    esac
done

echo
echo "Summary: $passed passed, $failed failed"

if [ ${#fail_list[@]} -gt 0 ]; then
    echo "Failures:"
    for entry in "${fail_list[@]}"; do echo "  - $entry"; done
    exit 1
fi
