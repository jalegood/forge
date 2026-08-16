#!/usr/bin/env bash
set -e

# Validates .forge/scripts/migrate-notes.js — the migration that pulls oversized
# inline Notes out of an existing WORKPLAN.md and into task records (TASK-060,
# CONTRACT#data-model/task-record-data-model,
# CONTRACT#rules/workplan-access-discipline).
#
# Three properties carry the task:
#   - The externalization threshold is applied as written: notes longer than 3
#     lines become records, notes of 3 lines or fewer are left byte-identical.
#     The inline residue is a real summary plus the path, never a bare pointer.
#   - Migration is idempotent. It runs against projects with no git history, so
#     a second pass must be a no-op rather than a second round of rewriting.
#   - Nothing is destroyed. Records are written before the workplan is touched,
#     a .bak is taken, an existing record is never clobbered, and a workplan
#     that does not already lint clean is refused rather than rewritten.

SCRIPTS="$(pwd)/.forge/scripts"
MIGRATE="$SCRIPTS/migrate-notes.js"
CHECK="$SCRIPTS/check-workplan.js"
WP="$SCRIPTS/wp.js"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
mkdir -p "$TMPDIR/.forge"

# migrate-notes.js resolves the workplan from the working directory and shells
# out to check-workplan.js next to itself, which does the same — so the fixture
# dir only needs the .forge documents, not a copy of the scripts.
cat > "$TMPDIR/.forge/CONTRACT.md" << 'EOF'
# Contract

## Data Model

### Task Record Data Model

Fixture content.

## Rules

### Workplan Access Discipline

Fixture content.
EOF

base_workplan() {
  cat > "$TMPDIR/.forge/WORKPLAN.md" << 'EOF'
# Workplan

## [TASK-001] Short note stays inline

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-access-discipline
- **Gate:** `echo ok`
- **Notes:** Fixed the off-by-one in the slug matcher; no deviations.

## [TASK-002] Long note externalizes

- **Status:** done
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#data-model/task-record-data-model
- **Gate:** `bash tests/test-two.sh`
- **Notes:** Built the projection layer over the workplan format.

  Chose a line-based parser so mutations can target exact line ranges.
  The regex approach was rejected because it cannot report line numbers.
  Files: lib/workplan.js, scripts/wp.js

## [TASK-003] Exactly three lines stays inline

- **Status:** done
- **Type:** refactor
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-access-discipline
- **Gate:** `echo ok`
- **Notes:** One line here.
  Two lines here.
  Three lines here.

## [TASK-004] Pending task with a long spec note

- **Status:** pending
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-access-discipline
- **Gate:** `bash tests/test-four.sh`
- **Notes:** The planner wrote this and the executing agent still needs it.

  Build the thing in two passes, the second one keyed off the first.
  Do not collapse the passes — the ordering is the whole point.

## [TASK-005] Long note whose record already exists

- **Status:** done
- **Type:** fix
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-access-discipline
- **Gate:** `bash tests/test-five.sh`
- **Notes:** Repaired the fence tracking in the section extractor.

  A hand-written record already covers this task.
  The migration must not overwrite it.

## [TASK-006] Long note that opens with a list

- **Status:** done
- **Type:** refactor
- **Depends:** none
- **Context:** CONTRACT#rules/workplan-access-discipline
- **Gate:** `echo ok`
- **Notes:**
  - split the loader out of the resolver
  - moved slugification next to it
  - deleted the duplicated fence scanner
EOF
}

