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

# --- WORKPLAN.md task format is parseable ---
echo "Checking WORKPLAN.md format..."

test -s .forge/WORKPLAN.md
grep -q "Status:" .forge/WORKPLAN.md
grep -q "Type:" .forge/WORKPLAN.md
grep -q "Depends:" .forge/WORKPLAN.md
grep -q "Context:" .forge/WORKPLAN.md
grep -q "Gate:" .forge/WORKPLAN.md
echo "  WORKPLAN.md: OK"

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
