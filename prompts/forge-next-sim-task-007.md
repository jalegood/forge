# /forge-next Simulation — TASK-007

> Assembled mechanically: resolved 2 manifest references, filled the scaffold
> template slots. Notes field guidance included. Issues noted at the end.

---

## Pre-Execution

Before you begin work, update `.forge/WORKPLAN.md`: change TASK-007's status from `pending` to `active`.

---

# Scaffold Task

You are executing a **scaffold** task. Your job is to set up project structure, configuration, and boilerplate.

## Task

**ID:** TASK-007
**Description:** Structural smoke test
**Gate:** `bash .forge/tests/smoke.sh`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

### Gate Patterns

Gates validate deliverable structure, not quality. Different deliverable types require different gate strategies:

| Deliverable Type            | Gate Strategy                                           | Example                                                             |
| --------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------- |
| Code                        | Test suite / build command                              | `npm test && npm run build`                                         |
| Config / JSON               | Parse validation + key check                            | `node -e "JSON.parse(require('fs').readFileSync('f.json','utf8'))"` |
| Markdown artifacts          | Structural check (required sections, slots, line count) | `grep -q '{{context}}' file.md && test $(wc -l < file.md) -gt 10`   |
| Human-judgment deliverables | `manual:` prefix — not automated                        | `manual: Verify the workflow completes 2-3 full cycles`             |

**The `manual:` gate type:** When a gate value starts with `manual:`, `/forge-next` does not run a shell command. Instead, it presents the description to the human and asks for pass/fail confirmation. Use this for deliverables that cannot be structurally validated (e.g., end-to-end workflow validation, UX review).

- Automated gates are always preferred. Use `manual:` only when no structural check is possible.
- If a task seems to need a `manual:` gate, first consider whether it can be split into an automatable structural task and a smaller manual verification task.

### Task Lifecycle

```
pending ──→ active ──→ done
  │            │
  │            └──→ blocked
  │                   │
  └───────────────────┘ (when blocker resolves)
```

- **pending:** Not yet started. All dependencies must be `done` to become unblocked.
- **active:** Currently being executed in a session. Exactly 0 or 1 tasks may be `active` at any time.
- **done:** Gate passed. Code committed. Terminal state.
- **blocked:** Cannot proceed. Requires a `clarify` task or dependency resolution. Returns to `pending` when unblocked.

Valid transitions: `pending→active`, `active→done`, `active→blocked`, `blocked→pending`.

## Task Notes

Create a test script that validates the pipeline plumbing: command files exist and reference correct artifacts, WORKPLAN.md task format is parseable (status/type/depends/context/gate fields present), settings.json is valid JSON with hook config, CLAUDE.md has the integration block. This is structural validation only — does not test Claude execution.

## Instructions

1. **Read before writing.** Check whether `.forge/tests/` exists. Create it if not.
2. **Structure first.** The deliverable is a single shell script at `.forge/tests/smoke.sh`. Write checks in logical groups: command files, WORKPLAN format, settings.json, CLAUDE.md.
3. **Follow conventions.** Each check should print a clear pass/fail message. The script should exit non-zero at the first failure so the cause is immediately visible.
4. **Keep it minimal.** Validate only what the Task Notes specify. This is structural validation — do not test Claude execution, simulate command behavior, or check file content beyond what's described.
5. **Wire things up.** The gate is `bash .forge/tests/smoke.sh` — ensure the script is valid bash (include `#!/usr/bin/env bash` and `set -e`).

## Practical Guidance

- Use `set -e` so the script exits on any check failure, and print a message before each check group so failures identify themselves.
- The four check groups, with specific validations for each:

  **Command files exist and reference correct artifacts:**
  - `.claude/commands/forge-status.md` — non-empty, contains "WORKPLAN"
  - `.claude/commands/forge-plan.md` — non-empty, contains "VISION" and "CONTRACT" and "manifest" or "completeness" or "independently"
  - `.claude/commands/forge-next.md` — non-empty, contains "WORKPLAN", "template", and "gate"

  **WORKPLAN.md task format is parseable:**
  - `.forge/WORKPLAN.md` exists and contains the required field labels: `Status:`, `Type:`, `Depends:`, `Context:`, `Gate:`
  - Contains at least one task with each of the four valid status values represented in the file (or simply: contains all five field labels)

  **settings.json is valid JSON with hook config:**
  - `.claude/settings.json` parses as valid JSON (`node -e` parse check)
  - Contains `PostToolUse`

  **CLAUDE.md has the integration block:**
  - `CLAUDE.md` exists and contains `Pipeline:`, `Workflow:`, and `Do not modify CONTRACT.md`

- Apply the gate pattern table from the Contract: JSON files get parse + key check; markdown files get grep-based structural checks.
- The script should print `All checks passed.` and exit 0 on success.

## Completion

When you believe the scaffold is complete:

1. Run the gate command: `bash .forge/tests/smoke.sh`
2. If the gate **passes**: mark TASK-007 as `done` in WORKPLAN.md, report success, and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix the script or the failing artifact, and re-run.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered

---

## Issues Surfaced During Assembly

### 1. Manifest is wider than strictly needed

The Task Lifecycle section is in the manifest to inform what valid WORKPLAN.md status values look like. In practice, the smoke test only checks that field labels are present — it doesn't validate that status values are drawn from the valid set (`pending`, `active`, `done`, `blocked`). The section is not harmful, but the manifest could have been narrower (just Gate Patterns). This is an acceptable overinclusion — the information doesn't mislead the agent.

### 2. The script validates prior task outputs

The smoke test is circular by design: it checks that WORKPLAN.md, settings.json, CLAUDE.md, and the command files are correct — all produced by TASK-001 through TASK-006. If those tasks produced imperfect output (e.g., a CLAUDE.md missing the "Do not modify" line, or a settings.json with a structural error), the smoke test will surface it here. This is the intended gate function: a single script that re-validates all pipeline plumbing before proceeding to end-to-end testing.

### 3. CLAUDE.md "Do not modify" check is tighter than TASK-006's gate

The Practical Guidance specifies `grep -q "Do not modify CONTRACT.md" CLAUDE.md` for the CLAUDE.md check, which is stricter than TASK-006's gate (`grep -q "CONTRACT.md" CLAUDE.md`). This surfaced the same weakness identified during TASK-006 assembly. If CLAUDE.md was produced correctly (verbatim from the Contract template), both checks pass. If it was produced incorrectly, the smoke test will catch what TASK-006's gate missed.

### 4. `.forge/tests/` directory must be created

The `tests/` subdirectory doesn't exist in `.forge/`. The script creation step must create it first. Instruction #1 covers this.

### 5. Script is self-validating

The gate `bash .forge/tests/smoke.sh` runs the script the task produces. If the script has a bash syntax error, the gate fails immediately with a parse error. If any check command fails, `set -e` causes early exit. This is clean: the task deliverable is both the test and its own gate target.
