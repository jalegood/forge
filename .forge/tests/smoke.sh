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
# The probe-refusal handling (TASK-075): exit 4 is documented with both routes
# out — repair the gate in this task's diff, or report absorbed scope — and
# --force stays the human's. prose.js so a fenced example cannot satisfy it.
node .forge/scripts/prose.js .claude/commands/forge-next.md \
  "gate-discrimination probe" "vacuous" "scope finding|absorbed" "Never pass \`--force\`"
echo "  forge-next.md: OK"

test -s .claude/commands/forge-spec.md
grep -q "SPEC" .claude/commands/forge-spec.md
grep -q "STATUS.md" .claude/commands/forge-spec.md
grep -q "check-spec" .claude/commands/forge-spec.md
echo "  forge-spec.md: OK"

test -s .claude/commands/forge-sync.md
grep -q "VERSION" .claude/commands/forge-sync.md
grep -qi "forge-managed" .claude/commands/forge-sync.md
echo "  forge-sync.md: OK"

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

# --- /forge-plan inserts checkpoint tasks at cadence (TASK-036) ---
# CONTRACT#rules/checkpoint-cadence: a checkpoint lands at each dependency-phase
# boundary or after every 5 consecutive non-checkpoint tasks, whichever comes
# first. Its Depends names the whole span, and downstream tasks depend on the
# checkpoint, so the DAG halts there until a human passes the packet. A plan
# generated without them runs unattended to the end of the workplan with no
# review point — the exact failure the rule exists to prevent.
#
# Asserted through prose.js, not grep: forge-plan.md fences its task-format
# block, whose Type line already lists `checkpoint` in the enum. A plain grep
# would match that fenced template and report the generation rule present when
# only the enum was.
echo "Checking forge-plan checkpoint cadence..."

# the cadence itself — both triggers, which one wins, and what gets counted
node .forge/scripts/prose.js .claude/commands/forge-plan.md \
  "checkpoint" "cadence" "phase boundary" "non-checkpoint" \
  "every 5|every five" "whichever comes first"
# the span travels in Depends, and downstream work waits on the checkpoint
node .forge/scripts/prose.js .claude/commands/forge-plan.md \
  "Depends[^.]*every task|every task[^.]*Depends" "depend[^.]*on the checkpoint"
# checkpoint gates are manual: — check-workplan.js invariant 7 rejects anything else
node .forge/scripts/prose.js .claude/commands/forge-plan.md "checkpoint[^.]*manual:"
# checkpoint is a generatable task type here, not just a name in the fenced enum
node .forge/scripts/prose.js .claude/commands/forge-plan.md \
  "review packet" "produces no code"
echo "  forge-plan.md checkpoint cadence: OK"

# --- /forge-next executes checkpoint tasks as a review packet (TASK-037) ---
# CONTRACT#interfaces/command-forge-next: when the selected task's Type is
# `checkpoint`, execution means assembling the review packet described in
# CONTRACT#rules/checkpoint-cadence, the gate is always `manual:`, and a block
# appends a STATUS.md Blockers row. SPEC req-checkpoint-fresh-gates adds that
# every automated gate in the span is re-run at packet-assembly time and reported
# with its real output, because a later task in the span can silently break an
# earlier task's gate — task status alone is not evidence.
#
# Asserted through prose.js, not grep: forge-next.md fences the wp.js output
# block, whose Type line already lists `checkpoint` in the enum. The task's own
# `grep -qi "checkpoint"` gate matches that fenced enum and passes with no work
# done — these assertions are what actually holds the deliverable.
echo "Checking forge-next checkpoint execution..."

# execution is packet assembly, and the span is exactly Depends — not a git-log
# guess at "everything since the last checkpoint"
node .forge/scripts/prose.js .claude/commands/forge-next.md \
  "review packet" "span is[^.]*Depends|Depends[^.]*is the span"
# every packet element CONTRACT#rules/checkpoint-cadence requires
node .forge/scripts/prose.js .claude/commands/forge-next.md \
  "file list" "Open Questions" "Risks" "rollback"
# SPEC req-checkpoint-fresh-gates: re-run at assembly time, reported with output
node .forge/scripts/prose.js .claude/commands/forge-next.md \
  "re-run every[^.]*gate" "fresh" "actual output"
# a gate failing fresh on a `done` task is a regression, flagged explicitly, and
# a span containing one is never summarized as clean
node .forge/scripts/prose.js .claude/commands/forge-next.md \
  "regression" "never[^.]*clean|not[^.]*as clean"
# manual: gates inside the span are listed with their steps, never executed
node .forge/scripts/prose.js .claude/commands/forge-next.md "not execut"
# the checkpoint's own gate is always manual: — step 7 runs no shell command here
node .forge/scripts/prose.js .claude/commands/forge-next.md "always[^.]*manual:" "pass/fail"
# on fail: a STATUS.md Blockers row, and the fix tasks are the human's to add
node .forge/scripts/prose.js .claude/commands/forge-next.md \
  "Blockers" "fix.{0,12}task" "not add|never add"
