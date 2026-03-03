# /forge-next Simulation — TASK-005

> Assembled mechanically: resolved 1 manifest reference, filled the scaffold
> template slots. Notes field guidance included. Issues noted at the end.

---

## Pre-Execution

Before you begin work, update `.forge/WORKPLAN.md`: change TASK-005's status from `pending` to `active`.

---

# Scaffold Task

You are executing a **scaffold** task. Your job is to set up project structure, configuration, and boilerplate.

## Task

**ID:** TASK-005
**Description:** Configure hooks in settings.json
**Gate:** `node -e "JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8'))" && grep -q "PostToolUse\|PreToolUse" .claude/settings.json && echo "Valid JSON with hooks configured"`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

### Hook Configuration

`/forge-plan` writes `.claude/settings.json` during initial scaffold **only if the file does not already exist**. The default configuration:

- **PostToolUse (file edit):** Auto-lint/format after every file write (~200ms, non-blocking). Configured for the detected tech stack, or a no-op placeholder if no linter is detected.
- **PreToolUse (git commit):** Block commits unless test suite passes (exit 0 required). **Disabled by default** — enabled by a later workplan task after test infrastructure exists.

This avoids broken hooks on first run while ensuring deterministic enforcement is available as early as possible. The human may edit `settings.json` at any time to adjust hook behavior.

## Task Notes

Per resolved CONTRACT decision: auto-create settings.json only if absent. PostToolUse lint hook enabled. PreToolUse commit hook disabled by default (enable after test infra exists).

## Instructions

1. **Read before writing.** Check whether `.claude/settings.json` already exists. If it does, do not overwrite it — report that it already exists and verify its contents match the spec. If it doesn't, create it.
2. **Structure first.** Create the file with valid JSON containing the hook configuration.
3. **Follow conventions.** Use the Claude Code `settings.json` hook format (see Practical Guidance below).
4. **Keep it minimal.** Only configure what the Contract specifies — PostToolUse with a lint/format placeholder, and a note about PreToolUse for later enablement.
5. **Wire things up.** Ensure the `.claude/` directory exists before writing the file.

## Practical Guidance

- The deliverable is `.claude/settings.json` — this is a Claude Code configuration file that defines hooks (shell commands triggered by tool events).
- The `.claude/` directory already exists (it contains the `commands/` subdirectory from previous tasks).
- The Contract says **PostToolUse** should be enabled with a lint/format placeholder. Since Forge's own build has no linter configured, use a no-op echo placeholder.
- The Contract says **PreToolUse** (commit-blocking) should be **disabled by default**. Omit it from the JSON and add a note in the WORKPLAN task's Notes field about enabling it when test infrastructure exists. JSON does not support comments, so "disabled" means "not present."
- Reference: `.claude/commands/forge-plan.md` contains the exact JSON structure for settings.json in its scaffold section (search for `settings.json`). Use that as the canonical format.

## Completion

When you believe the scaffold is complete:

1. Run the gate command: `node -e "JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8'))" && grep -q "PostToolUse\|PreToolUse" .claude/settings.json && echo "Valid JSON with hooks configured"`
2. If the gate **passes**: mark TASK-005 as `done` in WORKPLAN.md, report success, and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered

---

## Issues Surfaced During Assembly

### 1. Contract describes behavior, not JSON structure

The Hook Configuration section specifies _what_ the hooks should do (PostToolUse for lint, PreToolUse for commits) but not the exact `settings.json` JSON format. Claude knows the Claude Code settings format natively, so this is workable. Additionally, the `/forge-plan` command (`.claude/commands/forge-plan.md`, created in TASK-003) contains the canonical JSON structure in its scaffold section. The Practical Guidance points the agent there as a reference.

The gate validates structural correctness (valid JSON + hook type strings present) but cannot verify that the hook _works_ correctly. That's validated during TASK-008 end-to-end testing.

### 2. "Only if absent" is a /forge-plan constraint, not a TASK-005 constraint

The Contract says `/forge-plan` writes settings.json "only if the file does not already exist." This is about `/forge-plan`'s scaffold behavior — it's defensive against overwriting user customizations on re-runs. TASK-005 is creating the file for the first time in Forge's own build, so the file shouldn't exist yet. The instruction to check first (Instruction #1) is defensive but unlikely to trigger.

### 3. Minimal resolved context (~8 lines)

One section, ~8 lines of Contract content. The smallest manifest so far. The completeness test passes for a Claude-native task (Claude knows its own settings.json format), but would be borderline for a truly zero-knowledge agent that doesn't know Claude Code's configuration schema. Acceptable because the gate validates the output structurally and the Practical Guidance provides a concrete reference.

### 4. Gate accepts OR, not AND

The gate `grep -q "PostToolUse\|PreToolUse"` matches if _either_ string is present. Since PostToolUse will always be in the file, the gate passes regardless of whether PreToolUse appears. This is correct behavior — PreToolUse is disabled by default (omitted from JSON). But it means the gate wouldn't catch a file that only contains PreToolUse and no PostToolUse. Low risk since the Practical Guidance is clear about what to include.
