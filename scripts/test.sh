#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause

# scripts/test.sh [--update]: degust's own tests, with a Jello toolchain:
# JELLOC, the compiler as words (jelloc by default), and JELLOVM, the VM
# (jellovm on PATH by default), beside which are jlo_tool and std.jdll. The
# compiler finds the standard library its own way (JELLO_STD_PATH). The tests
# run from degust's root, as their expected outputs, tests/expected/*.out,
# name its files; --update rewrites those from this run.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
update=0
case "${1-}" in --update) update=1 ;; "") ;; *) echo "usage: $0 [--update]" >&2; exit 2 ;; esac
JELLOC="${JELLOC:-jelloc}"
JELLOVM="$(command -v "${JELLOVM:-jellovm}")" || { echo "$0: no jellovm on PATH; set JELLOVM" >&2; exit 2; }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

$JELLOC tests/degust/Golden.test.jello --test tests/degust/Programs.test.jello --path tests --path src --out "$TMP/degust.jlo"

# The tests, given ARGS, from here.
tests() {
  env -u JELLO_BC_SKIP_VALIDATE -u JELLO_JIT_DISABLE MallocScribble=1 JELLO_JDLL_PATH="$(dirname "$JELLOVM")" \
    "$JELLOVM" "$TMP/degust.jlo" "$@" 2>&1
}
failures=0
# check STATUS OUTPUT ARGS...: the tests, given ARGS, exit STATUS and print
# OUTPUT, or what contains it when OUTPUT starts with "...".
check() {
  local want_status="$1" want="$2" result status; shift 2
  result="$(tests "$@")" && status=0 || status=$?
  if [[ "$status" != "$want_status" ]] ||
    { [[ "$want" == ...* ]] && [[ "$result" != *"${want#...}"* ]]; } ||
    { [[ "$want" != ...* ]] && [[ "$result" != "$want" ]]; }; then
    printf 'FAIL: degust %s: want status %s and:\n%s\ngot status %s and:\n%s\n' "$*" "$want_status" "$want" "$status" "$result" >&2
    failures=$((failures + 1))
  fi
}
# expected FILE STATUS ARGS...: check, with FILE's output, which --update
# first rewrites.
expected() {
  local file="$1" want_status="$2"; shift 2
  if [[ "$update" == 1 ]]; then tests "$@" > "$file" || true; fi
  check "$want_status" "$(cat "$file")" "$@"
}
# degust.Programs' options: the compiler and the VM.
P=(-- --compiler "$JELLOC" --vm "$JELLOVM")

check 0 $'=== RUN   degust/Golden/testMatches\n=== RUN   degust/Golden/testDiffers\n=== RUN   degust/Golden/testMatchesOnly\n=== RUN   degust/Golden/testMissing\n=== RUN   degust/Golden/testUpdates\nok' --run degust/Golden
check 0 $'=== RUN   degust/Golden/testUpdates\n--- PASS: degust/Golden/testUpdates (tests/degust/Golden.test.jello:39)\n    updated build/golden/updated.golden\n    updated build/golden/updated.golden\nok' \
  -v --run degust/Golden/testUpdates -- --update
expected tests/expected/passes.out 0 -v --run degust/Programs/testPasses "${P[@]}" --jobs 1
expected tests/expected/fails.out 1 --run degust/Programs/testFails "${P[@]}" --modes jit
check 1 "...--- FAIL: degust/Programs/testPasses/expect/check
    the check failed: status 1
=== RUN   degust/Programs/testPasses/expect/jit" --run degust/Programs/testPasses/expect "${P[@]}" --modes jit --check false
# The exports that read the options, given them and not.
check 0 $'=== RUN   degust/Programs/testOptions\nok' --run degust/Programs/testOptions -- --vm /v/jellovm --compiler 'jc "a b"' --std /s --out /o \
  --modes jit,eager --check 'chk -q'
check 0 $'=== RUN   degust/Programs/testDefaults\nok' --run degust/Programs/testDefaults -- --vm /v/jellovm
# Options after -- are the ones the tests declare, listed in the usage.
check 2 $'...unexpected argument after --: --bogus\nusage:' --run degust/Programs/testPasses -- --bogus x
check 2 $'...after --:\n  --update\n      rewrite golden files that differ or are missing (degust.Golden)\n  --compiler value\n' -- --jobs
check 1 "...    threw degust.Programs needs -- --compiler CMD --vm PATH" --run degust/Programs/testPasses

if [[ "$failures" -gt 0 ]]; then
  echo "degust: $failures failure(s)" >&2
  exit 1
fi
echo "degust: passed"
