#!/usr/bin/env bash
set -e

# Validates .forge/scripts/check-workplan.js against CONTRACT#rules/workplan-lint's
# 7 invariants (TASK-025). Two things this script deliberately checks beyond the
# obvious pass/fail:
#   - "done" tasks are frozen history: a file-order violation (invariant 2) or a
#     cycle (invariant 3) confined entirely to done tasks prints a warning but
#     does not fail the build. The same violation on a pending/active task fails.
#   - Invariant 3 (whole-graph cycle detection) is not subsumed by invariant 2
#     (file-order, scoped to pending/active): a cycle confined to done tasks
#     escapes invariant 2 entirely, so invariant 3 must catch it independently.

SCRIPT="$(pwd)/.forge/scripts/check-workplan.js"
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.forge"

# Minimal contract with two resolvable sections, shared by every synthetic fixture.
cat > "$TMPDIR/.forge/CONTRACT.md" << 'EOF'
# Contract

## Data Model

### Context Manifest

Fixture content.

## Rules

### Workplan Lint

Fixture content.
EOF

# A task record in Task Record Data Model shape, so `notes/TASK-XXX#section`
# references have something to resolve against (CONTRACT#data-model/task-record-data-model).
mkdir -p "$TMPDIR/.forge/notes"
cat > "$TMPDIR/.forge/notes/TASK-029.md" << 'EOF'
# TASK-029 — Fixture record

## Outcome

Fixture content.

## Decisions

Fixture content.

## Deviations

Fixture content.

## Files

Fixture content.
EOF

run_fixture() {
  local description="$1"
  local expect_exit="$2"
  local workplan_content="$3"
  local grep_for="${4:-}"

  printf '%s\n' "$workplan_content" > "$TMPDIR/.forge/WORKPLAN.md"

  local output
  local actual_exit=0
  output=$(cd "$TMPDIR" && node "$SCRIPT" 2>&1) || actual_exit=$?

  if [ "$actual_exit" != "$expect_exit" ]; then
    echo "FAILED: $description (expected exit $expect_exit, got $actual_exit)"
    echo "--- output ---"
    echo "$output"
    rm -rf "$TMPDIR"
    exit 1
  fi

  if [ -n "$grep_for" ] && ! echo "$output" | grep -qi "$grep_for"; then
    echo "FAILED: $description (expected output to mention \"$grep_for\")"
    echo "--- output ---"
    echo "$output"
    rm -rf "$TMPDIR"
    exit 1
  fi

  echo "OK: $description"
}

# --- 0. Clean workplan: proper order, done->feature with test-invoking gate ---
CLEAN=$(cat <<'EOF'
# Workplan

## [TASK-001] Bootstrap

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**

## [TASK-002] Build feature

- **Status:** pending
- **Type:** feature
- **Depends:** TASK-001
- **Context:** CONTRACT#rules/workplan-lint
- **Gate:** `bash .forge/tests/fake.sh`
- **Notes:**
EOF
)
run_fixture "clean workplan passes" 0 "$CLEAN"

# --- 1. Missing required field (Gate) ---
MISSING_FIELD=$(cat <<'EOF'
# Workplan

## [TASK-001] Missing gate field

- **Status:** pending
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Notes:**
EOF
)
run_fixture "missing required field fails" 1 "$MISSING_FIELD" "Gate"

