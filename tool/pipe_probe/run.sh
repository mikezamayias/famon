#!/bin/bash
# Pass/fail check that `famon monitor --raw` works with no terminal attached,
# the way an AI agent or a shell pipeline runs it. Uses the stub adb in ./bin,
# so no device is needed. Exits non-zero if any check fails.
#
#   tool/pipe_probe/run.sh
#
# Case A: stdin </dev/null, no --no-shortcuts, stdout to a file, then SIGINT.
# Case B: famon monitor --raw </dev/null | head -5
# Case C: famon monitor --raw </dev/null 2>&1 | head -N, for N = 1, 2 and 6
# Case D: adb is unusable, stdout to a file: stdout stays empty, hints on stderr
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
no_crash_text() { ! grep -Eq 'Unhandled exception|^#[0-9]+ +|StackTrace|Stack trace' "$1"; }
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
famon=(dart run bin/famon.dart monitor --raw --platform android)
# Runs `famon monitor --raw </dev/null | head -<lines>` in the background,
# with famon's stderr in <stderr file>, or in the pipe when that is -, and
# head's output in $out/<id>.out. Checks that famon exits 0 once head
# closes, that no stub adb is left, and that head got <lines> lines.
run_into_head() { # run_into_head <id> <lines> <stderr file|->
  local id="$1" n="$2" err="$3" status
  (
    if [ "$err" = - ]; then
      "${famon[@]}" </dev/null 2>&1
    else
      "${famon[@]}" </dev/null 2>"$err"
    fi | head -"$n" >"$out/$id.out"
    echo "${PIPESTATUS[0]}" >"$out/$id.status"
  ) &
  job=$!
  if ended_within "$job" 20; then
    status="$(cat "$out/$id.status")"
    check "famon exits with status 0 once head closes (got $status)" [ "$status" = 0 ]
  else
    check "pipeline ends within 20s" false
  fi
  check "stub adb is not left running" stub_dead
  check "head got $n lines" [ "$(wc -l <"$out/$id.out" | tr -d ' ')" = "$n" ]
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
"${famon[@]}" </dev/null >"$out/a.out" 2>"$out/a.err" &
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
run_into_head b 5 "$out/b.err"
check "all 5 lines are event lines" only_events "$out/b.out"
check "stderr holds only the banner" cmp -s "$out/banner" "$out/b.err"
kill_leftovers
wait "$job" 2>/dev/null

for n in 1 2 6; do
  echo "== Case C$n: famon monitor --raw </dev/null 2>&1 | head -$n"
  run_into_head "c$n" "$n" -
  check "no stack trace or unhandled exception" no_crash_text "$out/c$n.out"
  kill_leftovers
  wait "$job" 2>/dev/null
done

echo "== Case D: adb unusable, famon monitor --raw </dev/null >file"
PROBE_ADB_FAIL=version "${famon[@]}" </dev/null >"$out/d.out" 2>"$out/d.err" &
job=$!
if ended_within "$job" 20; then wait "$job"; status=$?; else status=timeout; fi
check "famon exits with status 1 (got $status)" [ "$status" = 1 ]
check "stdout is empty" [ ! -s "$out/d.out" ]
check "stderr names the missing tools" grep -q 'Required tools not available for Android' "$out/d.err"
check "stderr holds the install hints" grep -q 'Android SDK platform-tools are required' "$out/d.err"
check "no stack trace or unhandled exception" no_crash_text "$out/d.err"
kill_leftovers

rm -rf "$out"
rmdir "$repo/build" 2>/dev/null
if [ "$failures" -eq 0 ]; then echo "ALL PASSED"; else echo "$failures FAILED"; fi
[ "$failures" -eq 0 ]
