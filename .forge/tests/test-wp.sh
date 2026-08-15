#!/usr/bin/env bash
set -e

# Validates .forge/scripts/wp.js — the deterministic workplan projection and
# mutation script (TASK-058, CONTRACT#rules/workplan-access-discipline).
#
# Beyond command-by-command behavior, two properties carry the contract:
#   - Selection reproduces the *whole* rule set from
#     CONTRACT#interfaces/command-forge-next: resume-active, explicit-ID
#     override, unmet-dependency warning, and the one-active-task constraint.
#     Moving selection into a script must not quietly drop any of them.
#   - The format boundary holds: every mutation leaves WORKPLAN.md as plain,
#     hand-editable markdown that check-workplan.js still accepts, and touches
#     only the lines it claims to touch.

SCRIPTS="$(pwd)/.forge/scripts"
WP="$SCRIPTS/wp.js"
CHECK="$SCRIPTS/check-workplan.js"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
mkdir -p "$TMPDIR/.forge"

# wp.js resolves WORKPLAN.md from the working directory and shells out to
# check-workplan.js next to itself, which does the same — so the fixture dir
# only needs the .forge documents, not a copy of the scripts.
cat > "$TMPDIR/.forge/CONTRACT.md" << 'EOF'
# Contract

## Data Model

### Context Manifest

Fixture content.

## Rules

### Workplan Lint

Fixture content.
EOF

write_workplan() {
  cat > "$TMPDIR/.forge/WORKPLAN.md"
}

base_workplan() {
  cat << 'EOF'
# Workplan

## [TASK-001] First task

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-lint
- **Gate:** `echo ok`
- **Notes:** Short note.

## [TASK-002] Second task

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-001
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `bash tests/test-two.sh`
- **Notes:**

## [TASK-003] Third task needing a decision

- **Status:** pending
- **Type:** clarify
- **Depends:** TASK-002
- **Context:** CONTRACT#rules/workplan-lint
- **Gate:** `manual: confirm the decision`
- **Notes:** Needs a human decision.

## [TASK-004] Fourth task with multi-line notes

- **Status:** pending
- **Type:** refactor
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-lint
- **Gate:** `echo ok`
- **Notes:** First line of notes.

  Second paragraph of notes.
EOF
}

active_workplan() {
  cat << 'EOF'
# Workplan

## [TASK-001] First task

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-lint
- **Gate:** `echo ok`
- **Notes:** Short note.

## [TASK-002] Second task

- **Status:** active
- **Type:** feature
- **Depends:** TASK-001
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `bash tests/test-two.sh`
- **Notes:** Resume context from the previous session.

## [TASK-004] Fourth task with multi-line notes

- **Status:** pending
- **Type:** refactor
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-lint
- **Gate:** `echo ok`
- **Notes:** First line of notes.

  Second paragraph of notes.
EOF
}

nothing_workplan() {
  cat << 'EOF'
# Workplan

## [TASK-001] Only task

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-lint
- **Gate:** `echo ok`
- **Notes:**

## [TASK-002] Blocked task

- **Status:** blocked
- **Type:** fix
- **Depends:** TASK-001
- **Context:** CONTRACT#rules/workplan-lint
- **Gate:** `bash tests/test-two.sh`
- **Notes:** Waiting on a decision.
EOF
}

run() {
  RC=0
  OUT=$(cd "$TMPDIR" && node "$WP" "$@" 2>&1) || RC=$?
}

fail() {
  echo "FAILED: $1"
  echo "--- output ---"
  echo "$OUT"
  exit 1
}

assert_rc() { [ "$RC" = "$1" ] || fail "$2 (expected exit $1, got $RC)"; }
assert_has() { echo "$OUT" | grep -qi -- "$1" || fail "$2 (expected output to mention \"$1\")"; }
assert_lacks() { if echo "$OUT" | grep -qi -- "$1"; then fail "$2 (output should not mention \"$1\")"; fi; }

