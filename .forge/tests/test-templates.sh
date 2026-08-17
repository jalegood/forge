#!/usr/bin/env bash
# Verifies that every prompt template carries the observation step.
#
# CONTRACT#interfaces/prompt-template-interface requires each template in
# .forge/templates/ to hold "an instruction to record out-of-scope findings as
# STATUS.md Observations rows, applying the in-scope fix test rather than
# logging reflexively". The step is worthless if it drifts between templates:
# an agent running a `fix` task and an agent running a `feature` task must
# apply the same test and produce the same row, or the Observations table
# becomes a mix of one-line pointers and memos.
#
# Two copies exist and both are checked. The live templates under
# .forge/templates/ are what /forge-next injects in this project. The blocks
# embedded in /forge-init are what a *new* project gets — unlike the script
# payloads, they carry no forge-init:embed marker and are not diffed against
# the live files, so nothing else would notice them going stale.

set -e

INIT=".claude/commands/forge-init.md"
TEMPLATES=(scaffold feature fix clarify refactor investigate ux-spec checkpoint)

# The wording that carries the step. Each phrase pins one mandatory element of
# CONTRACT#data-model/status.md-data-model, Observations — dropping any one of
# them changes what agents actually do.
check_body() {
  local label="$1"
  local body="$2"
  local phrase
  local -a required=(
    # the destination, named concretely enough to append to
    "Observations"
    ".forge/STATUS.md"
    # the in-scope fix test — the whole point of the step
    "belongs in this task's diff"
    # what the channel is for, stated positively
    "would otherwise be lost, not what would otherwise be fixed"
    # anti-ceremony constraint 1: one line, not a report
    "a pointer, not a report"
    # anti-ceremony constraint 2: observations never become tasks by themselves
    "spawns a task"
    # anti-ceremony constraint 3: volume collapses into one foundation row
    "More than three"
    "foundation"
  )

  for phrase in "${required[@]}"; do
    if ! printf '%s' "$body" | grep -qF -- "$phrase"; then
      echo "FAIL: $label is missing the observation step phrase: $phrase"
      exit 1
    fi
  done

  # A prohibition drives agents to write memos instead of one-line fixes. The
  # step must read as "fix what you own, record the rest", never as "record,
  # never act".
  if printf '%s' "$body" | grep -qiF -- "record, never act"; then
    echo "FAIL: $label frames the step as a prohibition on acting"
    exit 1
  fi
}

# The wording that makes a clarify task write its resolution to STATUS.md.
#
# CONTRACT#data-model/status.md-data-model names `clarify` tasks as a mandatory
# writer of the Decisions table — "a status file nothing reads goes stale", and
# one nothing writes is empty. The Contract's own phrasing is "move resolved
# questions to Decisions (dated, with rationale)": a *move*, so the same
# question cannot sit in both tables, where a reader of Open Questions cannot
# tell it from an unresolved one.
#
# Rejected alternatives are pinned separately because they are the column an
# agent drops first. The Decisions row is the only artifact that survives the
# session; without the options the human turned down, the next session re-opens
# the settled question and re-derives the same answers.
check_clarify_body() {
  local label="$1"
  local body="$2"
  local phrase
  local -a required=(
    # the destination table, named concretely enough to append to
    "Decisions table"
    # the row's shape — a decision with no date cannot be ordered against others
    "YYYY-MM-DD"
    # the column agents drop first, and the word that stops them
    "Alternatives rejected"
    "mandatory"
    # the question moves out of Open Questions; it is not copied into Decisions
    "Open Questions"
    "does not exist in both"
  )

  for phrase in "${required[@]}"; do
    if ! printf '%s' "$body" | grep -qF -- "$phrase"; then
      echo "FAIL: $label is missing the decision-logging phrase: $phrase"
      exit 1
    fi
  done
}

# Extract the fenced template body that follows the `.forge/templates/X.md`
# heading in forge-init.md.
extract_init() {
  awk -v want="$1" '
    index($0, "`.forge/templates/" want ".md`") { armed = 1; next }
    armed && /^```/ { infence = !infence; if (!infence) exit; next }
    armed && infence { print }
  ' "$INIT"
}

echo "Checking live templates..."
for name in "${TEMPLATES[@]}"; do
  path=".forge/templates/$name.md"
  test -s "$path" || { echo "FAIL: $path does not exist"; exit 1; }
  check_body "$path" "$(cat "$path")"
  echo "  $path: OK"
done

echo "Checking templates embedded in $INIT..."
test -s "$INIT"
for name in "${TEMPLATES[@]}"; do
  body="$(extract_init "$name")"
  test -n "$body" || { echo "FAIL: $INIT has no template block for $name.md"; exit 1; }
  check_body "$INIT ($name.md block)" "$body"
  echo "  $name.md block: OK"
done

# The investigate template used to close by drafting workplan entries for a
# human to add. That human is not reading during an unattended span, so the
# proposal went nowhere — the observation step replaces it. Task-drafting
# language returning here would reintroduce the orphaned channel.
echo "Checking that investigate.md no longer drafts workplan entries..."
for source in ".forge/templates/investigate.md" "<init>"; do
  if [ "$source" = "<init>" ]; then
    body="$(extract_init investigate)"
    label="$INIT (investigate.md block)"
  else
    body="$(cat "$source")"
    label="$source"
  fi
  for phrase in "added to the workplan" "add to WORKPLAN.md" "draft task entries"; do
    if printf '%s' "$body" | grep -qiF -- "$phrase"; then
      echo "FAIL: $label still tells the agent to draft workplan entries: $phrase"
      exit 1
    fi
  done
  echo "  $label: OK"
done

# Both copies of the clarify template must close the STATUS.md loop. The live
# one is what /forge-next injects here; the embedded one is what a new project
# gets, and it carries no forge-init:embed marker, so nothing else diffs it.
echo "Checking that clarify.md logs decisions to STATUS.md..."
check_clarify_body ".forge/templates/clarify.md" "$(cat .forge/templates/clarify.md)"
echo "  .forge/templates/clarify.md: OK"
check_clarify_body "$INIT (clarify.md block)" "$(extract_init clarify)"
echo "  $INIT (clarify.md block): OK"

echo ""
echo "All template checks passed."
