#!/usr/bin/env bash
set -e

# Validates .forge/scripts/prose.js — the fence-aware grep that four gates now
# depend on (TASK-031, TASK-036, TASK-053, TASK-055).
#
# The property under test is the one that matters: a pattern occurring ONLY
# inside a fenced block must not count as a match. Gates assert that a command
# file instructs something; command files also carry large fenced payloads, so a
# gate that cannot tell instruction from payload passes without the work being
# done. If this script is wrong, those four gates lie.

PROSE="$(pwd)/.forge/scripts/prose.js"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/sample.md" << 'SAMPLE'
# Command

Create the STATUS.md stub when it does not exist.

```js
// Reads the Observations table and returns open rows.
function readObservations() {}
```

Done.
SAMPLE

run() { RC=0; OUT=$(node "$PROSE" "$@" 2>&1) || RC=$?; }
fail() { echo "FAILED: $1"; echo "--- output ---"; echo "$OUT"; exit 1; }

# --- a pattern in the prose matches ---
run "$TMPDIR/sample.md" "STATUS\.md"
[ "$RC" = "0" ] || fail "a pattern present in the prose must match"
echo "  prose match: OK"

# --- a pattern only inside the fence does NOT match ---
run "$TMPDIR/sample.md" "Observations"
[ "$RC" = "1" ] || fail "a pattern only inside a fence must not match"
run "$TMPDIR/sample.md" "readObservations"
[ "$RC" = "1" ] || fail "embedded code must not satisfy a prose assertion"
echo "  fenced payload ignored: OK"

# --- plain grep would have been fooled; that is the whole point ---
grep -q "Observations" "$TMPDIR/sample.md" || fail "fixture is wrong — grep should match the fenced text"
echo "  regression the script exists to prevent: OK"

# --- every pattern must match, not just one ---
run "$TMPDIR/sample.md" "STATUS\.md" "Observations"
[ "$RC" = "1" ] || fail "all patterns must match for success"
run "$TMPDIR/sample.md" "STATUS\.md" "Done"
[ "$RC" = "0" ] || fail "two prose patterns must both match"
echo "  conjunction of patterns: OK"

# --- matching is case-insensitive ---
run "$TMPDIR/sample.md" "status\.md"
[ "$RC" = "0" ] || fail "matching must be case-insensitive"
echo "  case-insensitive: OK"

# --- usage errors ---
run "$TMPDIR/nope.md" "anything"
[ "$RC" = "1" ] || fail "a missing file must exit nonzero"
run "$TMPDIR/sample.md"
[ "$RC" = "1" ] || fail "no patterns is a usage error"
echo "  usage errors: OK"

# --- the live case: /forge-init has no STATUS.md instruction, only payload ---
cd "$(dirname "$PROSE")/../.."
if node "$PROSE" .claude/commands/forge-init.md "STATUS\.md" 2>/dev/null; then
  echo "FAILED: forge-init.md now instructs STATUS.md creation — update TASK-031 and this test together"
  exit 1
fi
grep -q "STATUS.md" .claude/commands/forge-init.md || fail "fixture drift — forge-init.md should still contain STATUS.md inside embedded payload"
echo "  forge-init.md false-pass closed: OK"

echo ""
echo "All prose.js checks passed."
