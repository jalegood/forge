# TASK-033 — Update /forge-status to surface STATUS.md items

## Outcome

`/forge-status` already surfaced STATUS.md's Open Questions and Blockers — TASK-059's
projection rewrite of the command file folded the whole deliverable in ahead of this
task, so the gate passed before any work started. What was actually missing was
enforcement: `smoke.sh` asserted only the Observations path for `/forge-status`, and
the task's own `grep -q "STATUS.md"` gate matches anywhere in the file, including
inside the fenced output-format sample. This task added the assertions that lock the
behavior, and made one change to the deliverable itself: open questions are now
surfaced by their `Q-XXX` ID.

## Decisions

- **Assertions go through `prose.js`, not `grep`.** `forge-status.md` fences an
  output-format template that already contains the literal strings `Open questions:`
  and `Blockers:`. A plain grep matches the sample and reports the instruction present
  when only the example is — the precise failure mode `prose.js` was written for
  (TASK-031), and the reason the task's own bare-grep gate could not be relied on.
- **Every assertion was mutation-verified.** Deleting step 2 from the command file
  makes the suite exit 1 naming `Open Questions, Blockers, exists|when present`;
  reverting the ID change makes it exit 1 naming `by its ID|by ID`. Tests that pass
  on first run against pre-existing behavior are worthless unless shown to fail
  without it, and these were all in that position.
- **Strengthening the gate went into `smoke.sh`, not the Gate field.** The Gate field
  already invokes `smoke.sh`, so assertions added there tighten this task's gate
  transitively without a workplan edit and without weakening lint invariant 6.
- **Open questions are surfaced by ID.** `CONTRACT#data-model/status.md-data-model`
  gives Open Questions an `ID` column, and every other row this report emits carries
  its identifier (`TASK-XXX`, `OBS-X`). A question the human cannot name is one they
  cannot hand to a `clarify` task, so dropping the only identifier from the one row
  type that has one was an inconsistency inside this task's own deliverable.

## Deviations

- The Contract's Outputs line specifies only "open questions and blockers from
  STATUS.md (if any)" and does not mandate IDs. Adding `Q-XXX` to the output shape
  goes marginally past the letter of the spec; it is justified above as internal
  coherence rather than a new requirement.
- Blockers are still surfaced by their `Blocker` text alone, dropping the data
  model's `Blocking tasks` and `Needs` columns. `Needs` is the actionable field, but
  the Contract does not require it and the Blockers table has no ID column, so no
  identity argument applies. Left alone deliberately to keep the diff to one concern.

## Files

- `.forge/tests/smoke.sh` — new `forge-status STATUS.md surfacing` assertion block
- `.claude/commands/forge-status.md` — step 2 lists questions by ID; output shape gains `Q-XXX`
- `.forge/STATUS.md` — OBS-008, OBS-009
