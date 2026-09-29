#!/usr/bin/env bash
set -e

# Validates .forge/scripts/obs.js — the sole writer of STATUS.md's Observations
# table (TASK-083, CONTRACT#interfaces/observation-script).
#
# Fixture discipline per TASK-056: a fixture that would pass with the feature
# reverted proves nothing. So the transition fixture attempts a genuinely
# invalid transition (not one that merely looks wrong), the sweep fixture
# includes a planned: row whose task is NOT done and asserts it survives, and
# the escaping fixture writes text containing a literal pipe and then reads it
# back through the parser — the round trip is the assertion, because a bare
# pipe in a cell is exactly what silently removes a row from every reader.

SCRIPT="$(pwd)/.forge/scripts/obs.js"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
mkdir -p "$TMPDIR/.forge/scripts"

# obs.js resolves the project root by walking up to the nearest .forge, and
# shells out to check-status.js next to itself — so the fixture needs its own
# copies of the scripts to keep the lint pointed at the fixture's STATUS.md.
cp .forge/scripts/obs.js .forge/scripts/check-status.js "$TMPDIR/.forge/scripts/"
mkdir -p "$TMPDIR/.forge/scripts/lib"
cp .forge/scripts/lib/markdown.js .forge/scripts/lib/workplan.js "$TMPDIR/.forge/scripts/lib/"
OBS="$TMPDIR/.forge/scripts/obs.js"

cat > "$TMPDIR/.forge/CONTRACT.md" << 'EOF'
# Contract

## Rules

Fixture.
EOF

cat > "$TMPDIR/.forge/WORKPLAN.md" << 'EOF'
# Workplan

## [TASK-001] A finished task

- **Status:** done
- **Type:** scaffold
- **Depends:** none
- **Context:** CONTRACT#rules
- **Gate:** `echo ok`
- **Notes:**

## [TASK-002] An unfinished task

- **Status:** pending
- **Type:** feature
- **Depends:** none
- **Context:** CONTRACT#rules
- **Gate:** `bash tests/none.sh`
- **Notes:**
EOF

base_status() {
  cat > "$TMPDIR/.forge/STATUS.md" << 'EOF'
# Status

## Open Questions

| ID | Question | Blocking? | Raised |
| -- | -------- | --------- | ------ |

## Decisions

### 2026-08-01 — Fixture decision

Body.

**Why:** reasons.

**Rejected alternatives:** none.

## Risks

| Risk | Impact | Mitigation |
| ---- | ------ | ---------- |

## Blockers

| Blocker | Blocking tasks | Needs |
| ------- | -------------- | ----- |

## Observations

| ID | Date | Raised by | Kind | Severity | Observation | Disposition |
| -- | ---- | --------- | ---- | -------- | ----------- | ----------- |
| OBS-001 | 2026-08-01 | TASK-001 | design | normal | An early finding. | open |
EOF
}

run() {
  RC=0
  OUT=$(cd "$TMPDIR" && node "$OBS" "$@" 2>&1) || RC=$?
}

fail() { echo "FAILED: $1"; echo "--- output ---"; echo "$OUT"; exit 1; }
assert_rc()   { [ "$RC" = "$1" ] || fail "$2 (expected exit $1, got $RC)"; }
assert_has()  { echo "$OUT" | grep -qi -- "$1" || fail "$2 (expected output to mention \"$1\")"; }
assert_file() { grep -q -- "$1" "$TMPDIR/.forge/STATUS.md" || fail "$2"; }

echo "Checking obs.js add..."
base_status
run add --kind bug --severity normal --task TASK-002 "A new finding."
assert_rc 0 "add succeeds"
assert_has "OBS-002" "the minted ID is reported"
assert_file "| OBS-002 |" "the row was written"
assert_file "| open |" "new rows are open"
# The date is stamped by the script, not passed in, and it is the LOCAL date —
# the same calendar day the shell reports, not a UTC day that can already be
# tomorrow for anyone west of UTC.
grep -q "| OBS-002 | $(date +%Y-%m-%d) |" "$TMPDIR/.forge/STATUS.md" || fail "add must stamp today's local date"

# Stamping and ageing must agree. They are computed in different places
# (obs.js today() and obs.js/check-status.js ageDays), and a mismatched
# timezone convention between them is invisible except for a few hours a day —
# a row written this second must read as zero days old.
run list --json
node -e '
  const d = JSON.parse(process.argv[1]);
  const r = d.observations.find(o => o.id === "OBS-002");
  if (!r) throw new Error("OBS-002 missing from the projection");
  if (r.ageDays !== 0) {
    throw new Error("a row stamped now reports ageDays=" + r.ageDays +
      " — today() and ageDays() disagree about the timezone");
  }
' "$OUT" || fail "the date stamp and the age computation must use the same calendar"
echo "  add: OK"