# --- 2. Invalid enum value (bad Status) ---
BAD_ENUM=$(cat <<'EOF'
# Workplan

## [TASK-001] Bad status value

- **Status:** in-progress
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "invalid Status enum fails" 1 "$BAD_ENUM" "Status"

# --- 3. Unknown dep (dangling reference) ---
UNKNOWN_DEP=$(cat <<'EOF'
# Workplan

## [TASK-001] References missing task

- **Status:** pending
- **Type:** scaffold
- **Depends:** TASK-999
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "dangling Depends reference fails" 1 "$UNKNOWN_DEP" "nonexistent"

# --- 4. Forward dep on a pending task (file-order violation, non-done -> error) ---
FORWARD_DEP=$(cat <<'EOF'
# Workplan

## [TASK-001] Depends on a later task

- **Status:** pending
- **Type:** scaffold
- **Depends:** TASK-002
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**

## [TASK-002] Comes after

- **Status:** pending
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "forward dependency on pending task fails" 1 "$FORWARD_DEP" "earlier in the file"

# --- 5. Done-task self-dep is a file-order WARNING, not an error ---
DONE_SELF_DEP=$(cat <<'EOF'
# Workplan

## [TASK-001] Done task with self dependency typo

- **Status:** done
- **Type:** scaffold
- **Depends:** TASK-001
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "done-task file-order violation is a warning" 0 "$DONE_SELF_DEP" "warning"

# --- 6. Cycle involving a pending task -> error ---
PENDING_CYCLE=$(cat <<'EOF'
# Workplan

## [TASK-001] Cycle A

- **Status:** pending
- **Type:** scaffold
- **Depends:** TASK-002
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**

## [TASK-002] Cycle B

- **Status:** pending
- **Type:** scaffold
- **Depends:** TASK-001
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "cycle involving pending tasks fails" 1 "$PENDING_CYCLE" "cycle"

# --- 7. Cycle confined entirely to done tasks -> warning, not an error ---
# This is the case invariant 2 cannot catch on its own (file-order is scoped to
# pending/active), so invariant 3's whole-graph cycle detection must run independently.
DONE_CYCLE=$(cat <<'EOF'
# Workplan

## [TASK-001] Done cycle A

- **Status:** done
- **Type:** scaffold
- **Depends:** TASK-002
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**

## [TASK-002] Done cycle B

- **Status:** done
- **Type:** scaffold
- **Depends:** TASK-001
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "cycle confined to done tasks is a warning" 0 "$DONE_CYCLE" "cycle"

# --- 8. Two active tasks -> error ---
TWO_ACTIVE=$(cat <<'EOF'
# Workplan

## [TASK-001] First active

- **Status:** active
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**

## [TASK-002] Second active

- **Status:** active
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "two active tasks fails" 1 "$TWO_ACTIVE" "active"

# --- 9. Unresolvable Context reference -> error ---
BAD_CONTEXT=$(cat <<'EOF'
# Workplan

## [TASK-001] Bad context ref

- **Status:** pending
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#nonexistent-section
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "unresolvable Context reference fails" 1 "$BAD_CONTEXT" "Context reference"

# --- 10. Feature gate without a test command, targeting real code -> error ---
FEATURE_NO_TEST=$(cat <<'EOF'
# Workplan

## [TASK-001] Feature with structural-only gate on code

- **Status:** pending
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `grep -q "foo" src/app.js && echo ok`
- **Notes:**
EOF
)
run_fixture "feature gate without test command fails" 1 "$FEATURE_NO_TEST" "test command"

# --- 10b. A root-level test.sh IS a test command (OBS-020, TASK-105) ---
# hasTestInvocation recognized tests/ and test-*.sh but not the equally common
# root-level test.sh, so a project using that convention could not satisfy
# invariant 6 for any feature or fix task without renaming its runner — the
# lint dictating project layout rather than checking for a test.
FEATURE_ROOT_TEST_SH=$(cat <<'EOF'
# Workplan

## [TASK-001] Feature gated by a root-level test.sh

- **Status:** pending
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `bash test.sh && grep -q "foo" src/app.js`
- **Notes:**
EOF
)
run_fixture "root-level test.sh satisfies invariant 6" 0 "$FEATURE_ROOT_TEST_SH"

FEATURE_DOT_SLASH_TEST_SH=$(cat <<'EOF'
# Workplan

## [TASK-001] Feature gated by ./test.sh

- **Status:** pending
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `./test.sh && grep -q "foo" src/app.js`
- **Notes:**
EOF
)
run_fixture "./test.sh satisfies invariant 6" 0 "$FEATURE_DOT_SLASH_TEST_SH"

# The other direction, so the invariant is not widened into uselessness: a word
# merely ending in the same characters is not a test runner.
FEATURE_FAKE_TEST_SH=$(cat <<'EOF'
# Workplan

## [TASK-001] Feature whose gate only looks like a test runner

- **Status:** pending
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `grep -q "latest.sh" src/app.js && echo ok`
- **Notes:**
EOF
)
run_fixture "a word ending in test.sh is not a test command" 1 "$FEATURE_FAKE_TEST_SH" "test command"

# --- 11. Feature gate without a test command, but deliverable is a markdown
#     artifact (Gate Patterns sanctions structural checks here) -> exempt, passes ---
FEATURE_MARKDOWN=$(cat <<'EOF'
# Workplan

## [TASK-001] Feature producing a markdown artifact

- **Status:** pending
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `test -s .claude/commands/foo.md && grep -q "bar" .claude/commands/foo.md && echo ok`
- **Notes:**
EOF
)
run_fixture "feature gate on markdown-only deliverable is exempt" 0 "$FEATURE_MARKDOWN"

# --- 12. Checkpoint gate missing the manual: prefix -> error ---
CHECKPOINT_NO_MANUAL=$(cat <<'EOF'
# Workplan

## [TASK-001] Checkpoint missing manual prefix

- **Status:** pending
- **Type:** checkpoint
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo review complete`
- **Notes:**
EOF
)
run_fixture "checkpoint gate without manual: prefix fails" 1 "$CHECKPOINT_NO_MANUAL" "manual:"

# --- 13. Duplicate task ID -> error ---
DUPLICATE_ID=$(cat <<'EOF'
# Workplan

## [TASK-001] First one

- **Status:** pending
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**

## [TASK-001] Duplicate ID

- **Status:** pending
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "duplicate task ID fails" 1 "$DUPLICATE_ID" "Duplicate"

# --- 14. notes/TASK-XXX#section resolves as a Context reference ---
# The record namespace needs no new resolution code: createLoader joins the
# prefix onto .forge/, so `notes/TASK-029` loads .forge/notes/TASK-029.md by the
# same path that makes `specs/name#` work. This fixture is what makes that a
# verified property rather than an assumption.
NOTES_REF=$(cat <<'EOF'
# Workplan

## [TASK-001] Consumes a prior task record

- **Status:** pending
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#data-model/context-manifest, notes/TASK-029#deviations
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "notes/TASK-XXX#section reference resolves" 0 "$NOTES_REF"

# --- 15. notes/ reference to a missing record file -> error ---
NOTES_MISSING_FILE=$(cat <<'EOF'
# Workplan

## [TASK-001] References a record that does not exist

- **Status:** pending
- **Type:** scaffold
- **Depends:** none
- **Context:** notes/TASK-999#outcome
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "notes/ reference to a missing record fails" 1 "$NOTES_MISSING_FILE" "notes/TASK-999.md not found"

# --- 16. notes/ reference to a missing section within an existing record -> error ---
NOTES_MISSING_SECTION=$(cat <<'EOF'
# Workplan

## [TASK-001] References a section the record lacks

- **Status:** pending
- **Type:** scaffold
- **Depends:** none
- **Context:** notes/TASK-029#nonexistent-section
- **Gate:** `echo ok`
- **Notes:**
EOF
)
run_fixture "notes/ reference to a missing section fails" 1 "$NOTES_MISSING_SECTION" "no heading matching"

rm -rf "$TMPDIR"

# --- 17. The real current .forge/WORKPLAN.md must pass, warning-free. It once
#     carried two done-task self-deps (TASK-012, TASK-014) that surfaced as four
#     non-blocking frozen-history warnings; those were typos, not history, and
#     have been corrected. The warning-not-error behavior they used to
#     demonstrate is covered by fixtures 5 and 7 above, which is where it
#     belongs — a live-file accident is not a test. ---
echo ""
echo "Real workplan: exit 0 expected..."
node "$SCRIPT"
echo "  OK"

echo ""
echo "All check-workplan.js fixtures passed."