echo "Checking wp.js next (selection)..."

base_workplan | write_workplan
rm -f "$TMPDIR/.forge/STATUS.md"

# --- next: first unblocked pending task in file order ---
run next
assert_rc 0 "next selects a task"
assert_has "TASK-002" "next selects the first unblocked pending task"
assert_has "next-unblocked" "next reports how the task was selected"
assert_has "Gate:" "next emits the gate"
assert_has "Context:" "next emits the context manifest"
# TASK-003's dependency is pending, so it is not unblocked; TASK-004 is unblocked
# but later in file order. Neither may appear — projection returns one task only.
assert_lacks "Third task" "next must not emit tasks it did not select"
assert_lacks "Fourth task" "next must not emit the whole workplan"
echo "  next -> first unblocked pending: OK"

# --- next: explicit ID overrides file order ---
run next TASK-004
assert_rc 0 "explicit ID selects that task"
assert_has "TASK-004" "explicit ID selects the requested task"
assert_has "explicit" "explicit selection is reported as such"
assert_has "Second paragraph of notes" "multi-line Notes survive projection"
echo "  next TASK-XXX -> explicit override: OK"

# --- next: unmet dependencies warn but do not stop ---
run next TASK-003
assert_rc 0 "unmet dependencies warn rather than stop"
assert_has "TASK-003" "the requested task is still selected"
assert_has "unmet dependencies" "unmet dependencies are named"
assert_has "TASK-002" "the unsatisfied dependency is listed"
echo "  next TASK-XXX -> unmet dependency warning: OK"

# --- next: unknown task ID is a usage error ---
run next TASK-999
assert_rc 1 "unknown task ID fails"
assert_has "TASK-999" "the unknown ID is named"
echo "  next TASK-999 -> not found: OK"

echo "Checking wp.js next (active-task rules)..."

active_workplan | write_workplan

# --- next: an active task resumes, with its Notes as continuity ---
run next
assert_rc 0 "next resumes the active task"
assert_has "TASK-002" "the active task is the one resumed"
assert_has "resume-active" "resumption is reported as such"
assert_has "Resume context from the previous session" "Notes are surfaced for continuity"
echo "  next -> resume active: OK"

# --- next TASK-XXX matching the active task is also a resume ---
run next TASK-002
assert_rc 0 "explicitly naming the active task resumes it"
assert_has "resume-active" "naming the active task is a resume, not a conflict"
echo "  next TASK-002 (active) -> resume: OK"

# --- next TASK-XXX while a *different* task is active is refused ---
run next TASK-004
assert_rc 2 "starting a second task while one is active is refused"
assert_has "TASK-002" "the conflicting active task is named"
assert_has "active" "the one-active-task constraint is explained"
echo "  next TASK-XXX with another active -> refused: OK"

# --- next: nothing selectable ---
nothing_workplan | write_workplan
run next
assert_rc 2 "no unblocked pending task is not a crash"
assert_has "no unblocked" "the empty case is explained"
echo "  next -> nothing available: OK"

echo "Checking wp.js get..."

base_workplan | write_workplan
run get TASK-003
assert_rc 0 "get returns a task"
assert_has "TASK-003" "get returns the requested task"
assert_has "clarify" "get emits the Type field"
assert_has "manual: confirm the decision" "get emits the Gate field verbatim"
assert_lacks "Selection:" "get does not claim a selection"
assert_lacks "Fourth task" "get returns one task, not the file"
run get TASK-999
assert_rc 1 "get on an unknown ID fails"
echo "  get TASK-XXX: OK"

echo "Checking wp.js status..."

cat > "$TMPDIR/.forge/STATUS.md" << 'EOF'
# Status

## Open Questions

| ID | Question | Blocking? | Raised |
| -- | -------- | --------- | ------ |

## Observations

