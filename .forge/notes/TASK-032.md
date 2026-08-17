# TASK-032 — Create /forge-spec intake command

## Outcome

Created `.claude/commands/forge-spec.md`, the fifth Forge command: it takes raw planning input as `$ARGUMENTS` (idea text, pasted ticket, or file reference), runs a structured intake interview *before* drafting, then writes `.forge/SPEC.md` or `.forge/specs/<feature>.md` per the SPEC Data Model, annotates inferences and unknowns, appends unresolved unknowns to STATUS.md Open Questions, and runs `check-spec.js` to a passing exit before reporting. Eight steps: read context, choose target file, interview, draft, annotate, record-and-disqualify, gate, report — plus a Constraints section.

Test-first: a `forge-spec.md` block and a "forge-spec intake contract" block were added to `.forge/tests/smoke.sh` and confirmed failing before the command file existed. Assertions run through `prose.js` rather than `grep` because the command fences a spec skeleton, a STATUS.md row template, and shell commands — a plain grep would match the sample and report the instruction present when only the payload was.

## Decisions

- **Read two SPEC requirements outside the declared manifest.** `SPEC#requirements/req-intake-coverage` and `req-intake-disqualification` are this deliverable's acceptance criteria (both cited in STATUS.md's 2026-08-14 Decisions row on the adaptive intake bar), but TASK-032's Context field lists only CONTRACT# refs. Building to the manifest alone would have produced a command that fails the project's own spec. Read them, built to them, logged the manifest gap as OBS-006 rather than silently widening.
- **Coverage is adaptive with a pointing test.** Each of the five intake categories resolves via an interview answer *or* a specific quotable passage of the input — "a general impression of the input does not resolve a category" is stated as a rule, because that is the loophole that turns an adaptive bar back into no bar. Re-asking a question the input answers is named a defect, not diligence.
- **Disqualification is a step, not a caveat.** Step 6 ends with an explicit re-check: a plan-blocking unknown neither asked nor annotated withholds the draft and returns to the interview. The doc forbids the middle path of presenting it "with caveats", since the failure mode is a draft that looks finished.
- **Unresolved markers are exempted from gate-fixing.** `check-spec.js` fails on any `<!-- UNRESOLVED -->` at its default `--max-unresolved 0`, so a literal reading of the Contract's "fixes structural failures" would push an agent to delete markers to pass. The command instead requires each marker to have its STATUS.md `Q-XXX` row, then re-runs with `--max-unresolved N` and reports N to the human, so carrying unknowns stays a visible human decision.
- **Contract boundary stated twice.** "Never writes or modifies CONTRACT.md" appears in step 1 and in Constraints, and step 1 routes implied Contract changes to the step 8 report instead. `/forge-plan` is where coverage gaps get drafted into CONTRACT.md; two commands writing it would make the Contract-First invariant unowned.

## Deviations

- The manifest was widened by reading `.forge/SPEC.md` requirements it did not declare (see the first decision above). OBS-006 records the gap; the fix belongs to whoever regenerates or amends TASK-032's manifest, not to this diff.
- Checked whether TASK-032's structural-only gate violated workplan lint invariant 6 (feature gates must invoke tests) before logging it as an observation — it does not. Invariant 6 deliberately exempts gates whose only file targets are markdown artifacts, per CONTRACT#rules/gate-patterns. No observation logged.

## Files

- `.claude/commands/forge-spec.md` (created)
- `.forge/tests/smoke.sh` (modified — forge-spec existence checks plus the intake-contract block)
- `.forge/STATUS.md` (modified — OBS-006, OBS-007)
