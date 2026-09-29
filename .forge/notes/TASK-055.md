# TASK-055 — Wire observations into /forge-status and /forge-plan read paths

## Outcome

`/forge-plan` now has an Observation intake step. It reads STATUS.md's Observations
table during step 1 context loading, selects rows whose Disposition is `accepted`,
and folds each into the deliverable set — so an accepted row passes through the
step 2 Contract-First coverage check and yields a candidate task in step 4 on the
same terms as any deliverable derived from VISION.md or CONTRACT.md. Rows marked
`open` or `declined` are never planned, and the command is explicitly told not to
edit any row's Disposition in either direction.

`/forge-status`'s half of the contract turned out to be already satisfied by prior
work: `wp.js status` returns open rows foundation-first via `readObservations()`,
step 1 of the command consumes them, and the Output Format already carries an
`**Open observations:**` block. No edit was needed there. That was established
test-first rather than assumed — the assertion was written before the
implementation and passed on its first run, which is what identified the real
scope of this task as `/forge-plan` alone.

`.forge/tests/smoke.sh` gained an "observation read paths" block asserting both
halves, so the wiring is now covered wherever smoke.sh runs rather than only by
this task's gate.

## Decisions

- **Intake lives in step 1, not step 4.** The Contract requires accepted rows to
  be "subject to the same Contract-First coverage requirement as any other
  deliverable." Step 2 is where that check runs, so intake had to happen before
  it. Putting the block at the end of step 1 makes accepted rows part of the
  planning input the coverage check already iterates, rather than a parallel path
  bolted onto task generation that would need its own coverage language.
- **Step 4's opening sentence was widened rather than given a new subsection.**
  One clause ("plus any deliverable carried in from the accepted observations
  collected in step 1") is enough to connect the two steps; a second subsection
  would have restated the intake rules a second time and invited them to drift
  apart.
- **Assertions go through `prose.js`, not `grep`.** Both command files fence
  sample task blocks and example output. A `grep -q "accepted"` against
  forge-plan.md could match inside a fenced task template and report the
  instruction present when only the sample was — the exact failure mode prose.js
  was built for after TASK-031.
- **The "no disposition edits" rule was stated explicitly.** The Contract's
  `/forge-plan` constraints already say "no side effects beyond writing
  WORKPLAN.md," but the intake step is the one place an agent has an obvious
  motive to mark a row consumed. Saying so at the point of temptation costs one
  sentence.
- **Intake is documented as the secondary loop closure.** The command states that
  `/forge-next` reports open `foundation` rows every session and that an
  observation must not depend on a planning run to be seen, so a future reader
  does not mistake `/forge-plan` for the primary path.

## Deviations

None from the Contract. The task description names two read paths; only one
required a change, because `/forge-status`'s path was already wired. The test
assertion for it was still added, so the behavior is now pinned rather than
incidentally true.

One inconsistency was noticed and left alone as out of scope: the Contract's
`/forge-plan` **Reads:** line annotates STATUS.md as "blocking open questions"
only, while its own **Does:** line requires Observations intake from that same
file. Fixing it means editing CONTRACT.md, which is not this task's diff — logged
as OBS-004.

## Files

- `.claude/commands/forge-plan.md` — Observation intake block in step 1; step 4
  opening sentence widened to include accepted observations
- `.forge/tests/smoke.sh` — "observation read paths" assertion block
- `.forge/STATUS.md` — OBS-004 appended
- `.forge/WORKPLAN.md` — TASK-055 status and notes (via `wp.js`)