| ID | Raised by | Kind | Severity | Observation | Disposition |
| -- | --------- | ---- | -------- | ----------- | ----------- |
| OBS-1 | TASK-001 | friction | normal | A small annoyance in the fixture | open |
| OBS-2 | TASK-001 | design | foundation | The fixture approach is suspect | open |
| OBS-3 | TASK-001 | friction | normal | Already dealt with | accepted |
EOF

run status
assert_rc 0 "status succeeds"
assert_has "1 done" "status counts done tasks"
assert_has "3 pending" "status counts pending tasks"
assert_has "TASK-002" "status names the next unblocked task"
assert_has "TASK-003" "status lists clarify tasks awaiting input"
assert_has "foundation" "status surfaces foundation-severity observations"
assert_has "OBS-2" "open observations are listed"
assert_lacks "OBS-3" "non-open observations are not listed"
# foundation rows come first
FOUND_LINE=$(echo "$OUT" | grep -n "OBS-2" | cut -d: -f1)
NORMAL_LINE=$(echo "$OUT" | grep -n "OBS-1" | cut -d: -f1)
[ "$FOUND_LINE" -lt "$NORMAL_LINE" ] || fail "foundation observations must be listed first"
echo "  status: OK"

rm -f "$TMPDIR/.forge/STATUS.md"
run status
assert_rc 0 "status works without STATUS.md"
assert_has "1 done" "counts still reported without STATUS.md"
echo "  status without STATUS.md: OK"

echo "Checking wp.js --json..."

base_workplan | write_workplan
for cmd in "next" "status"; do
  run $cmd --json
  assert_rc 0 "$cmd --json succeeds"
  node -e "JSON.parse(process.argv[1])" "$OUT" || fail "$cmd --json must emit parseable JSON"
done

run get TASK-004 --json
assert_rc 0 "get --json succeeds"
node -e "
  const d = JSON.parse(process.argv[1]);
  const t = d.task;
  if (t.id !== 'TASK-004') throw new Error('id');
  if (!Array.isArray(t.depends)) throw new Error('depends must be a list');
  if (!Array.isArray(t.context) || t.context.length !== 1) throw new Error('context must be a list of refs');
  if (!/Second paragraph/.test(t.notes)) throw new Error('notes must carry the full multi-line value');
" "$OUT" || fail "get --json shape"
echo "  --json: OK"

echo "Checking wp.js set (mutation)..."

base_workplan | write_workplan
cp "$TMPDIR/.forge/WORKPLAN.md" "$TMPDIR/before.md"

run set TASK-002 status active
assert_rc 0 "set status succeeds"
grep -q '^- \*\*Status:\*\* active$' "$TMPDIR/.forge/WORKPLAN.md" || fail "status was not written as plain markdown"
# The mutation must touch exactly one line — the format boundary is the point.
DIFFLINES=$(diff "$TMPDIR/before.md" "$TMPDIR/.forge/WORKPLAN.md" | grep -c '^[<>]' || true)
[ "$DIFFLINES" = "2" ] || fail "set must change exactly one line (changed $DIFFLINES diff lines)"
echo "  set status: OK"

# --- one active task at a time is enforced on write, not just on read ---
run set TASK-004 status active
assert_rc 1 "activating a second task is refused"
assert_has "TASK-002" "the existing active task is named"
grep -q '^- \*\*Status:\*\* pending$' "$TMPDIR/.forge/WORKPLAN.md" || fail "refused mutation must leave the file unchanged"
echo "  set status active (second) -> refused: OK"

# --- lifecycle transitions are enforced (CONTRACT#state-machines/task-lifecycle) ---
run set TASK-004 status done
assert_rc 1 "pending -> done is not a valid transition"
assert_has "transition" "the invalid transition is explained"
run set TASK-004 status done --force
assert_rc 0 "--force overrides the transition check"
echo "  set status -> transition rules: OK"

