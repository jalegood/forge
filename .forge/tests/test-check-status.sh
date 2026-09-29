#!/usr/bin/env bash
set -e

# Validates .forge/scripts/check-status.js (TASK-082, CONTRACT#rules/status-lint).
#
# The invariant that matters most: a row that does not parse to the declared
# column count is an ERROR, never a skipped row. A dropped Observations row is
# indistinguishable from an absent one, and at foundation severity it disables
# the pipeline's one mechanical hard stop while every report shows a clear
# queue. Each failing fixture here is one lint rule; each was run against the
# unfixed world (no lint at all) where every one of them passed silently.

SCRIPT="$(pwd)/.forge/scripts/check-status.js"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
mkdir -p "$TMPDIR/.forge"

# A minimal valid workplan so planned: links can resolve.
cat > "$TMPDIR/.forge/WORKPLAN.md" << 'EOF'
# Workplan

## [TASK-001] Real task

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#rules
- **Gate:** `echo ok`
- **Notes:**
EOF

cat > "$TMPDIR/.forge/CONTRACT.md" << 'EOF'
# Contract

## Rules

Fixture.
EOF

write_status() {
  cat > "$TMPDIR/.forge/STATUS.md"
}

valid_status() {
  cat << 'EOF'
# Status

## Open Questions

| ID | Question | Blocking? | Raised |
| -- | -------- | --------- | ------ |
| Q-001 | A question? | No | 2026-08-01 |

## Decisions

### 2026-08-02 — A decision

The decision.

**Why:** reasons.

**Rejected alternatives:** the other thing.

## Risks

| Risk | Impact | Mitigation |
| ---- | ------ | ---------- |

## Blockers

| Blocker | Blocking tasks | Needs |
| ------- | -------------- | ----- |

## Observations

| ID | Date | Raised by | Kind | Severity | Observation | Disposition |
| -- | ---- | --------- | ---- | -------- | ----------- | ----------- |
| OBS-001 | 2026-08-01 | TASK-001 | bug | normal | Something with an escaped \| pipe. | closed |
| OBS-002 | 2026-08-02 | TASK-001 | design | foundation | A suspect approach. | planned:TASK-001 |
| OBS-003 | 2026-08-03 | TASK-001 | scope | normal | Folded elsewhere. | duplicate:OBS-001 |
EOF
}

run() {
  RC=0
  OUT=$(cd "$TMPDIR" && node "$SCRIPT" 2>&1) || RC=$?
}

fail() { echo "FAILED: $1"; echo "--- output ---"; echo "$OUT"; exit 1; }
expect_pass() { [ "$RC" = "0" ] || fail "$1 (expected exit 0, got $RC)"; }
expect_fail() { [ "$RC" = "1" ] || fail "$1 (expected exit 1, got $RC)"; }
expect_msg()  { echo "$OUT" | grep -qi -- "$1" || fail "$2 (expected output to mention \"$1\")"; }

echo "Fixture 1: a valid STATUS.md passes..."
valid_status | write_status
run
expect_pass "valid file"
echo "  OK"

echo "Fixture 2: a malformed row (unescaped pipe) is an error, not a dropped row..."
valid_status | sed 's/an escaped \\| pipe/an unescaped | pipe/' | write_status
run
expect_fail "unescaped pipe"
expect_msg "escape" "the error says how to fix it"
echo "  OK"

echo "Fixture 3: wrong column order is an error..."
valid_status | sed 's/| ID | Date | Raised by |/| Date | ID | Raised by |/' | write_status
run
expect_fail "column order"
expect_msg "Data Model requires" "the required order is named"
echo "  OK"

echo "Fixture 4: enum violations are errors..."
valid_status | sed 's/| bug |/| vibe |/' | write_status
run
expect_fail "bad Kind"
valid_status | sed 's/| normal | Something/| urgent | Something/' | write_status
run
expect_fail "bad Severity"
valid_status | sed 's/| closed |/| parked |/' | write_status
run
expect_fail "bad Disposition"
echo "  OK"

echo "Fixture 5: planned: must name an existing task..."
valid_status | sed 's/planned:TASK-001/planned:TASK-999/' | write_status
run
expect_fail "planned link"
expect_msg "TASK-999" "the missing task is named"
echo "  OK"

echo "Fixture 6: duplicate: must not chain to another duplicate..."
valid_status | sed 's/duplicate:OBS-001/duplicate:OBS-003/' | write_status
run
expect_fail "self-referential duplicate chain"
echo "  OK"

echo "Fixture 7: duplicate ID and non-monotonic ID are errors..."
valid_status | sed 's/OBS-003/OBS-002/' | write_status
run
expect_fail "duplicate ID"
echo "  OK"

echo "Fixture 8: an old accepted row warns but does not block..."
valid_status | sed 's/| closed |/| accepted |/' | write_status
run
expect_pass "accepted row is not an error"
expect_msg "awaiting planning" "the backlog warning prints"
echo "  OK"

echo "Fixture 9: a Decisions table (pre-migration shape) is an error..."
valid_status | sed 's/### 2026-08-02 — A decision/| Date | Decision | Why | Alternatives rejected |/' | write_status
run
expect_fail "decisions as table"
echo "  OK"

echo "Fixture 10: a Decisions heading without the dated shape is an error..."
valid_status | sed 's/### 2026-08-02 — A decision/### A decision with no date/' | write_status
run
expect_fail "undated decisions heading"
echo "  OK"

echo "Fixture 11: the live STATUS.md passes..."
RC=0
OUT=$(node "$SCRIPT" 2>&1) || RC=$?
expect_pass "live STATUS.md"
echo "  OK"

echo "Fixture 12: the PostToolUse hook wrapper translates exit 1 into a blocking exit 2..."
# CONTRACT#interfaces/script-exit-codes: hook scripts follow Claude Code's
# contract, where only exit 2 blocks and every other nonzero exit reports a
# problem while letting the tool run anyway. A wrapper that passed the
# script's exit 1 straight through would prevent nothing.
HOOK="$(pwd)/.forge/scripts/hook-status-lint.sh"
hook_payload() { printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$1"; }

# Fixture 10 left a deliberately-broken file behind; start from a valid one.
valid_status | write_status

RC=0; OUT=$(cd "$TMPDIR" && hook_payload ".forge/STATUS.md" | bash "$HOOK" 2>&1) || RC=$?
[ "$RC" = "0" ] || fail "a clean STATUS.md must pass the hook (got $RC)"

RC=0; OUT=$(cd "$TMPDIR" && hook_payload "README.md" | bash "$HOOK" 2>&1) || RC=$?
[ "$RC" = "0" ] || fail "an edit to an unrelated file must not run the lint (got $RC)"

printf '%s
' "| OBS-004 | 2026-08-04 | TASK-001 | bug | normal | An unescaped | pipe. | open |" >> "$TMPDIR/.forge/STATUS.md"
RC=0; OUT=$(cd "$TMPDIR" && hook_payload ".forge/STATUS.md" | bash "$HOOK" 2>&1) || RC=$?
[ "$RC" = "2" ] || fail "a malformed STATUS.md must block with exit 2, not merely report (got $RC)"
echo "$OUT" | grep -qi "status lint" || fail "the block must explain itself on stderr"
echo "  OK"

echo ""
echo "All check-status.js fixtures passed."
