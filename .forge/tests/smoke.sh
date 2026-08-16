#!/usr/bin/env bash
set -e

# --- Command files exist and reference correct artifacts ---
echo "Checking command files..."

test -s .claude/commands/forge-status.md
grep -q "WORKPLAN" .claude/commands/forge-status.md
echo "  forge-status.md: OK"

test -s .claude/commands/forge-plan.md
grep -q "VISION" .claude/commands/forge-plan.md
grep -q "CONTRACT" .claude/commands/forge-plan.md
grep -qi "manifest\|completeness\|independently" .claude/commands/forge-plan.md
echo "  forge-plan.md: OK"

test -s .claude/commands/forge-next.md
grep -q "WORKPLAN" .claude/commands/forge-next.md
grep -q "template" .claude/commands/forge-next.md
grep -q "gate" .claude/commands/forge-next.md
echo "  forge-next.md: OK"

# --- forge-next.md documents task record externalization ---
echo "Checking record externalization protocol..."

# writes the record to the notes/ path
grep -q '\.forge/notes/TASK-XXX\.md' .claude/commands/forge-next.md
# the 3-line threshold that decides inline vs. externalized
grep -qi "3 lines" .claude/commands/forge-next.md
# all four record sections from the Task Record Data Model
for section in Outcome Decisions Deviations Files; do
  grep -q "## $section" .claude/commands/forge-next.md
done
# inline residue is a summary plus path, not a bare pointer
grep -qi "summary" .claude/commands/forge-next.md
grep -qi "bare pointer" .claude/commands/forge-next.md
# records must stand alone without git history
grep -qi "without git\|stand alone" .claude/commands/forge-next.md
echo "  record externalization: OK"

# --- Commands project the workplan; they never read it in full (TASK-059) ---
# CONTRACT#rules/workplan-access-discipline: /forge-next and /forge-status
# obtain workplan data through wp.js, which returns only what the operation
# needs. Loading the whole workplan into context is a defect, not a default.
echo "Checking workplan access discipline..."

# forge-next acquires the task by projection, and mutates through the same script
grep -q 'wp.js next' .claude/commands/forge-next.md
grep -q 'wp.js set' .claude/commands/forge-next.md
grep -q 'wp.js append-notes' .claude/commands/forge-next.md
# and no longer instructs the agent to read the file in full
if grep -qi 'in full' .claude/commands/forge-next.md; then
  echo "  FAIL: forge-next.md still speaks of reading WORKPLAN.md in full"
  exit 1
fi
# every selection rule from CONTRACT#interfaces/command-forge-next survives the
# move into the script — the projection must still surface them to the human
grep -qi 'unmet dep' .claude/commands/forge-next.md
grep -qi 'one task can be active\|one active task' .claude/commands/forge-next.md
grep -qi 'resum' .claude/commands/forge-next.md
grep -q 'check-workplan.js' .claude/commands/forge-next.md
echo "  forge-next.md projection: OK"

# forge-status is a script invocation plus formatting — no in-context parsing
grep -q 'wp.js status' .claude/commands/forge-status.md
if grep -qi 'in full' .claude/commands/forge-status.md; then
  echo "  FAIL: forge-status.md still speaks of reading WORKPLAN.md in full"
  exit 1
fi
# the report format from CONTRACT#interfaces/command-forge-status is unchanged
grep -q 'Forge Status' .claude/commands/forge-status.md
grep -q 'Progress:' .claude/commands/forge-status.md
grep -qi 'next unblocked' .claude/commands/forge-status.md
grep -qi 'clarify' .claude/commands/forge-status.md
grep -qi 'observation' .claude/commands/forge-status.md
grep -qi 'read-only' .claude/commands/forge-status.md
echo "  forge-status.md projection: OK"

# --- WORKPLAN.md task format is parseable ---
echo "Checking WORKPLAN.md format..."

test -s .forge/WORKPLAN.md
grep -q "Status:" .forge/WORKPLAN.md
grep -q "Type:" .forge/WORKPLAN.md
grep -q "Depends:" .forge/WORKPLAN.md
grep -q "Context:" .forge/WORKPLAN.md
grep -q "Gate:" .forge/WORKPLAN.md
echo "  WORKPLAN.md: OK"

# --- gate assertions can tell instruction from embedded payload ---
# Four gates depend on prose.js; smoke.sh runs in most of them, so its
# correctness is checked wherever they are.
echo "Checking prose.js..."
bash .forge/tests/test-prose.sh > /dev/null
echo "  prose.js: OK"

# --- settings.json is valid JSON with hook config ---
echo "Checking settings.json..."

node -e "JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8'))"
grep -q "PostToolUse" .claude/settings.json
echo "  settings.json: OK"

# --- CLAUDE.md has the integration block ---
echo "Checking CLAUDE.md..."

test -s CLAUDE.md
grep -q "Pipeline:" CLAUDE.md
grep -q "Workflow:" CLAUDE.md
grep -q "Do not modify CONTRACT.md" CLAUDE.md
echo "  CLAUDE.md: OK"

echo ""
echo "All checks passed."