# --- invalid field and value are rejected ---
base_workplan | write_workplan
run set TASK-002 status finished
assert_rc 1 "an invalid status value is rejected"
run set TASK-002 colour blue
assert_rc 1 "an unknown field is rejected"
run set TASK-999 status active
assert_rc 1 "set on an unknown task is rejected"
echo "  set validation: OK"

# --- set on other fields ---
run set TASK-002 gate 'bash tests/test-new.sh'
assert_rc 0 "set gate succeeds"
grep -q '^- \*\*Gate:\*\* bash tests/test-new.sh$' "$TMPDIR/.forge/WORKPLAN.md" || fail "gate was not written"
echo "  set gate: OK"

echo "Checking wp.js append-notes..."

base_workplan | write_workplan

# --- appending to an empty Notes field puts the text inline ---
run append-notes TASK-002 'Files: a.js, b.js'
assert_rc 0 "append-notes succeeds on an empty Notes field"
grep -q '^- \*\*Notes:\*\* Files: a.js, b.js$' "$TMPDIR/.forge/WORKPLAN.md" || fail "empty Notes must be filled inline"
echo "  append-notes to empty Notes: OK"

# --- appending to existing Notes preserves them and indents the continuation ---
run append-notes TASK-004 'Files: c.js'
assert_rc 0 "append-notes succeeds on populated Notes"
grep -q 'First line of notes' "$TMPDIR/.forge/WORKPLAN.md" || fail "existing notes must be preserved"
grep -q 'Second paragraph of notes' "$TMPDIR/.forge/WORKPLAN.md" || fail "existing multi-line notes must be preserved"
grep -q '^  Files: c.js$' "$TMPDIR/.forge/WORKPLAN.md" || fail "appended notes must be indented as a continuation line"
echo "  append-notes to populated Notes: OK"

# --- the result is still a valid workplan that wp.js can re-read ---
run get TASK-004
assert_rc 0 "the mutated workplan is still readable"
assert_has "Files: c.js" "the appended note round-trips"
assert_has "First line of notes" "the original note round-trips"
run append-notes TASK-999 'nope'
assert_rc 1 "append-notes on an unknown task is rejected"
echo "  append-notes round-trip: OK"

echo "Checking mutations stay lint-clean..."

# Every mutation above ran through wp.js, which re-lints and reverts on failure;
# prove it independently by running the real linter over the mutated fixture.
run set TASK-003 status active
assert_rc 0 "pending -> active succeeds"
run set TASK-003 status blocked
assert_rc 0 "active -> blocked succeeds"
LINT_RC=0
LINT_OUT=$(cd "$TMPDIR" && node "$CHECK" 2>&1) || LINT_RC=$?
if [ "$LINT_RC" != "0" ]; then
  echo "FAILED: mutated workplan does not pass check-workplan.js"
  echo "$LINT_OUT"
  exit 1
fi
echo "  check-workplan.js after mutations: OK"

# --- a mutation that would break the lint is reverted, not left on disk ---
base_workplan | write_workplan
cp "$TMPDIR/.forge/WORKPLAN.md" "$TMPDIR/before2.md"
run set TASK-002 context 'CONTRACT#does-not-exist'
assert_rc 1 "a mutation that breaks the lint is refused"
diff -q "$TMPDIR/before2.md" "$TMPDIR/.forge/WORKPLAN.md" > /dev/null || fail "a refused mutation must be reverted on disk"
echo "  lint-failing mutation reverted: OK"

echo "Checking wp.js against the real workplan..."

RC=0
OUT=$(node "$WP" status 2>&1) || RC=$?
[ "$RC" = "0" ] || fail "wp.js status must work on the project's own WORKPLAN.md"
echo "$OUT" | grep -qi "total" || fail "status must report a task total on the real workplan"
echo "  real WORKPLAN.md: OK"

echo "Checking usage errors..."

run
assert_rc 1 "no command is a usage error"
assert_has "usage" "usage is printed"
run frobnicate
assert_rc 1 "an unknown command is a usage error"
echo "  usage: OK"

echo ""
echo "All wp.js checks passed."