run() {
  RC=0
  OUT=$(cd "$TMPDIR" && node "$MIGRATE" "$@" 2>&1) || RC=$?
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
assert_file() { [ -f "$TMPDIR/$1" ] || fail "$2 (expected $1 to exist)"; }
assert_no_file() { [ ! -e "$TMPDIR/$1" ] || fail "$2 ($1 should not exist)"; }
in_wp() { grep -q -- "$1" "$TMPDIR/.forge/WORKPLAN.md" || fail "$2"; }
not_in_wp() { if grep -q -- "$1" "$TMPDIR/.forge/WORKPLAN.md"; then fail "$2"; fi; }

echo "Checking migrate-notes.js --dry-run..."

base_workplan
cp "$TMPDIR/.forge/WORKPLAN.md" "$TMPDIR/pristine.md"

run --dry-run
assert_rc 0 "dry run succeeds"
assert_has "TASK-002" "dry run names the task it would migrate"
assert_has "TASK-005" "dry run names every candidate"
assert_lacks "TASK-001" "a 1-line note is not a candidate"
assert_lacks "TASK-003" "a 3-line note is not a candidate — the threshold is *more than* 3"
diff -q "$TMPDIR/pristine.md" "$TMPDIR/.forge/WORKPLAN.md" > /dev/null || fail "dry run must not touch WORKPLAN.md"
assert_no_file ".forge/notes" "dry run must not write records"
assert_no_file ".forge/WORKPLAN.md.bak" "dry run must not take a backup"
echo "  --dry-run writes nothing: OK"

echo "Checking migrate-notes.js (the migration)..."

# TASK-005 carries a hand-written record already. Migration must leave both the
# record and the task's inline notes alone — the one irreversible mistake this
# script could make is overwriting narrative a human wrote.
mkdir -p "$TMPDIR/.forge/notes"
cat > "$TMPDIR/.forge/notes/TASK-005.md" << 'EOF'
# TASK-005 — Long note whose record already exists

## Outcome

Hand-written record, must survive the migration verbatim.
EOF
cp "$TMPDIR/.forge/notes/TASK-005.md" "$TMPDIR/handwritten.md"

run
assert_rc 0 "migration succeeds"
assert_has "TASK-002" "the migrated task is reported"
echo "  migration runs: OK"

# --- the record is written in Task Record Data Model shape ---
assert_file ".forge/notes/TASK-002.md" "a record is written for the oversized task"
REC="$TMPDIR/.forge/notes/TASK-002.md"
grep -q '^# TASK-002 — Long note externalizes$' "$REC" || fail "record title must be '# TASK-XXX — Description'"
grep -q '^## Outcome$' "$REC" || fail "record must carry an Outcome section"
grep -q 'Built the projection layer over the workplan format' "$REC" || fail "the original notes must survive in the record"
grep -q 'The regex approach was rejected' "$REC" || fail "every line of the original notes must survive"
echo "  record shape: OK"

# --- a Files: line in the notes is lifted into the record's Files section ---
grep -q '^## Files$' "$REC" || fail "a Files: line in the notes must become a Files section"
grep -q 'lib/workplan.js' "$REC" || fail "the file list must survive into the record"
grep -q 'scripts/wp.js' "$REC" || fail "every path in the file list must survive"
echo "  Files: line lifted: OK"

# --- the record stands alone without git (CONTRACT#data-model/task-record-data-model) ---
if grep -qi 'see the commit\|see the diff\|git log' "$REC"; then
  fail "a record must not defer to git — Forge runs where .forge/ is never committed"
fi
echo "  record self-sufficiency: OK"

# --- inline residue is a summary plus the path, not a bare pointer ---
grep -q '^- \*\*Notes:\*\* Built the projection layer over the workplan format\. Record: \.forge/notes/TASK-002\.md$' \
  "$TMPDIR/.forge/WORKPLAN.md" || fail "Notes must become 'first sentence. Record: <path>' on one line"
not_in_wp 'The regex approach was rejected' "the externalized body must leave the workplan"
echo "  inline summary + path: OK"

# --- the residue occupies one line: the point of the exercise ---
NOTELINES=$(awk '/^## \[TASK-002\]/,/^## \[TASK-003\]/' "$TMPDIR/.forge/WORKPLAN.md" | grep -c '^  ' || true)
[ "$NOTELINES" = "0" ] || fail "no continuation lines may remain under a migrated task (found $NOTELINES)"
echo "  residue is one line: OK"

# --- notes at or under the threshold are byte-identical ---
in_wp '^- \*\*Notes:\*\* Fixed the off-by-one in the slug matcher; no deviations\.$' \
  "a 1-line note must be left exactly as it was"
in_wp '^  Three lines here\.$' "a 3-line note must keep its continuation lines"
assert_no_file ".forge/notes/TASK-001.md" "no record for a short note"
assert_no_file ".forge/notes/TASK-003.md" "no record at the threshold"
echo "  short notes untouched: OK"

# --- an existing record is never clobbered ---
diff -q "$TMPDIR/handwritten.md" "$TMPDIR/.forge/notes/TASK-005.md" > /dev/null \
  || fail "an existing record must never be overwritten"
in_wp 'The migration must not overwrite it\.' "a skipped task keeps its inline notes"
assert_has "TASK-005" "the skip is reported rather than silent"
echo "  existing record preserved: OK"

# --- a pending task's notes are the executing agent's instructions, not history ---
in_wp 'Do not collapse the passes' "a pending task's notes must survive by default"
assert_no_file ".forge/notes/TASK-004.md" "pending tasks are not migrated by default"
echo "  pending task left alone: OK"

# --- a summary is always generated, even when the notes open with a list ---
assert_file ".forge/notes/TASK-006.md" "a list-shaped note still externalizes"
SUMMARY=$(grep '^## \[TASK-006\]' -A 8 "$TMPDIR/.forge/WORKPLAN.md" | grep '^- \*\*Notes:\*\*')
echo "$SUMMARY" | grep -q 'Record: \.forge/notes/TASK-006\.md' || fail "the record path must be present"
echo "$SUMMARY" | grep -qv '^- \*\*Notes:\*\* Record:' || fail "the summary must not be a bare pointer"
echo "  summary always generated: OK"

echo "Checking safety..."

# --- the backup is the pre-migration file, byte for byte ---
assert_file ".forge/WORKPLAN.md.bak" "a backup is taken before mutating"
diff -q "$TMPDIR/pristine.md" "$TMPDIR/.forge/WORKPLAN.md.bak" > /dev/null \
  || fail ".bak must hold the workplan exactly as it was before migration"
echo "  .bak matches pre-migration state: OK"

# --- the migrated workplan still lints, and wp.js can still read it ---
LINT_RC=0
LINT_OUT=$(cd "$TMPDIR" && node "$CHECK" 2>&1) || LINT_RC=$?
[ "$LINT_RC" = "0" ] || { echo "FAILED: migrated workplan does not pass check-workplan.js"; echo "$LINT_OUT"; exit 1; }
echo "  check-workplan.js after migration: OK"

RC=0
OUT=$(cd "$TMPDIR" && node "$WP" get TASK-002 2>&1) || RC=$?
assert_rc 0 "wp.js can still read the migrated workplan"
assert_has "Record: .forge/notes/TASK-002.md" "the projection surfaces the record path"
echo "  wp.js round-trip: OK"

echo "Checking idempotency..."

cp "$TMPDIR/.forge/WORKPLAN.md" "$TMPDIR/after-first.md"
rm -f "$TMPDIR/.forge/WORKPLAN.md.bak"

run
assert_rc 0 "a second run succeeds"
diff -q "$TMPDIR/after-first.md" "$TMPDIR/.forge/WORKPLAN.md" > /dev/null \
  || fail "a second run must leave WORKPLAN.md byte-identical"
assert_no_file ".forge/WORKPLAN.md.bak" "a no-op run must not take a backup"
assert_has "nothing to migrate" "the no-op case is reported plainly"
echo "  second run is a no-op: OK"

echo "Checking --all..."

base_workplan
rm -rf "$TMPDIR/.forge/notes" "$TMPDIR/.forge/WORKPLAN.md.bak"

run --all
assert_rc 0 "--all succeeds"
assert_file ".forge/notes/TASK-004.md" "--all migrates the pending task too"
not_in_wp 'Do not collapse the passes' "--all externalizes the pending task's notes"
echo "  --all covers every status: OK"

echo "Checking refusal on an unlintable workplan..."

base_workplan
rm -rf "$TMPDIR/.forge/notes" "$TMPDIR/.forge/WORKPLAN.md.bak"
cp "$TMPDIR/.forge/WORKPLAN.md" "$TMPDIR/before-broken.md"
# An unresolvable Context reference is a check-workplan.js error. Migrating a
# workplan that is already broken makes the .bak the only way back, and these
# projects have no git history behind it — refuse instead.
sed 's|CONTRACT#data-model/task-record-data-model|CONTRACT#does-not-exist|' \
  "$TMPDIR/.forge/WORKPLAN.md" > "$TMPDIR/.forge/WORKPLAN.tmp"
mv "$TMPDIR/.forge/WORKPLAN.tmp" "$TMPDIR/.forge/WORKPLAN.md"
cp "$TMPDIR/.forge/WORKPLAN.md" "$TMPDIR/broken.md"

run
assert_rc 1 "a workplan that does not lint is refused"
assert_has "check-workplan" "the refusal names the linter"
diff -q "$TMPDIR/broken.md" "$TMPDIR/.forge/WORKPLAN.md" > /dev/null \
  || fail "a refused migration must leave WORKPLAN.md untouched"
assert_no_file ".forge/notes" "a refused migration must not write records"
echo "  unlintable workplan refused: OK"

run --force
assert_rc 0 "--force overrides the pre-flight lint"
assert_file ".forge/notes/TASK-002.md" "--force proceeds with the migration"
not_in_wp 'The regex approach was rejected' "--force must actually rewrite the workplan, not revert it"
# The post-write lint exists to catch damage this script did. A workplan that
# did not lint beforehand cannot be held to linting afterward, so the still-
# failing lint is reported rather than treated as a reason to revert.
assert_has "warning" "the still-failing lint is surfaced, not swallowed"
echo "  --force overrides: OK"

echo "Checking missing workplan..."

rm -f "$TMPDIR/.forge/WORKPLAN.md"
run
assert_rc 1 "a missing workplan is a usage error"
assert_has "WORKPLAN.md" "the missing file is named"
echo "  missing workplan: OK"

echo "Checking the real workplan (read-only)..."

# --dry-run against the project's own workplan proves the script survives real
# input without mutating the repository it is being developed in.
RC=0
OUT=$(node "$MIGRATE" --dry-run 2>&1) || RC=$?
assert_rc 0 "--dry-run must work on the project's own WORKPLAN.md"
[ ! -e ".forge/WORKPLAN.md.bak" ] || fail "--dry-run must not back up the real workplan"
echo "  real WORKPLAN.md --dry-run: OK"

echo ""
echo "All migrate-notes.js checks passed."
