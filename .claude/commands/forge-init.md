# /forge-init

Bootstrap a new Forge project by creating all required scaffold files. Safe to re-run — never overwrites existing files.

## Steps

### 1. Create `.forge/VISION.md` if absent

Check if `.forge/VISION.md` exists. If it does **not** exist, create it with this stub:

```markdown
# Vision

## What

<!-- Describe what this project builds. One paragraph. -->

## Who

<!-- Describe the primary user or stakeholder. One sentence. -->

## Pillars

<!-- 3-5 non-negotiable principles that constrain all decisions. Bullet list. -->
```

If it exists, skip — do not overwrite.

### 2. Create `.forge/CONTRACT.md` if absent

Check if `.forge/CONTRACT.md` exists. If it does **not** exist, create it with this stub:

```markdown
# Contract

## Data Model

<!-- Artifacts, relationships, and context manifest format. -->

## State Machines

<!-- Task lifecycle and session lifecycle state machines. -->

## Interfaces

<!-- Command interfaces: /forge-init, /forge-plan, /forge-next, /forge-status -->
<!-- Prompt template interface and task types. -->

## Rules

<!-- Task sizing, context budget, manifest completeness, session boundary protocol, -->
<!-- contract amendment protocol, mid-task scope splitting, CLAUDE.md minimalism, -->
<!-- workplan integrity, contract-first, test-first convention, traceability, gate patterns. -->

## Boundaries

<!-- What Forge does not do, what requires human approval, hook configuration, platform constraints. -->
```

If it exists, skip — do not overwrite.

### 3. Create `.forge/templates/` with all 7 template files if absent

Check for each of the following files. For any that do **not** exist, create them with the stub below. If a file exists, skip it — do not overwrite.

**`.forge/templates/scaffold.md`** — if absent, create:

```markdown
# Scaffold Task

You are executing a **scaffold** task. Your job is to set up project structure, configuration, and boilerplate.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

{{context}}

## Instructions

1. **Read before writing.** Check what already exists. Don't overwrite working files.
2. **Structure first.** Create directories, config files, and boilerplate in a logical order.
3. **Follow conventions.** Match any existing project patterns (naming, file organization, code style).
4. **Keep it minimal.** Scaffold only what's needed. Don't add features, utilities, or abstractions that aren't in the task description.
5. **Wire things up.** Ensure new files are properly referenced (imports, config entries, package.json scripts).

## Completion

When you believe the scaffold is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered
```

**`.forge/templates/feature.md`** — if absent, create:

```markdown
# Feature Task

You are executing a **feature** task. Your job is to implement a vertical slice of functionality.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

{{context}}

## Instructions

Follow test-first development:

1. **Write tests first.** Write tests that specify the expected behavior before writing any implementation code. Run the test command to confirm the tests fail (they should — implementation doesn't exist yet).
2. **Write implementation.** Write the minimum implementation needed to satisfy the tests.
3. **Run the full gate.** Run `{{gate}}` to confirm everything passes.
4. **Stay in scope.** Only implement what's described in the task. Don't add features, helpers, or abstractions beyond what's needed.

## Completion

When you believe the feature is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered
```

**`.forge/templates/fix.md`** — if absent, create:

```markdown
# Fix Task

You are executing a **fix** task. Your job is to repair a broken gate or bug.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

{{context}}

## Instructions

Follow test-first development:

1. **Write a failing test first.** Before touching implementation, write a test that reproduces the bug or exercises the broken behavior. Confirm it fails.
2. **Fix the root cause.** Implement the minimal fix that makes the test pass. Avoid unrelated changes.
3. **Run the full gate.** Run `{{gate}}` to confirm the fix holds and nothing regressed.

## Completion

When you believe the fix is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered
```

**`.forge/templates/clarify.md`** — if absent, create:

```markdown
# Clarify Task

You are executing a **clarify** task. Your job is to resolve ambiguities in CONTRACT.md.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

{{context}}

## Instructions

1. **Identify the ambiguity.** Read the relevant Contract section and note the specific `<!-- UNRESOLVED -->` marker or unclear language.
2. **Draft a resolution.** Propose specific, precise language to replace the ambiguity. The resolution must be concrete enough to generate unambiguous gates and tasks.
3. **Present to the human.** Show the proposed change and ask for approval before modifying CONTRACT.md.
4. **Apply after approval.** Once the human approves, update CONTRACT.md with the resolved text.
5. **Assess workplan impact.** Note any `pending` tasks whose Context references the changed section — they may need re-scoping.

## Completion

When the ambiguity is resolved:

1. Confirm the gate: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was clarified
   - What remains unresolved
   - Any decisions or blockers encountered
```

**`.forge/templates/refactor.md`** — if absent, create:

