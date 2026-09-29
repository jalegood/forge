# TASK-047 — Create unattended-execution guard hooks and wire into settings.json

## Outcome

Three deterministic `PreToolUse` guard scripts now enforce
CONTRACT#rules/unattended-execution mechanically instead of by
instruction-following: `guard-push.sh` blocks `git push` unconditionally (rule
3), `guard-branch.sh` blocks `git commit` on the repository's default branch
when `FORGE_UNATTENDED=1` is set (rule 1), and `guard-secrets.sh` blocks
`git commit` when the staged diff adds a line matching a conservative
secret-pattern list. All three read Claude Code's `PreToolUse` stdin contract
(JSON, `tool_input.command`) and exit 2 to block. They are wired into
`.claude/settings.json` under a second `Bash`-matcher `PreToolUse` entry
alongside the pre-existing `PostToolUse` lint hook, and `/forge-init` now
provisions all three by default for new projects. `test-guard-hooks.sh` covers
each guard's positive and negative cases against real git fixtures, plus the
settings wiring and the `/forge-init` provisioning.

## Decisions

- **Blocked means exit 2, not merely nonzero.** The Contract says "exits nonzero
  to block" (annotated ASSUMED). Claude Code actually treats exit 2 as "block
  the call and feed stderr to the model" and every *other* nonzero code as a
  non-blocking error that lets the tool run anyway — so a guard exiting 1 would
  print a complaint and let the push through. Exit 2 satisfies the Contract's
  wording and is the code that actually stops the call; the tests assert on 2
  specifically rather than on `!= 0`.
- **Guards fail closed on an unparseable payload.** The command is extracted from
  the JSON envelope with `node`; if that yields nothing, the raw stdin blob
  becomes the haystack instead of allowing the call. A guard that opens the gate
  whenever it cannot read the request is defeatable by anything that perturbs
  the envelope.
- **The default branch is read from the repo, never hardcoded.** `guard-branch.sh`
  resolves `refs/remotes/origin/HEAD`, then `init.defaultBranch`, then falls back
  to `main`. A guard hardcoding `main` would silently protect nothing in a
  `trunk`- or `master`-default repository — a failure with no symptom until the
  unattended run has already committed. Covered by a `trunk` fixture.
- **`FORGE_UNATTENDED` is checked before anything else in the branch guard**, so
  the interactive path costs one string comparison and is provably inert. Per the
  2026-07-31 discussion recorded in the task Notes, the flag is set by the
  headless launcher, never typed by a human; that convention is now documented in
  `forge-init.md` step 9 as well as in the script header. Building the launcher
  itself remains out of scope.
- **Secret patterns stay narrow.** Only the three classes the Contract names —
  cloud access keys, private-key headers, common API-key prefixes — all of which
  have fixed prefixes and length constraints. Generic `password =` heuristics were
  deliberately excluded: a guard that cries wolf on ordinary code gets disabled,
  and a disabled guard catches nothing.
- **The secret guard scans added lines of the staged diff only.** Unstaged content
  is not about to be committed, and deleting a line containing a key is the fix
  rather than the offense. Both cases are asserted.
- **The gate runs `test-init-scripts.sh` rather than re-implementing drift
  detection.** The three guards were added to that script's existing `check` list
  and `test-guard-hooks.sh` invokes it, so the embedded `/forge-init` payloads are
  diffed against the live files by one implementation.
- **Guard-subcommand matching allows flag/value pairs.** `git -C dir push` puts a
  flag argument between `git` and the subcommand, which a `git( -flag)* push`
  pattern misses. The pattern now permits an optional non-flag value after each
  flag, while the trailing word boundary still keeps `git pushed` and `pushState`
  from matching.

## Deviations

- **Two duplicate lines were removed from `forge-init.md`'s step 12 completion
  list** — `.forge/scripts/lib/markdown.js` and `.forge/scripts/check-workplan.js`
  each appeared twice. This is the defect recorded as OBS-011. It was fixed rather
  than observed because the guard paths had to be added to that exact list, and
  leaving two stale duplicates inside a list being rewritten fails the in-scope
  test. OBS-011's Disposition was left `open` — closing an observation is the
  human's call, not the executing task's.
- **`grep -v '^\+\+\+'` was a real bug found mid-implementation**, not a
  deviation from spec: GNU grep reads `\+` in a *basic* regular expression as the
  repetition operator, so that filter discarded every line and the secret guard
  saw an empty diff and passed. Both greps in that pipeline now take `-E`, with a
  comment recording the trap.

## Files

- `.forge/scripts/guard-push.sh` (new)
- `.forge/scripts/guard-branch.sh` (new)
- `.forge/scripts/guard-secrets.sh` (new)
- `.forge/tests/test-guard-hooks.sh` (new)
- `.claude/settings.json` (PreToolUse guards added; PostToolUse lint hook unchanged)
- `.claude/commands/forge-init.md` (step 9 settings JSON + guard rationale, step 11 three embedded payloads, step 12 completion list)
- `.forge/tests/test-init-scripts.sh` (three guard payloads added to the drift check)
- `.forge/STATUS.md` (OBS-016)
- `.forge/WORKPLAN.md` (status, notes)
