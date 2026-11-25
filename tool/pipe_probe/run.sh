#!/bin/bash
# Pass/fail check that `famon monitor --raw` works with no terminal attached,
# the way an AI agent or a shell pipeline runs it. Uses the stub adb in ./bin,
# so no device is needed. Exits non-zero if any check fails.
#
#   tool/pipe_probe/run.sh
#
# Case A: stdin </dev/null, no --no-shortcuts, stdout to a file, then SIGINT.
# Case B: famon monitor --raw </dev/null | head -5
set -u

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
out="$repo/build/pipe_probe"
rm -rf "$out"
mkdir -p "$out"
export PATH="$here/bin:$PATH"
export PROBE_PIDFILE="$out/adb.pid"
cd "$repo" || exit 1

failures=0
check() { # check <description> <command...>
  local what="$1"
  shift
  if "$@"; then echo "  PASS $what"; else echo "  FAIL $what"; failures=$((failures + 1)); fi
}

event_re='^[0-9-]+ [0-9:.]+ \| add_to_cart \| \{.*\} \| items=\[.*\]$'
only_events() { [ -s "$1" ] && ! grep -Evq "$event_re" "$1"; }
no_escapes() { ! LC_ALL=C grep -q $'\x1b' "$1"; }
famon_pids() { pgrep -f 'famon.dart monitor' || true; }
stub_dead() {
  sleep 1
  ! { [ -f "$PROBE_PIDFILE" ] && kill -0 "$(cat "$PROBE_PIDFILE")" 2>/dev/null; }
}
# Waits up to $2 seconds for pid $1 to end. Returns 0 if it ended.
ended_within() {
  local i=0
  while kill -0 "$1" 2>/dev/null && [ "$i" -lt $(($2 * 2)) ]; do
    sleep 0.5
    i=$((i + 1))
  done
  ! kill -0 "$1" 2>/dev/null
}
kill_leftovers() {
  for p in $(famon_pids); do kill -9 "$p" 2>/dev/null; done
  [ -f "$PROBE_PIDFILE" ] && kill -9 "$(cat "$PROBE_PIDFILE")" 2>/dev/null
  rm -f "$PROBE_PIDFILE"
}

printf '%s\n' '🔥 Firebase Analytics Monitor Started' '📱 Connecting to Android...' \
  'Press Ctrl+C to stop monitoring' '' >"$out/banner"

echo "== warm-up compile: $(dart run bin/famon.dart --version 2>&1 | tail -1)"

echo "== Case A: famon monitor --raw </dev/null >file, then SIGINT"
dart run bin/famon.dart monitor --raw --platform android \
  </dev/null >"$out/a.out" 2>"$out/a.err" &
job=$!
sleep 7
check "keeps running with stdin from /dev/null" kill -0 "$job"
check "prints event lines" grep -Eq "$event_re" "$out/a.out"
for p in $(famon_pids); do kill -INT "$p" 2>/dev/null; done
if ended_within "$job" 10; then wait "$job"; status=$?; else status=timeout; fi
check "SIGINT stops famon with status 0 (got $status)" [ "$status" = 0 ]
check "stub adb is not left running" stub_dead
check "stdout holds only event lines" only_events "$out/a.out"
check "stdout has no ANSI escapes" no_escapes "$out/a.out"
check "stderr holds only the banner" cmp -s "$out/banner" "$out/a.err"
kill_leftovers

echo "== Case B: famon monitor --raw </dev/null | head -5"
(
  dart run bin/famon.dart monitor --raw --platform android \
    </dev/null 2>"$out/b.err" | head -5 >"$out/b.out"
  echo "${PIPESTATUS[0]}" >"$out/b.status"
) &
job=$!
if ended_within "$job" 20; then
  status="$(cat "$out/b.status")"
  check "famon exits with status 0 once head closes (got $status)" [ "$status" = 0 ]
else
  check "pipeline ends within 20s" false
fi
check "stub adb is not left running" stub_dead
check "head got 5 lines" [ "$(wc -l <"$out/b.out" | tr -d ' ')" = 5 ]
check "all 5 lines are event lines" only_events "$out/b.out"
check "stderr holds only the banner" cmp -s "$out/banner" "$out/b.err"
kill_leftovers
wait "$job" 2>/dev/null

rm -rf "$out"
rmdir "$repo/build" 2>/dev/null
if [ "$failures" -eq 0 ]; then echo "ALL PASSED"; else echo "$failures FAILED"; fi
[ "$failures" -eq 0 ]