```markdown
# Refactor Task

You are executing a **refactor** task. Your job is to improve structure while preserving behavior.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

{{context}}

## Instructions

1. **Confirm existing tests pass.** Run the gate before touching any code. If tests fail, stop — this is a fix task, not a refactor.
2. **Write characterization tests if needed.** If coverage is insufficient, write tests that pin current behavior before changing anything.
3. **Refactor in small steps.** Make one structural change at a time. Run the gate after each step.
4. **Preserve behavior.** The gate must pass before and after. If behavior changes, stop and reassess.
5. **No scope creep.** Don't add features or fix unrelated bugs during a refactor.

## Completion

When the refactor is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered
```

**`.forge/templates/investigate.md`** — if absent, create:

```markdown
# Investigate Task

You are executing an **investigate** task. Your job is to diagnose issues or explore unknowns and document findings.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

{{context}}

## Instructions

1. **Define the question.** What specific unknown needs to be resolved? State it clearly before starting.
2. **Explore systematically.** Read relevant files, run diagnostic commands, trace execution paths.
3. **Document as you go.** Write findings incrementally — don't wait until the end.
4. **Produce actionable output.** The deliverable is a clear finding: what is happening, why, and what should be done next.
5. **Propose follow-up tasks.** If the investigation reveals work to be done, draft task entries for the human to add to WORKPLAN.md.

## Completion

When the investigation is complete:

1. Present findings to the human (the gate is `manual:` — the human confirms pass/fail).
2. Update the `Notes` field in WORKPLAN.md with a summary of findings.
3. If the gate **passes**: report success and suggest a commit message.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was investigated
   - What remains unclear
   - Any decisions or blockers encountered
```

**`.forge/templates/ux-spec.md`** — if absent, create:

```markdown
# UX Spec Task

You are executing a **ux-spec** task. Your job is to author or complete a screen spec in UX.md. This task produces no code — only a completed screen specification.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following sections are relevant to this task. The UX.md stub to complete is included below.

{{context}}

## Instructions

1. **Read the stub.** Locate the screen referenced in the task description within `.forge/UX.md`.
2. **Complete all mandatory fields.** Every screen must have `**Emotional intent:**` and `**Design intention:**` filled with specific, non-placeholder language.
3. **Fill in States.** Every state row must have a specific, measurable Experience value. No vague terms like "smooth", "fast", or "subtle" — use numeric values (e.g., "ease-out 250ms") for anything involving time, physics, or sensation.
4. **Fill in Edge Cases.** At minimum: Empty/first-time behavior and Error behavior.
5. **Precision rule.** Prose is permitted only in Emotional intent, Design intention, and Copy Tone. All cells involving measurable qualities must be numeric or reference a named pattern.

## Completion

When the screen spec is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: read the validation errors, fix the offending fields, and re-run.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was completed
   - What remains
   - Any decisions or blockers encountered
```

### 4. Create `.forge/UX.md` if absent

Check if `.forge/UX.md` exists. If it does **not** exist, create it with this stub:

```markdown
# UX Spec

## Global

### Copy Tone

<!-- Voice and energy rules: name what's in bounds and out. -->

### Style Notes

<!-- Global interaction/aesthetic principles only. Screen-specific decisions belong on the screen. -->

## Flows

### Flow: [Name]

**Entry:** [Screen + trigger]
**Exit:** [Screen(s) + condition]
**Emotional arc:** [e.g., anticipation → focus → satisfaction]

#### Screen: [Name]

**Purpose:** One sentence: what does this screen accomplish for the user?
**Emotional intent:** <!-- What should the user FEEL at this moment? Be specific. -->
**Design intention:** <!-- The specific decision that elevates this screen above a generic implementation. -->

##### States

| State | Trigger | Experience |
| ----- | ------- | ---------- |
|       |         |            |

##### Edge Cases

| Condition          | Behavior |
| ------------------ | -------- |
| Empty / first-time |          |
| Error              |          |
```

If it exists, skip — do not overwrite.

### 5. Create `.forge/scripts/check-ux-spec.js` if absent

Check if `.forge/scripts/check-ux-spec.js` exists. If it does **not** exist, create `.forge/scripts/` directory if needed, then create `check-ux-spec.js` with:

```javascript
#!/usr/bin/env node
// check-ux-spec.js — validate one screen spec in .forge/UX.md by screen name
// Usage: node .forge/scripts/check-ux-spec.js "Screen Name"
// Exit 0 = valid, Exit 1 = invalid (errors printed to stderr)

const fs = require('fs');
const path = require('path');

const screenName = process.argv[2];
if (!screenName) {
  console.error('Usage: node .forge/scripts/check-ux-spec.js "Screen Name"');
  process.exit(1);
}

const uxPath = path.join(process.cwd(), '.forge', 'UX.md');
if (!fs.existsSync(uxPath)) {
  console.error('Error: .forge/UX.md not found');
  process.exit(1);
}

const content = fs.readFileSync(uxPath, 'utf8');

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Find the screen section
const screenRegex = new RegExp(`^#### Screen: ${escapeRegex(screenName)}\\s*$`, 'm');
const screenMatch = screenRegex.exec(content);
if (!screenMatch) {
  console.error(`Error: Screen "${screenName}" not found in UX.md`);
  process.exit(1);
}