# a checkpoint halts the loop — no chaining into the next task in this session
node .forge/scripts/prose.js .claude/commands/forge-next.md \
  "hard stop|halt" "do not select|not select further|select no further"
echo "  forge-next.md checkpoint execution: OK"

# --- /forge-sync updates Forge-managed files, never project-owned ones (TASK-038) ---
# CONTRACT#interfaces/command-forge-sync: sync reads .forge/VERSION (line 1
# engine version, line 2 canonical repo URL), fetches the canonical copies of
# the three Forge-managed globs, classifies each local file, applies only what
# the human approves file by file, and never touches a project-owned artifact.
# That last rule is the load-bearing one: overwriting CONTRACT.md or WORKPLAN.md
# destroys work no upstream copy can restore, so the untouchable set is asserted
# name by name rather than as one phrase that a single edit could hollow out.
#
# Asserted through prose.js, not grep: forge-sync.md fences the VERSION format,
# the per-file summary output, and shell commands. The task's own gate
# (`grep -q "VERSION"`, `grep -qi "never"`) matches inside any of those fences
# and passes with no work done — these assertions are what actually holds it.
echo "Checking forge-sync contract..."

# reads the version stamp, and knows what each of its two lines carries
node .forge/scripts/prose.js .claude/commands/forge-sync.md \
  "\.forge/VERSION" "engine version" "canonical" "repo|repository"
# the three Forge-managed globs it is allowed to fetch and replace
node .forge/scripts/prose.js .claude/commands/forge-sync.md \
  "commands/forge-|forge-\*\.md" "templates/" "check-"
# all four per-file classifications from the Contract
node .forge/scripts/prose.js .claude/commands/forge-sync.md \
  "unchanged" "local-only|local customization" "upstream-updated|upstream update" "conflict"
# approval is per file, and a local customization is never silently overwritten
node .forge/scripts/prose.js .claude/commands/forge-sync.md \
  "file by file|per-file|each file" "approv" "never[^.]*silently|silently[^.]*overwrit"
# every project-owned artifact named untouchable, one at a time
for artifact in VISION CONTRACT SPEC WORKPLAN STATUS UX DESIGN; do
  node .forge/scripts/prose.js .claude/commands/forge-sync.md "$artifact\.md"
done
node .forge/scripts/prose.js .claude/commands/forge-sync.md "specs/"
# stated as a prohibition, not merely as a list
node .forge/scripts/prose.js .claude/commands/forge-sync.md \
  "never touch|does not touch|untouchable|never modif"
# VERSION is restamped, and only after a sync that succeeded
node .forge/scripts/prose.js .claude/commands/forge-sync.md \
  "updat[^.]*VERSION|VERSION[^.]*updat|restamp" "successful|succeed"
echo "  forge-sync.md contract: OK"

# --- .forge/VERSION carries the engine stamp and the repo pointer ---
# CONTRACT#data-model/artifacts: Forge-managed, "engine version stamp +
# canonical repo pointer, consumed by /forge-sync". Both lines are asserted by
# shape, since a sync that cannot parse either one has nothing to fetch from.
echo "Checking VERSION stamp..."

test -s .forge/VERSION
# line 1 — semver engine version
head -1 .forge/VERSION | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\r?$'
# line 2 — canonical repo URL
sed -n '2p' .forge/VERSION | grep -Eq '^https?://[^ ]+\r?$'
echo "  VERSION: OK"

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

# --- The task-type enum's prose restatements agree with VALID_TYPES ---
# Five sites restate the enum on purpose (template, tables, documented script
# output); test-task-types.sh derives the truth from lib/workplan.js and checks
# both directions, so a type dropped from a table or invented in prose fails
# here (TASK-080, closes OBS-012).
echo "Checking task-type enum sites..."
bash .forge/tests/test-task-types.sh > /dev/null
echo "  task-type enum: OK"

# --- STATUS.md holds its invariants ---
# The status lint guards the one table a mechanical hard stop reads every
# session; a malformed row there is an invisible disarm (TASK-082,
# CONTRACT#rules/status-lint).
echo "Checking check-status.js..."
bash .forge/tests/test-check-status.sh > /dev/null
echo "  check-status.js: OK"

# --- Observations have exactly one writer ---
# obs.js mints IDs, stamps dates, escapes cells, and validates before the write
# stands; hand-written rows are how a literal pipe silently removes a row from
# every reader (TASK-083, CONTRACT#interfaces/observation-script).
echo "Checking obs.js..."
bash .forge/tests/test-obs.sh > /dev/null
echo "  obs.js: OK"

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
