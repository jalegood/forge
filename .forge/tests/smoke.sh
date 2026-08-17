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

test -s .claude/commands/forge-spec.md
grep -q "SPEC" .claude/commands/forge-spec.md
grep -q "STATUS.md" .claude/commands/forge-spec.md
grep -q "check-spec" .claude/commands/forge-spec.md
echo "  forge-spec.md: OK"

# --- /forge-spec interviews before it drafts (TASK-032) ---
# CONTRACT#interfaces/command-forge-spec makes the intake interview the point of
# the command: an unasked question becomes an assumption propagated into every
# task the spec generates. SPEC req-intake-coverage sets the bar as adaptive
# rather than checklist-driven, and req-intake-disqualification makes an unasked
# plan-blocking unknown withhold the draft. Asserted through prose.js because the
# file fences a spec skeleton, a STATUS.md row, and shell commands — a match
# inside any of those would report the instruction present when only the sample
# was.
echo "Checking forge-spec intake contract..."

# the interview runs before drafting, not alongside it
node .forge/scripts/prose.js .claude/commands/forge-spec.md "interview" "before draft|before you draft|before drafting"
# all five intake categories are named
node .forge/scripts/prose.js .claude/commands/forge-spec.md \
  "target user" "success criteria" "edge case" "integration point" "non-goal"
# adaptive, not a checklist: a category the input already answers is not re-asked
node .forge/scripts/prose.js .claude/commands/forge-spec.md "already answers|already answered" "ceremony"
# an unasked, unannotated plan-blocking unknown withholds the draft
node .forge/scripts/prose.js .claude/commands/forge-spec.md "plan-blocking" "withhold|disqualif"
# both annotation forms, and the STATUS.md Open Questions handoff for unknowns
node .forge/scripts/prose.js .claude/commands/forge-spec.md "ASSUMED" "UNRESOLVED" "Open Questions"
# drafts to the SPEC Data Model, in EARS form
node .forge/scripts/prose.js .claude/commands/forge-spec.md "EARS" "SHALL" "Non-Goals"
# split threshold for per-feature spec files
node .forge/scripts/prose.js .claude/commands/forge-spec.md "specs/" "300"
# the readiness gate is run by the command, not left to the human
node .forge/scripts/prose.js .claude/commands/forge-spec.md "check-spec.js"
# CONTRACT stays read-only — SPEC owns behavior, CONTRACT owns constraints
node .forge/scripts/prose.js .claude/commands/forge-spec.md "never (writes|modifies)[^.]*CONTRACT.md"
echo "  forge-spec.md intake: OK"

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

# --- /forge-status surfaces the human-authored STATUS.md items (TASK-033) ---
# CONTRACT#interfaces/command-forge-status requires the report to surface open
# questions (flagging any marked Blocking) and blockers, read from STATUS.md
# itself — wp.js projects the workplan and the Observations table, not these two.
# CONTRACT#data-model/status.md-data-model makes the integration mandatory: a
# status file nothing reads goes stale.
#
# Asserted through prose.js, not grep: forge-status.md fences its output-format
# template, and that fence already contains "Open questions:" and "Blockers:".
# A plain grep would match the sample and report the instruction present when
# only the example was — the exact failure prose.js exists to prevent, and the
# reason the task's own `grep -q "STATUS.md"` gate is not sufficient on its own.
echo "Checking forge-status STATUS.md surfacing..."

# both tables are read, and the read is conditional on the file being present
node .forge/scripts/prose.js .claude/commands/forge-status.md \
  "STATUS\.md" "Open Questions" "Blockers" "exists|when present"
# Blocking questions are flagged, not merely listed
node .forge/scripts/prose.js .claude/commands/forge-status.md "flag[a-z]*[^.]*Blocking"
# questions are surfaced by ID: every other row in this report carries its
# identifier (TASK-XXX, OBS-X), and a question the human cannot name is one they
# cannot hand to a clarify task
node .forge/scripts/prose.js .claude/commands/forge-status.md "by its ID|by ID"
grep -q 'Q-XXX' .claude/commands/forge-status.md
# Observations arrive from the projection; re-reading the table would double-report
node .forge/scripts/prose.js .claude/commands/forge-status.md "not re-read|do not re-read"
# surfacing STATUS.md must not turn a read-only command into a writer
node .forge/scripts/prose.js .claude/commands/forge-status.md \
  "Read-only|read-only" "no file modifications|No side effects|never writes"
echo "  forge-status.md STATUS.md surfacing: OK"

# --- Observation read paths (TASK-055) ---
# CONTRACT#data-model/status.md-data-model names the observation readers, and two
# of them read differently on purpose: /forge-status lists every open row with
# foundation severity first, while /forge-plan plans only rows a human has
# triaged to `accepted`. The disposition distinction is the whole deliverable — a
# planner that consumed open rows would let an agent's own observation become
# work no human agreed to, which the same section forbids outright.
#
# Asserted through prose.js, not grep: both files fence example output and task
# blocks, and a match inside a fence would show the instruction present when only
# the sample was.
echo "Checking observation read paths..."

node .forge/scripts/prose.js .claude/commands/forge-status.md "observation" "foundation"

node .forge/scripts/prose.js .claude/commands/forge-plan.md "observation" "accepted" "declined"
# intake is the secondary loop closure; /forge-next is the one that runs every session
node .forge/scripts/prose.js .claude/commands/forge-plan.md "secondary|never the only path"
echo "  observation read paths: OK"

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

# --- Context references resolve to the sections they name ---
# lib/markdown.js backs check-workplan.js invariant 5, check-ux-spec.js, and
# /forge-next's manifest resolution. A silent regression there makes every
# manifest unreliable at once, so its test runs wherever smoke.sh runs.
echo "Checking markdown.js..."
bash .forge/tests/test-markdown.sh > /dev/null
echo "  markdown.js: OK"

# --- Every prompt template carries the observation step ---
# CONTRACT#interfaces/prompt-template-interface makes the step mandatory in
# every template, and the templates embedded in /forge-init are not diffed
# against the live ones — so both copies are checked here, where every gate
# that runs smoke.sh picks it up.
echo "Checking prompt templates..."
bash .forge/tests/test-templates.sh > /dev/null
echo "  templates: OK"

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