// Extract screen content through next heading at same or higher level
const afterMatch = content.slice(screenMatch.index + screenMatch[0].length);
const nextSectionMatch = /^#{1,4} /m.exec(afterMatch);
const screenContent = nextSectionMatch ? afterMatch.slice(0, nextSectionMatch.index) : afterMatch;

const errors = [];

// Check mandatory fields are present and not placeholders
const mandatoryFields = ['**Emotional intent:**', '**Design intention:**'];
for (const field of mandatoryFields) {
  const idx = screenContent.indexOf(field);
  if (idx === -1) {
    errors.push(`Missing mandatory field: ${field}`);
  } else {
    const afterField = screenContent.slice(idx + field.length).trim();
    const firstLine = afterField.split('\n')[0].trim();
    if (!firstLine || firstLine.startsWith('<!--') || firstLine === 'TODO' || firstLine === 'TBD') {
      errors.push(`${field} is empty or placeholder`);
    }
  }
}

// Check States table exists and has at least one data row
const statesMatch = /##### States([\s\S]*?)(?=##### |$)/.exec(screenContent);
if (!statesMatch) {
  errors.push('Missing section: ##### States');
} else {
  const statesBody = statesMatch[1];
  const dataRows = statesBody.split('\n').filter(line => {
    const trimmed = line.trim();
    return trimmed.startsWith('|') && !trimmed.includes('---') && !/^\|\s*State\s*\|/i.test(trimmed);
  });
  if (dataRows.length === 0) {
    errors.push('States table has no data rows');
  }

  // Reject vague terms in States cells
  const vagueTerms = ['smooth', 'fast', 'subtle', 'snappy', 'quick', 'slow', 'nice', 'clean', 'simple'];
  for (const term of vagueTerms) {
    const regex = new RegExp(`\\b${term}\\b`, 'i');
    if (regex.test(statesBody)) {
      errors.push(`Vague term "${term}" found in States table — use numeric/named values (e.g., "ease-out 250ms")`);
    }
  }
}

// Check Edge Cases section exists
if (!screenContent.includes('##### Edge Cases')) {
  errors.push('Missing section: ##### Edge Cases');
}

if (errors.length > 0) {
  console.error(`Screen "${screenName}" spec validation failed:\n`);
  errors.forEach(e => console.error(`  - ${e}`));
  process.exit(1);
}

console.log(`Screen "${screenName}" spec is valid.`);
process.exit(0);
```

If `.forge/scripts/check-ux-spec.js` exists, skip — do not overwrite.

### 6. Create `.claude/settings.json` if absent

Check if `.claude/settings.json` exists. If it does **not** exist, create `.claude/` directory if needed, then create `settings.json` with:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'File saved.'",
            "description": "Placeholder lint hook — replace with project linter (e.g., eslint --fix, ruff format)"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "exit 0",
            "description": "Commit gate — disabled by default. Enable after test infrastructure exists by replacing with: npm test or equivalent."
          }
        ]
      }
    ]
  }
}
```

If `.claude/settings.json` exists, skip — do not overwrite.

### 7. Append Forge integration block to `CLAUDE.md` if absent

Check if `CLAUDE.md` exists in the project root.

- If `CLAUDE.md` does **not** exist, create it with exactly:

```markdown
## Forge

- Pipeline: .forge/ (VISION.md, CONTRACT.md, WORKPLAN.md)
- Workflow: /forge-next → review → commit → /clear
- Do not modify CONTRACT.md without asking first
```

- If `CLAUDE.md` exists, check whether it already contains `Pipeline: .forge/`. If it does, skip — do not append. If it does not contain that line, append the integration block to the end of the file (preceded by a blank line).

### 8. Report completion

After creating all files, tell the user:

```
Forge initialized. Files created (existing files were not overwritten):
- .forge/VISION.md
- .forge/CONTRACT.md
- .forge/templates/scaffold.md
- .forge/templates/feature.md
- .forge/templates/fix.md
- .forge/templates/clarify.md
- .forge/templates/refactor.md
- .forge/templates/investigate.md
- .forge/templates/ux-spec.md
- .forge/UX.md
- .forge/scripts/check-ux-spec.js
- .claude/settings.json
- CLAUDE.md (integration block)

Next steps:
1. Fill in .forge/VISION.md with your project's What, Who, and Pillars.
2. Fill in .forge/CONTRACT.md with your project's interfaces, rules, and data model.
3. Fill in .forge/UX.md with your screen flows and specs.
4. Run /forge-plan to generate a task workplan.
```

Only list files that were actually created or modified (not skipped). If all files already existed, say: "All Forge files already exist. Nothing was changed."
