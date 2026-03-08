# Enhancements

**Status:** Implemented
**Date:** 2026-03-06

---

## 1. Test-First Gates

### Goal

Enforce that `feature` and `fix` tasks produce tested code. Not aspirational — structurally enforced through gates and hooks.

### What's enforceable vs. what isn't

**Enforceable (Pillar 2 — deterministic enforcement):**

- Gate commands for `feature` and `fix` tasks must include test commands. `/forge-plan` generates these; the human verifies during workplan review.
- The PreToolUse commit hook blocks commits unless tests pass. (Already designed in CONTRACT — disabled by default until test infrastructure exists.)
- Build must succeed alongside tests. Gate pattern: `{{test_command}} && {{build_command}}`.

**Not enforceable (be honest about it):**

- Test-first _ordering_ (writing tests before implementation) cannot be verified by a hook or gate. There is no mid-task checkpoint in Forge — the gate runs once, at the end. An AI agent can write tests and implementation in any order and still pass the gate.
- Test-first ordering is a **convention**, enforced by template instructions and human code review of the diff. The human reviewer (Pillar 5) is the gate for process discipline.

### What changes

**CONTRACT.md — new rule under Rules:**

```markdown
### Test-First Convention

`feature` and `fix` tasks follow test-first development:

1. Write tests that specify expected behavior before writing implementation.
2. Run the test command to confirm tests exercise new behavior.
3. Write implementation to satisfy the tests.
4. Run the full gate command.

**Enforcement:**

- Gate commands for `feature` and `fix` tasks must include a test command (e.g., `npm test && npm run build`). `/forge-plan` generates these; the human verifies.
- The PreToolUse commit hook blocks commits when the test command fails. This is enabled after test infrastructure exists.
- Test-first _ordering_ is a convention. The human reviewer verifies it by reading the diff — tests should appear as additions alongside or before implementation code.

**Exemptions:** `scaffold` tasks (create test infrastructure), `investigate` tasks (manual gates), `clarify` tasks (no code). `refactor` tasks already have tests — write characterization tests first if coverage is insufficient.
```

**Templates — strengthen existing instructions:**

`feature.md` already says "Tests first." Add explicit ordering:

```
1. **Read** the Contract context. Identify interfaces, edge cases, and error conditions.
2. **Write tests** that specify the expected behavior. Cover the happy path, at least one edge case, and at least one error condition. Run the test command — tests should fail (no implementation yet).
3. **Implement** the feature to satisfy the tests. Stay within Contract constraints.
4. **Run the gate command.** All tests pass, build succeeds.
```

`fix.md` already says "Reproduce first." Add:

```
1. **Write a failing test** that reproduces the bug. Run the test command — it should fail, confirming the bug.
2. **Fix the root cause.** Minimal change.
3. **Run the gate command.** The reproducing test and all existing tests pass.
```

No new template fields. No phase gates. No `{{test_command}}` placeholder — the test command is part of the existing `{{gate}}` value.

**Hook — enable PreToolUse commit gate:**

The CONTRACT already specifies this hook is "disabled by default, enabled by a later workplan task after test infrastructure exists." That's the right design. This enhancement just makes it explicit: the scaffold task that creates test infrastructure should also enable the commit hook as its final step.

### What this does NOT do

- No "Red gate" that checks `npm test` exits non-zero. That fires on syntax errors, missing imports, and pre-existing failures — it doesn't prove your new tests are valid.
- No multi-phase gates within a single task. Forge has one gate per task. That's a feature, not a limitation.
- No Refactor phase. If code needs refactoring after a feature, it's a separate `refactor` task (Pillar 1 — one task, one concern).

---

## 2. Traceability via Git

### Goal

Create a greppable graph from requirements (WORKPLAN) to code (commits + files). Zero tooling, zero maintenance — git is the database (Pillar 3).

### What already works

- `/forge-next` suggests commit messages ending with `(TASK-XXX)`.
- `git log --grep="TASK-007"` finds every commit for a task.
- `git show` on those commits shows exactly which files were touched and what changed.

That's already a working requirement→code graph. The gap: it depends on the human following the suggested commit message format.

### What changes

**CONTRACT.md — new rule under Rules:**

```markdown
### Traceability

Task IDs are the traceability anchor. Every task leaves a grep-able trail:

**Commit messages** must end with `(TASK-XXX)`:

    Add user auth middleware (TASK-012)

`/forge-next` generates this format automatically when suggesting commit messages.

**File manifest** — when `/forge-next` marks a task `done`, it appends a `Files` line to the task's Notes listing the files created or modified (derived from `git diff --name-only` against the task's starting commit). This records the requirement→file mapping inside WORKPLAN.md without relying on code annotations.

**Discovery:**

- Find commits: `git log --oneline --grep="TASK-007"`
- Find files: look at the `Files` line in the task's Notes, or `git log --name-only --grep="TASK-007"`
- Full diff: `git log -p --grep="TASK-007"`
```

**`/forge-next` changes:**

When marking a task `done`, run `git diff --name-only` (staged or last commit vs. session start) and write a `Files:` line to the task's Notes field. Example:

```
- Notes: Files: src/auth/middleware.ts, src/auth/middleware.test.ts, src/routes/login.ts
```

This is auto-generated, not a judgment call. Every completed task gets it.

### What this does NOT do

- No code annotations (`// TASK-XXX` comments). They rot when code moves. They depend on the agent's judgment about what's "non-trivial." They violate Pillar 3 — git is the memory, not comments. If you need to find what TASK-007 touched, `git log --grep` is authoritative; a comment in the code is a stale copy.
- No heuristics about LOC thresholds or "agent decides." The file manifest is mechanical and total.

---

## Implementation

| Enhancement          | Changes                                            | Effort |
| -------------------- | -------------------------------------------------- | ------ |
| Test-First Gates     | CONTRACT rule, template instructions, hook enable  | Low    |
| Traceability via Git | CONTRACT rule, `/forge-next` file manifest on done | Low    |

**Order:**

1. **Test-First Gates** — highest value, and the template changes clarify agent behavior for every subsequent task.
2. **Traceability** — the file manifest in `/forge-next` needs implementation, but it's a small diff.

### Validation

**Test-First Gates:**

- Generate a workplan. Every `feature` and `fix` gate includes a test command. (Inspect WORKPLAN.md.)
- Run a `feature` task. Verify the template instructs test-first ordering. Verify the gate runs tests.
- Enable the PreToolUse commit hook. Attempt a commit with failing tests. It should block.

**Traceability:**

- Complete a task. Verify the commit message ends with `(TASK-XXX)`.
- Check the task's Notes in WORKPLAN.md. A `Files:` line should list touched files.
- Run `git log --oneline --grep="TASK-XXX"` — it should find the commit.

---

## Decisions Recorded

1. **No Red gate.** `npm test` exiting non-zero doesn't prove new tests are valid — it proves _something_ is broken. Test-first ordering is a convention, not a gate.
2. **No code annotations.** Git log is authoritative. Comments rot. Pillar 3.
3. **No parallelism design.** YAGNI.
4. **No agent judgment calls.** File manifests are mechanical. Template instructions are explicit. The human reviewer is the process gate (Pillar 5), not the AI's discretion.
