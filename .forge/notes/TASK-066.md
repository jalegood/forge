# TASK-066 — Realign test-prose.sh with forge-init's STATUS.md instruction

## Outcome

The final live-case block in `.forge/tests/test-prose.sh` is inverted rather than
deleted. It previously asserted that `prose.js` finds *no* `STATUS.md` in
`.claude/commands/forge-init.md` prose — true when written, because the only
occurrences were inside the embedded script payload, and false since TASK-031
(commit f7d4e60) added the step-4 instruction that creates the stub. The block now
asserts the positive half against `STATUS\.md` and moves the false-pass half to
`module\.exports`, which is still payload-only in that file.

`test-prose.sh` and `smoke.sh` are green again. Because `smoke.sh` runs
`test-prose.sh`, this also clears the inherited failure for the nine tasks that
TASK-065 wired Depends edges from (TASK-033/034/036/037/049/051/053/054/055).

## Decisions

- **Inverted the live case, did not delete it.** The block's purpose is to test the
  false-pass property against a real file, not against the synthetic fixture — the
  fixture cannot show that a 1843-line, 88%-fenced command file still discriminates
  correctly. Deleting it would have made the gate pass by removing the assertion
  that gives the other four gates their credibility.
- **Chose `module.exports` for the negative half.** Candidates that are payload-only
  in forge-init.md today include `readObservations`, `process.exit`, `use strict`,
  `const fs`, `Disposition`, and `appendNotes`. `module.exports` is the most durable:
  it is JavaScript in a markdown command file, so it cannot migrate into prose the
  way `Observations` and `STATUS.md` both did. The others are either equally
  incidental (`const fs`) or describe concepts the prose could plausibly start
  discussing (`Disposition`, `appendNotes`).
- **Kept the `grep -q` fixture-drift check on the new pattern.** It is what proves
  plain grep *would* be fooled; without it the negative assertion could pass simply
  because the payload no longer contains the pattern at all. Verified: grep matches
  `module.exports` in the file, `prose.js` does not.
- **Verified the positive assertion is not vacuous.** Stripping every prose line
  matching `STATUS.md` from a scratch copy (leaving fenced lines intact) makes
  `prose.js` exit 1 while plain grep still finds 3 payload occurrences. That is the
  false-pass scenario reproduced in the one direction the old test used to cover,
  now demonstrated rather than asserted.

## Deviations

The `fix` template's test-first ordering (write a failing test, then fix) does not
map cleanly here: the stale assertion in the test *is* the defect, so there is no
separate test to write ahead of it. The equivalent discipline was applied by
verifying all three new assertions against the live file with `prose.js` and `grep`
directly, plus the negative control above, before editing the script.

`prose.js`'s header comment carried the same staleness as the test — it cited
`grep -q "Observations"` as a live payload false positive, which stopped being one
when TASK-031 put "Observations" into forge-init.md's prose. Fixed in a follow-up
pass at the human's request: the historical account of the TASK-031 failure is kept
(it is the real motivation and still true as history, now in past tense), with a
note that the example is historical and `module.exports` is the current stand-in.
The same pass corrected "embeds four scripts verbatim" to five — forge-init.md
embeds check-ux-spec.js, markdown.js, workplan.js, check-workplan.js, and wp.js.
The 88%-fenced figure was re-measured and still holds (1616 of 1843 lines).

`prose.js` is not itself an init payload — `test-init-scripts.sh` diffs only
markdown.js, workplan.js, check-workplan.js, and wp.js — so there was no second
copy to keep in sync.

## Files

- `.forge/tests/test-prose.sh` — live-case block inverted (lines 68-80)
- `.forge/scripts/prose.js` — header comment de-staled (lines 2-16)
- `.forge/WORKPLAN.md` — TASK-066 status and notes