# --- escaping round trip: a literal pipe must survive as content ---
run add --kind scope --severity normal --task TASK-001 "Text with a | pipe in it."
assert_rc 0 "add with a pipe succeeds"
node -e '
  const md = require(process.argv[1]);
  const fs = require("fs");
  const text = fs.readFileSync(process.argv[2], "utf8");
  const body = text.slice(text.indexOf("## Observations"));
  const t = md.parseTable(body);
  if (!t.ok) { console.error("FAIL: table did not parse after add: " + JSON.stringify(t.errors)); process.exit(1); }
  const row = t.rows.find(r => r.cells["ID"] === "OBS-003");
  if (!row) { console.error("FAIL: OBS-003 vanished from the parse — the pipe was not escaped"); process.exit(1); }
  if (!/Text with a \| pipe in it\./.test(row.cells["Observation"])) {
    console.error("FAIL: pipe did not round-trip: " + row.cells["Observation"]); process.exit(1);
  }
' "$(pwd)/.forge/scripts/lib/markdown.js" "$TMPDIR/.forge/STATUS.md" || exit 1
echo "  add escapes pipes (round trip through the parser): OK"

# --- invalid enum values are refused ---
run add --kind vibes --severity normal --task TASK-001 "Nope."
assert_rc 1 "an invalid kind is refused"
run add --kind bug --severity urgent --task TASK-001 "Nope."
assert_rc 1 "an invalid severity is refused"
run add --kind bug --severity normal --task NOPE "Nope."
assert_rc 1 "an invalid task reference is refused"
echo "  add validates its arguments: OK"

echo "Checking obs.js set (lifecycle transitions)..."
base_status
run set OBS-001 disposition accepted
assert_rc 0 "open -> accepted is allowed"
assert_file "| accepted |" "the transition was written"

run set OBS-001 disposition planned:TASK-002
assert_rc 0 "accepted -> planned: is allowed"

# A genuinely invalid transition: planned: -> accepted is not in the lifecycle.
run set OBS-001 disposition accepted
assert_rc 1 "planned: -> accepted is refused"
assert_has "transition" "the refusal explains itself"
grep -q "| planned:TASK-002 |" "$TMPDIR/.forge/STATUS.md" || fail "a refused transition must leave the row unchanged"
echo "  set: OK"

# --- a planned: link to a task that does not exist is caught by the lint ---
base_status
run set OBS-001 disposition accepted
run set OBS-001 disposition planned:TASK-999
assert_rc 1 "planned: naming a nonexistent task is rejected by the lint"
assert_has "revert" "the write was reverted"
grep -q "| accepted |" "$TMPDIR/.forge/STATUS.md" || fail "the reverted file must hold the pre-write value"
echo "  set write-lint-revert: OK"

echo "Checking obs.js list..."
base_status
run list --json
assert_rc 0 "list --json succeeds"
node -e '
  const d = JSON.parse(process.argv[1]);
  if (!d.ok || !Array.isArray(d.observations)) throw new Error("shape");
  const r = d.observations[0];
  if (r.id !== "OBS-001") throw new Error("id");
  if (typeof r.ageDays !== "number") throw new Error("ageDays must be computed");
' "$OUT" || fail "list --json shape"
run list --disposition open
assert_rc 0 "list --disposition succeeds"
assert_has "OBS-001" "the open row is listed"
echo "  list: OK"

echo "Checking obs.js sweep..."
base_status
# OBS-001 -> planned:TASK-001 (done, must close); a second row planned against
# TASK-002 (pending, must survive) — without it, "closes everything" would pass.
run set OBS-001 disposition accepted
run set OBS-001 disposition planned:TASK-001
run add --kind bug --severity normal --task TASK-002 "Still in flight."
run set OBS-002 disposition accepted
run set OBS-002 disposition planned:TASK-002

run sweep
assert_rc 0 "sweep reports without applying"
assert_has "OBS-001" "the closable row is reported"
grep -q "| planned:TASK-001 |" "$TMPDIR/.forge/STATUS.md" || fail "sweep without --apply must not write"

run sweep --apply
assert_rc 0 "sweep --apply succeeds"
grep -q "| OBS-001 | .* | closed |" "$TMPDIR/.forge/STATUS.md" || fail "sweep must close a planned: row whose task is done"
grep -q "| planned:TASK-002 |" "$TMPDIR/.forge/STATUS.md" || fail "sweep must NOT close a planned: row whose task is pending"
echo "  sweep closes only what is provably resolved: OK"

# --- sweep reports duplicates and unlinked accepted rows, judgment-free ---
base_status
run add --kind design --severity normal --task TASK-001 "An early finding."
run set OBS-002 disposition accepted
run sweep
assert_rc 0 "sweep with duplicates succeeds"
assert_has "duplicate" "exact-duplicate text is reported"
assert_has "accepted" "unlinked accepted rows are reported"
grep -q "| accepted |" "$TMPDIR/.forge/STATUS.md" || fail "sweep must not disposition an accepted row itself"
echo "  sweep reports what needs judgment, applies none of it: OK"

echo "Checking obs.js refuses a malformed table..."
base_status
printf '| OBS-002 | 2026-08-02 | TASK-001 | bug | normal | An unescaped | pipe. | open |\n' >> "$TMPDIR/.forge/STATUS.md"
run list
assert_rc 1 "a malformed table is refused, not silently partially read"
assert_has "malformed" "the refusal names the problem"
echo "  malformed table refused: OK"

echo ""
echo "All obs.js checks passed."
