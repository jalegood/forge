# Headless Run Policy — v0.3-headless

Experiment-scoped fault-tolerance policy for the unattended run on branch
`v0.3-headless` (started 2026-08-30). This file is the written-down version of
the run's circuit breakers, per the run charter: design the breakers, write
them down before relying on them, encode them as scripts or hooks wherever
possible, and hold to them as strictly as the hooks hold to theirs. It is
deleted or archived when the branch merges and the experiment ends.

## Authority for this run

Every Forge rule that exists to make the agent consult a human before acting is
suspended for this branch, except: Vision changes are proposed, never made.
Contract, Spec, and Workplan changes, clarify-task resolution, checkpoint
approval, and commit review are agent decisions, each recorded where the
Contract already requires a record (Decisions rows, checkpoint packets written
to disk, task records).

## Mechanical breakers (git-native hooks, armed by FORGE_UNATTENDED=1)

Source: `.forge/scripts/guard-headless-run.sh`, installed as
`.git/hooks/pre-commit`. A companion blocker is installed as
`.git/hooks/pre-push`. Git hooks fire on every commit/push regardless of which
process invokes git — a strictly stronger enforcement point than an
instruction, and independent of Claude Code's own hook layer, which stays
active above it (push guard, branch guard, secret guard).

A commit is refused when any of these holds:

1. **Branch pin.** HEAD is not `v0.3-headless`. Narrower than the engine's
   default-branch guard: this run commits to exactly one branch.
2. **Vision lock.** The staged diff touches `.forge/VISION.md`. Vision changes
   are proposals to the human, so the run cannot commit one even by accident.
3. **Task ceiling.** `git log --oneline | grep -c '(TASK-'` has reached 100 —
   the run charter's hard stop, encoded with the charter's own formula
   (52 at run start; the count is total history, which is how the formula
   reads).
4. **Workplan lint.** `check-workplan.js` exits nonzero.
5. **Status lint.** `check-status.js` exits nonzero (skipped until the script
   exists; it is a pending deliverable of this very run).
6. **Test suite.** Any `.forge/tests/test-*.sh` or `smoke.sh` fails. The suite
   runs with `FORGE_UNATTENDED` unset so the session's armed environment does
   not leak into test fixtures (the guard tests set the flag explicitly per
   case). This is the regression breaker: a later task that breaks an earlier
   task's tests cannot commit, so momentum cannot carry a broken foundation
   forward.
7. **Secret scan.** A staged added line matches the same conservative patterns
   `guard-secrets.sh` blocks on.

The human bypass is git's own `--no-verify`. The agent never passes it, the
same way it never passes `wp.js --force`.

## Behavioral breakers (recorded policy, ledgered where possible)

These have no mechanical enforcement point available mid-session (Claude Code
hooks snapshot at startup; git hooks cannot see gate outcomes), so they are
policy — held to exactly, with a paper trail that makes a violation visible
after the fact:

1. **Two-strike gate failure.** A gate failure writes a diagnostic line to the
   task's Notes (the Contract already mandates this). A second consecutive
   failure on the same task marks it `blocked`, writes the Blockers row, and
   the run moves on or stops — never a third attempt on momentum.
2. **Foundation-observation triage protocol.** The mechanical halt stays: task
   selection refuses while an open `foundation` row exists. This run holds
   triage authority, under three constraints: (a) a `foundation` row is
   dispositioned only with a full dated Decisions row stating the reasoning;
   (b) `declined` is never applied to a `foundation` row autonomously — the
   run may accept, plan, or fold it into visible work, but never bury it;
   (c) every `foundation` row touched during the run is listed in the final
   report for human review. Rationale: the OBS-013/OBS-018 record shows pure
   halting deadlocks when the queue itself contains the fix, while
   unconstrained self-triage retires the one signal designed to interrupt
   agent momentum. Constraint (b) is the load-bearing one.
3. **Novel `normal` observations stay `open`** for end-of-run review, except
   the two auto-disposition cases the Contract amendment permits (provable
   duplicate, already-covered by an existing task), each with a dated
   Decisions row.
4. **Stop conditions.** The run ends when the pending queue is genuinely empty
   (including run-created tasks) or the task ceiling is reached, whichever
   comes first. On stop: report what shipped, what was decided autonomously,
   this policy and why, and anything flagged for the human.

## Cleanup at run end

- Remove the `env.FORGE_UNATTENDED` entry from `.claude/settings.local.json`
  (it arms the guards for every future session in this project until removed).
- The git hooks stay installed but disarm without the flag; note them in the
  final report so the human can delete them at merge.

## Run outcome (2026-08-31)

The run stopped on an empty queue: 98/98 tasks done, 0 pending, 0 active,
0 blocked, well under the 100-task-commit ceiling. No breaker fired against
a real defect, and none was bypassed — `--no-verify` was never passed, and
neither was `wp.js --force` or `next --force`.

Two breakers proved their keep:

- **Breaker 6 (test suite)** caught its first failure within a minute of being
  armed: `test-guard-hooks.sh` inherited `FORGE_UNATTENDED=1` from the session
  and read a correct block as a failure. That became TASK-094 — a guard test
  that could not survive the unattended context the guards exist for.
- **Breaker 2 (Vision lock)** was exercised deliberately at install time and
  refused a staged VISION.md edit. It never fired again, because Vision was
  never touched.

The behavioral breakers were never triggered: no gate failed twice on the
same task, and no `foundation` row was raised during the run. The one
foundation-adjacent decision — OBS-019, found by the TASK-046 checkpoint's own
gate re-run — was `normal` severity and went to a task rather than a halt.

**Teardown for the human at merge:** delete `.git/hooks/pre-commit` and
`.git/hooks/pre-push`, and delete this file along with
`.forge/scripts/guard-headless-run.sh`. All four are experiment-scoped. The
engine's own guards (`guard-push.sh`, `guard-branch.sh`, `guard-secrets.sh`,
`hook-status-lint.sh`) are permanent and stay.
