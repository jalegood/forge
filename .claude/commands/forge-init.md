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

### 3. Create `.forge/SPEC.md` if absent

Check if `.forge/SPEC.md` exists. If it does **not** exist, create it with this stub:

```markdown
# Spec

<!-- When this file exceeds ~300 lines, split into per-feature files under .forge/specs/ -->
<!-- (e.g., .forge/specs/auth.md), referenced from tasks as specs/auth#requirements. -->

## Overview

<!-- What this feature/system does, in one paragraph. Why it exists. -->

## Requirements

### [REQ-slug] Requirement Name

<!-- EARS-style statement: WHEN <trigger>, THE SYSTEM SHALL <response>. -->
<!-- Acceptance criteria: bullet list, each independently testable. -->

## Flows

<!-- Behavioral sequences that span requirements. References UX.md screens where applicable. -->

## Non-Goals

<!-- What this spec deliberately excludes. Prevents scope creep during execution. -->
```

If it exists, skip — do not overwrite.

### 4. Create `.forge/STATUS.md` if absent

Check if `.forge/STATUS.md` exists. If it does **not** exist, create it with this stub — five tables, headers only, no rows:

```markdown
# Status

## Open Questions

| ID | Question | Blocking? | Raised |
| -- | -------- | --------- | ------ |

## Decisions

| Date | Decision | Why | Alternatives rejected |
| ---- | -------- | --- | --------------------- |

## Risks

| Risk | Impact | Mitigation |
| ---- | ------ | ---------- |

## Blockers

| Blocker | Blocking tasks | Needs |
| ------- | -------------- | ----- |

## Observations

| ID | Raised by | Kind | Severity | Observation | Disposition |
| -- | --------- | ---- | -------- | ----------- | ----------- |
```

All five tables are mandatory. `check-workplan.js` resolves `STATUS#observations` and `/forge-next` halts on open `foundation` rows, so a stub missing the Observations table silently disables that hard stop. Emit the header rows even though every table starts empty — writers append rows, they do not create tables.

If it exists, skip — do not overwrite.

### 5. Create `.forge/templates/` with all 6 template files if absent

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

### 6. Ask whether the project has a user-facing interface, then create `.forge/UX.md` if needed

Ask the human: **"Does this project have a user-facing interface (UI/UX)?"**

If the answer is unclear, ask again — do not guess a default.

- **If no:** skip this step, step 7 (`DESIGN.md`), and step 8 (`check-ux-spec.js`) entirely. Do not create `.forge/UX.md`, `.forge/DESIGN.md`, or `.forge/scripts/check-ux-spec.js`. Proceed to step 9.
- **If yes:** continue below.

Check if `.forge/UX.md` exists. If it does **not** exist, create it with this stub:

```markdown
# UX Spec

## Global

### Copy Tone

<!-- Voice and energy rules: name what's in bounds and out. -->

### Interaction Notes

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

<!-- Example: | Loading | Fetch triggered | Skeleton fade-in, opacity 0→1 over 200ms | -->

##### Edge Cases

| Condition          | Behavior |
| ------------------ | -------- |
| Empty / first-time |          |
| Error              |          |
```

If it exists, skip — do not overwrite.

Also create `.forge/templates/ux-spec.md` if absent (only reached when step 6 was answered "yes" — skipped otherwise):

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

If it exists, skip — do not overwrite.

### 7. Create `.forge/DESIGN.md` if absent

Only run this step if step 6 was answered "yes". If it was answered "no", this step was already skipped.

Check if `.forge/DESIGN.md` exists. If it does **not** exist, create it with this stub:

```markdown
# Design System

## Tokens

### Colors

<!-- Seed colors, semantic color roles (e.g., primary, surface, error) -->
<!-- Example: primary: #4F46E5, surface: #FFFFFF, error: #DC2626 -->

### Typography

<!-- Type scale: font families, sizes, weights, line heights -->

### Spacing

<!-- Base unit and named sizes (e.g., sm: 8px, md: 16px, lg: 24px) -->

### Radius

<!-- Corner radius values by component tier -->

## Components

### [Component Name]

<!-- Visual spec: default state, variants, token references -->

## Style Notes

<!-- Aesthetic rationale and cross-cutting component rules -->
```

If it exists, skip — do not overwrite.

### 8. Create `.forge/scripts/check-ux-spec.js` if absent

Only run this step if step 6 was answered "yes". If it was answered "no", this step was already skipped.

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

  // Reject vague terms in the Experience column only (3rd cell) — State/Trigger labels
  // may legitimately contain words like "slow" or "fast" without violating precision.
  const experienceCells = dataRows.map(row => {
    const cells = row.split('|');
    return cells[3] !== undefined ? cells[3].trim() : '';
  });
  const vagueTerms = ['smooth', 'fast', 'subtle', 'snappy', 'quick', 'slow', 'nice', 'clean', 'simple'];
  for (const term of vagueTerms) {
    const regex = new RegExp(`\\b${term}\\b`, 'i');
    if (experienceCells.some(cell => regex.test(cell))) {
      errors.push(`Vague term "${term}" found in States table Experience column — use numeric/named values (e.g., "ease-out 250ms")`);
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

### 9. Create `.claude/settings.json` if absent

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

### 10. Append Forge integration block to `CLAUDE.md` if absent

Check if `CLAUDE.md` exists in the project root.

- If `CLAUDE.md` does **not** exist, create it with exactly:

```markdown
## Forge

- Pipeline: .forge/ (VISION.md, CONTRACT.md, WORKPLAN.md)
- Workflow: /forge-next → review → commit → /clear
- Do not modify CONTRACT.md without asking first
```

- If `CLAUDE.md` exists, check whether it already contains `Pipeline: .forge/`. If it does, skip — do not append. If it does not contain that line, append the integration block to the end of the file (preceded by a blank line).

### 11. Create the `.forge/scripts/` engine scripts if absent

Unconditional — these are not gated on the step 6 interface question. `/forge-next` and `/forge-plan` both run the workplan lint after every WORKPLAN.md write and treat a nonzero exit as a hard block, and `/forge-next` and `/forge-status` reach the workplan only through `wp.js` (CONTRACT#rules/workplan-access-discipline), so a project without these files cannot complete a task.

Create `.forge/scripts/lib/` (both the `scripts` and `lib` directories) if needed.

The four blocks below are exact copies of the engine's scripts. Copy them verbatim — they are diffed against the originals by `.forge/tests/test-init-scripts.sh`, and the `<!-- forge-init:embed -->` markers are what that test keys on. Do not edit the payloads in place; if a script changes, re-copy the whole block.

Order matters only in that the two `lib/` modules must exist before the scripts that require them; create all four.
If `.forge/scripts/lib/markdown.js` does **not** exist, create it with:

<!-- forge-init:embed .forge/scripts/lib/markdown.js -->

```javascript
// markdown.js — shared markdown section resolution (CONTRACT#data-model/context-manifest)
//
// One implementation of "find a heading, extract through the next same-or-higher
// heading". Previously duplicated in check-ux-spec.js (ad-hoc regex, not
// fence-aware) and check-workplan.js (level-scoped, fence-aware). The
// fence-aware version is the correct one and is what lives here — CONTRACT.md
// alone holds fenced blocks containing heading-like lines, so a scanner that
// ignores fences truncates real sections early.
//
// Exports: parseHeadings, normalizeSlug, headingCompact, sectionRange,
//          findHeading, resolveSegments, resolveRef, createLoader

'use strict';

const fs = require('fs');
const path = require('path');

// --- Slug comparison ---
// Compacts to lowercase alnum-only. Deliberately looser than a strict
// hyphen-slug: it tolerates the mixed "x.md-data-model" / "xmd-data-model"
// punctuation already present in this project's hand-written Context fields.

function normalizeSlug(s) {
  return s.trim().toLowerCase().replace(/[^a-z0-9]/g, '');
}

// UX.md headings carry a "Flow: " / "Screen: " label prefix that is part of the
// document convention, not part of the name being referenced.
function headingCompact(text) {
  const stripped = text.trim().replace(/^(Flow|Screen):\s*/, '');
  return normalizeSlug(stripped);
}

// --- Heading scan ---
// Returns [{ level, text, index }] where index is the offset of the heading
// line's first character. Lines inside ``` fences are not headings.

function parseHeadings(fileContent) {
  const lines = fileContent.split('\n');
  const headings = [];
  let offset = 0;
  let inFence = false;
  for (const line of lines) {
    if (/^\s*```/.test(line)) {
      inFence = !inFence;
    } else if (!inFence) {
      const m = /^(#{1,6})\s+(.*)$/.exec(line);
      if (m) headings.push({ level: m[1].length, text: m[2].trim(), index: offset });
    }
    offset += line.length + 1;
  }
  return headings;
}

// --- Section extraction ---
// A section runs from its heading (inclusive) to just before the next heading
// at the same level or higher.

function sectionRange(headings, match, contentLength) {
  const next = headings.find(h => h.index > match.index && h.level <= match.level);
  return { start: match.index, end: next ? next.index : contentLength };
}

// Find the first heading whose compacted text equals `slug`, within an optional
// scope window and level constraints.
//   scopeStart/scopeEnd — offset window to search (default: whole document)
//   minLevel            — heading must be deeper than this (nested navigation)
//   level               — heading must be exactly this level
//   prefix              — heading text must start with this label (e.g. 'Screen')
function findHeading(headings, slug, opts = {}) {
  const {
    scopeStart = 0,
    scopeEnd = Infinity,
    minLevel = 0,
    level = null,
    prefix = null,
  } = opts;

  return headings.find(h => {
    if (h.index < scopeStart || h.index >= scopeEnd) return false;
    if (h.level <= minLevel) return false;
    if (level !== null && h.level !== level) return false;
    if (prefix !== null && !new RegExp(`^${prefix}:\s*`).test(h.text)) return false;
    return headingCompact(h.text) === slug;
  });
}

// --- Segment navigation ---
// Walks "a/b/c" style reference segments. Each segment is matched within the
// previous segment's section and must be strictly deeper than it, so
// `requirements/req-login` cannot match a `req-login` heading in a sibling
// section. Returns the resolved range on success.
//
// `file` is { content, headings }. `label` is used only in error text.

function resolveSegments(file, segments, label) {
  const ref = label || segments.join('/');
  if (!segments.length) return { ok: false, reason: `"${ref}" has no path segments` };

  let scopeStart = 0;
  let scopeEnd = file.content.length;
  let minLevel = 0;
  let match = null;

  for (const seg of segments) {
    match = findHeading(file.headings, normalizeSlug(seg), { scopeStart, scopeEnd, minLevel });
    if (!match) return { ok: false, reason: `"${ref}" — no heading matching "${seg}" found`, segment: seg };

    const range = sectionRange(file.headings, match, file.content.length);
    scopeStart = range.start;
    scopeEnd = range.end;
    minLevel = match.level;
  }

  return {
    ok: true,
    heading: match,
    start: scopeStart,
    end: scopeEnd,
    section: file.content.slice(scopeStart, scopeEnd),
  };
}

// --- File loading ---
// Reference prefixes name a file under the given base directory: `CONTRACT` ->
// CONTRACT.md, `specs/auth` -> specs/auth.md, `notes/TASK-029` ->
// notes/TASK-029.md. Returns a cached loader; missing files resolve to null.

function createLoader(baseDir) {
  const cache = new Map();
  return function loadFile(relPath) {
    if (cache.has(relPath)) return cache.get(relPath);
    const full = path.join(baseDir, relPath);
    let data = null;
    if (fs.existsSync(full)) {
      const content = fs.readFileSync(full, 'utf8').replace(/\r\n/g, '\n');
      data = { content, headings: parseHeadings(content) };
    }
    cache.set(relPath, data);
    return data;
  };
}

// --- Full reference resolution ---
// "PREFIX#segment/segment" -> resolved section. `loadFile` maps a relative path
// to { content, headings } or null. `displayBase` is cosmetic only: it prefixes
// the file path in error text so messages name the path a human would type.

function resolveRef(ref, loadFile, opts = {}) {
  const displayBase = opts.displayBase || '';
  const hashIdx = ref.indexOf('#');
  if (hashIdx === -1) return { ok: false, reason: `"${ref}" is malformed (missing #)` };
  const prefix = ref.slice(0, hashIdx).trim();
  const refPath = ref.slice(hashIdx + 1).trim();
  if (!prefix || !refPath) return { ok: false, reason: `"${ref}" is malformed` };

  const shown = `${displayBase}${prefix}.md`;
  const file = loadFile(`${prefix}.md`);
  if (!file) return { ok: false, reason: `"${ref}" — source file ${shown} not found` };

  const segments = refPath.split('/').map(s => s.trim()).filter(Boolean);
  const result = resolveSegments(file, segments, ref);
  if (!result.ok) return { ok: false, reason: `${result.reason} in ${shown}` };
  return Object.assign({ file: prefix }, result);
}

module.exports = {
  normalizeSlug,
  headingCompact,
  parseHeadings,
  sectionRange,
  findHeading,
  resolveSegments,
  createLoader,
  resolveRef,
};
```

If it exists, skip — do not overwrite.

If `.forge/scripts/lib/workplan.js` does **not** exist, create it with:

<!-- forge-init:embed .forge/scripts/lib/workplan.js -->

```javascript
// workplan.js — shared WORKPLAN.md parsing, selection, and mutation
// (CONTRACT#rules/workplan-access-discipline, CONTRACT#state-machines/task-lifecycle)
//
// One parser for the workplan format. check-workplan.js owns validation and
// wp.js owns projection and mutation, but both read the file through here — a
// second, divergent workplan parser is exactly the failure that pushing shared
// markdown resolution into lib/markdown.js was meant to end.
//
// The parser is line-based rather than regex-over-the-whole-file because the
// mutation side needs line ranges: `set` must rewrite one field in place and
// leave every other byte of the file untouched. WORKPLAN.md stays plain,
// hand-editable markdown (Rules/Workplan Access Discipline, Format boundary) —
// this module accelerates access to that format, it does not become it.
//
// Exports: VALID_STATUSES, VALID_TYPES, VALID_TRANSITIONS, FIELD_NAMES,
//          parseWorkplan, readWorkplan, dependsList, contextList, stripBackticks,
//          unmetDeps, selectTask, setField, appendNotes

'use strict';

const fs = require('fs');
const path = require('path');

const VALID_STATUSES = ['pending', 'active', 'done', 'blocked'];
const VALID_TYPES = ['scaffold', 'feature', 'clarify', 'refactor', 'fix', 'investigate', 'ux-spec', 'checkpoint'];

// CONTRACT#state-machines/task-lifecycle. Enforced on mutation so the script
// cannot walk the workplan into a state the state machine forbids; `--force`
// exists for the human who is deliberately rewriting history.
const VALID_TRANSITIONS = {
  pending: ['active'],
  active: ['done', 'blocked'],
  blocked: ['pending'],
  done: [],
};

// Canonical casing for the six fields, keyed by lowercase name.
const FIELD_NAMES = {
  status: 'Status',
  type: 'Type',
  depends: 'Depends',
  context: 'Context',
  gate: 'Gate',
  notes: 'Notes',
};

const HEADER_RE = /^## \[(TASK-\d+)\]\s*(.*)$/;
const FIELD_RE = /^- \*\*([A-Za-z][A-Za-z ]*):\*\*[ \t]?(.*)$/;

function stripBackticks(s) {
  if (!s) return s;
  const m = /^`([\s\S]*)`$/.exec(s.trim());
  return m ? m[1] : s;
}

// --- Parsing ---
// Returns { content, lines, tasks, taskById }. Each task carries its parsed
// field values plus a `fields` map of { name, firstLine, lastLine, valueLines }
// so mutations can target exact line ranges.

function parseWorkplan(rawContent) {
  const content = rawContent.replace(/\r\n/g, '\n');
  const lines = content.split('\n');
  const tasks = [];

  let cur = null;
  let curField = null;
  let inFence = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    if (/^\s*```/.test(line)) {
      inFence = !inFence;
    } else if (!inFence) {
      const h = HEADER_RE.exec(line);
      if (h) {
        if (cur) cur.endLine = i;
        cur = {
          id: h[1],
          description: h[2].trim(),
          order: tasks.length,
          headerLine: i,
          endLine: lines.length,
          fields: new Map(),
        };
        tasks.push(cur);
        curField = null;
        continue;
      }
      if (cur) {
        const f = FIELD_RE.exec(line);
        if (f) {
          curField = {
            name: f[1].trim(),
            firstLine: i,
            lastLine: i,
            valueLines: [f[2]],
          };
          cur.fields.set(curField.name.toLowerCase(), curField);
          continue;
        }
      }
    }

    // Anything else inside a task body continues the field above it. A field's
    // value is therefore multi-line by default, which is what Notes needs.
    if (cur && curField) {
      curField.lastLine = i;
      curField.valueLines.push(line);
    }
  }

  // Trailing blank lines belong to the document's spacing, not to the field.
  for (const t of tasks) {
    for (const f of t.fields.values()) {
      while (f.valueLines.length > 1 && f.valueLines[f.valueLines.length - 1].trim() === '') {
        f.valueLines.pop();
        f.lastLine--;
      }
    }
    t.status = firstLineOf(t, 'status');
    t.type = firstLineOf(t, 'type');
    t.depends = firstLineOf(t, 'depends');
    t.contextRaw = firstLineOf(t, 'context');
    t.gate = stripBackticks(firstLineOf(t, 'gate'));
    t.notes = fullValueOf(t, 'notes');
  }

  return { content, lines, tasks, taskById: new Map(tasks.map(t => [t.id, t])) };
}

function firstLineOf(task, name) {
  const f = task.fields.get(name);
  return f ? f.valueLines[0].trim() : null;
}

// Continuation lines carry two spaces of markdown indentation; strip one level
// so callers see the value a human meant to write, not its list indentation.
function fullValueOf(task, name) {
  const f = task.fields.get(name);
  if (!f) return null;
  const out = [f.valueLines[0].trim()];
  for (const l of f.valueLines.slice(1)) out.push(l.replace(/^ {1,2}/, ''));
  return out.join('\n').replace(/\s+$/, '');
}

function readWorkplan(rootDir) {
  const workplanPath = path.join(rootDir, '.forge', 'WORKPLAN.md');
  if (!fs.existsSync(workplanPath)) return null;
  const wp = parseWorkplan(fs.readFileSync(workplanPath, 'utf8'));
  wp.path = workplanPath;
  return wp;
}

// --- Graph helpers ---

function dependsList(task) {
  if (!task || !task.depends || task.depends === 'none') return [];
  return task.depends.split(',').map(s => s.trim()).filter(Boolean);
}

function contextList(task) {
  if (!task || !task.contextRaw || task.contextRaw.toLowerCase() === 'none') return [];
  return task.contextRaw.split(',').map(s => s.trim()).filter(Boolean);
}

function unmetDeps(task, taskById) {
  return dependsList(task).filter(id => {
    const dep = taskById.get(id);
    return !dep || dep.status !== 'done';
  });
}

// --- Selection ---
// The whole of CONTRACT#interfaces/command-forge-next "Task selection", in one
// deterministic place. Returns { ok, task, selection, warnings } or
// { ok: false, code, error }: code 1 = usage error (no such task), code 2 =
// nothing to select (active-task conflict, or no unblocked pending task).

function selectTask(wp, requestedId) {
  const { tasks, taskById } = wp;
  const activeTasks = tasks.filter(t => t.status === 'active');

  if (activeTasks.length > 1) {
    return {
      ok: false,
      code: 2,
      error: `Multiple active tasks found: ${activeTasks.map(t => t.id).join(', ')}. At most one task may be active — resolve this in WORKPLAN.md before continuing.`,
    };
  }
  const active = activeTasks[0] || null;

  if (requestedId) {
    const task = taskById.get(requestedId);
    if (!task) {
      return { ok: false, code: 1, error: `${requestedId} not found in WORKPLAN.md.` };
    }
    // Naming the active task is a resume, not a conflict.
    if (task.status === 'active') {
      return { ok: true, task, selection: 'resume-active', warnings: [] };
    }
    if (active) {
      return {
        ok: false,
        code: 2,
        error: `${active.id} is currently active. Only one task can be active at a time. Complete or block it before starting a new task.`,
      };
    }

    const warnings = [];
    if (task.status === 'done') {
      warnings.push(`${task.id} is already done — re-running it will redo completed work.`);
    }
    if (task.status === 'blocked') {
      warnings.push(`${task.id} is blocked. Confirm the blocker is resolved before proceeding.`);
    }
    const unmet = unmetDeps(task, taskById);
    if (unmet.length) {
      const detail = unmet
        .map(id => `${id} (${taskById.has(id) ? taskById.get(id).status : 'missing'})`)
        .join(', ');
      warnings.push(`${task.id} has unmet dependencies: ${detail}. Ask the human to confirm before proceeding.`);
    }
    return { ok: true, task, selection: 'explicit', warnings };
  }

  if (active) {
    return { ok: true, task: active, selection: 'resume-active', warnings: [] };
  }

  const next = tasks.find(t => t.status === 'pending' && unmetDeps(t, taskById).length === 0);
  if (!next) {
    return {
      ok: false,
      code: 2,
      error: 'No unblocked tasks available. Run /forge-status to see what is blocked.',
    };
  }
  return { ok: true, task: next, selection: 'next-unblocked', warnings: [] };
}

// --- Mutation ---
// Both mutators return { ok, content } — new file content — or { ok: false,
// error }. They never write; the caller decides, so it can lint before
// committing the change to disk.

function renderField(name, value) {
  const canonical = FIELD_NAMES[name.toLowerCase()] || name;
  const valueLines = String(value).split('\n');
  const head = `- **${canonical}:** ${valueLines[0]}`.replace(/\s+$/, '');
  const rest = valueLines.slice(1).map(l => (l.trim() === '' ? '' : `  ${l.replace(/^\s+/, '')}`));
  return [head, ...rest];
}

function setField(wp, taskId, fieldName, value) {
  const task = wp.taskById.get(taskId);
  if (!task) return { ok: false, error: `${taskId} not found in WORKPLAN.md.` };

  const key = fieldName.toLowerCase();
  if (!FIELD_NAMES[key]) {
    return { ok: false, error: `Unknown field "${fieldName}". Expected one of: ${Object.values(FIELD_NAMES).join(', ')}.` };
  }
  const field = task.fields.get(key);
  if (!field) {
    return { ok: false, error: `${taskId} has no ${FIELD_NAMES[key]} field to set.` };
  }

  const lines = wp.lines.slice();
  lines.splice(field.firstLine, field.lastLine - field.firstLine + 1, ...renderField(key, value));
  return { ok: true, content: lines.join('\n') };
}

function appendNotes(wp, taskId, text) {
  const task = wp.taskById.get(taskId);
  if (!task) return { ok: false, error: `${taskId} not found in WORKPLAN.md.` };
  if (!task.fields.has('notes')) return { ok: false, error: `${taskId} has no Notes field to append to.` };

  const existing = (task.notes || '').replace(/\s+$/, '');
  const addition = String(text).replace(/\s+$/, '');
  const merged = existing === '' ? addition : `${existing}\n${addition}`;
  return setField(wp, taskId, 'notes', merged);
}

module.exports = {
  VALID_STATUSES,
  VALID_TYPES,
  VALID_TRANSITIONS,
  FIELD_NAMES,
  parseWorkplan,
  readWorkplan,
  dependsList,
  contextList,
  stripBackticks,
  unmetDeps,
  selectTask,
  setField,
  appendNotes,
};
```

If it exists, skip — do not overwrite.

If `.forge/scripts/check-workplan.js` does **not** exist, create it with:

<!-- forge-init:embed .forge/scripts/check-workplan.js -->

```javascript
#!/usr/bin/env node
// check-workplan.js — validate .forge/WORKPLAN.md invariants (CONTRACT#rules/workplan-lint)
// Usage: node .forge/scripts/check-workplan.js
// Exit 0 = no errors (warnings may still print). Exit 1 = at least one error.
//
// Severity policy: violations of invariants 2 (file-order) and 3 (cycles) that
// are confined entirely to `done` tasks are warnings, not errors — done tasks
// are frozen history (Rules/Task Ordering). The same is extended here to
// invariants 6/7 (gate quality) for consistency: a `done` or `blocked` task's
// gate is already shipped; a `pending`/`active` task's gate is still correctable.
// Invariants 1, 4, and 5 (structural integrity) have no status exemption.

const fs = require('fs');
const path = require('path');
const { createLoader, resolveRef } = require('./lib/markdown');
const {
  VALID_STATUSES,
  VALID_TYPES,
  parseWorkplan,
  dependsList,
} = require('./lib/workplan');

const ROOT = process.cwd();
const workplanPath = path.join(ROOT, '.forge', 'WORKPLAN.md');

if (!fs.existsSync(workplanPath)) {
  console.error('Error: .forge/WORKPLAN.md not found');
  process.exit(1);
}

const content = fs.readFileSync(workplanPath, 'utf8').replace(/\r\n/g, '\n');

const CODE_EXTENSIONS = ['js', 'ts', 'jsx', 'tsx', 'py', 'rb', 'go', 'java', 'c', 'cpp', 'cs', 'php', 'rs'];

const errors = [];
const warnings = [];

// --- Parse tasks ---
// Parsing lives in lib/workplan.js, shared with wp.js. This script owns the
// invariants, not the format: two parsers for one file is how a linter starts
// disagreeing with the tool that writes the file it lints.

const { tasks, taskById } = parseWorkplan(content);

if (tasks.length === 0) {
  console.error('Error: no tasks found in WORKPLAN.md');
  process.exit(1);
}

// --- Invariant 1: every task has all required fields with valid values ---

for (const t of tasks) {
  if (!t.status) errors.push(`${t.id}: missing required field Status`);
  else if (!VALID_STATUSES.includes(t.status)) errors.push(`${t.id}: invalid Status "${t.status}" (expected one of ${VALID_STATUSES.join(', ')})`);

  if (!t.type) errors.push(`${t.id}: missing required field Type`);
  else if (!VALID_TYPES.includes(t.type)) errors.push(`${t.id}: invalid Type "${t.type}" (expected one of ${VALID_TYPES.join(', ')})`);

  if (!t.depends) errors.push(`${t.id}: missing required field Depends`);
  else if (t.depends !== 'none' && !t.depends.split(',').every(d => /^TASK-\d+$/.test(d.trim()))) {
    errors.push(`${t.id}: Depends must be "none" or a comma-separated list of TASK-IDs, got "${t.depends}"`);
  }

  if (t.contextRaw === null) errors.push(`${t.id}: missing required field Context`);

  if (!t.gate) errors.push(`${t.id}: missing required field Gate`);
}

// --- Invariant 2: unique IDs; Depends references an existing task; for
//     pending/active tasks each Depends entry must appear earlier in the file
//     (the same violation in a done task is a warning, not an error) ---

const idCounts = new Map();
for (const t of tasks) idCounts.set(t.id, (idCounts.get(t.id) || 0) + 1);
for (const [id, count] of idCounts) {
  if (count > 1) errors.push(`Duplicate task ID: ${id} appears ${count} times`);
}

for (const t of tasks) {
  for (const depId of dependsList(t)) {
    const depTask = taskById.get(depId);
    if (!depTask) {
      errors.push(`${t.id}: Depends references nonexistent task ${depId}`);
      continue;
    }
    if (depTask.order >= t.order) {
      const msg = `${t.id}: Depends entry ${depId} does not appear earlier in the file (Rules/Task Ordering)`;
      if (t.status === 'pending' || t.status === 'active') errors.push(msg);
      else warnings.push(`${msg} [warning: ${t.status} task, frozen history]`);
    }
  }
}

// --- Invariant 3: no dependency cycles, checked across the whole graph.
//     A cycle confined entirely to done tasks is a warning (frozen history);
//     any cycle touching a non-done task is an error. Not subsumed by
//     invariant 2, whose file-order check is scoped to pending/active only. ---

function findSCCs(nodeIds, edgesOf) {
  let counter = 0;
  const indices = new Map();
  const lowlink = new Map();
  const onStack = new Set();
  const stack = [];
  const sccs = [];

  function strongconnect(v) {
    indices.set(v, counter);
    lowlink.set(v, counter);
    counter++;
    stack.push(v);
    onStack.add(v);

    for (const w of edgesOf(v)) {
      if (!indices.has(w)) {
        strongconnect(w);
        lowlink.set(v, Math.min(lowlink.get(v), lowlink.get(w)));
      } else if (onStack.has(w)) {
        lowlink.set(v, Math.min(lowlink.get(v), indices.get(w)));
      }
    }

    if (lowlink.get(v) === indices.get(v)) {
      const scc = [];
      let w;
      do {
        w = stack.pop();
        onStack.delete(w);
        scc.push(w);
      } while (w !== v);
      sccs.push(scc);
    }
  }

  for (const v of nodeIds) {
    if (!indices.has(v)) strongconnect(v);
  }
  return sccs;
}

const allIds = tasks.map(t => t.id);
const edgesOf = (id) => dependsList(taskById.get(id)).filter(d => taskById.has(d));
const sccs = findSCCs(allIds, edgesOf);

for (const scc of sccs) {
  const isCycle = scc.length > 1 || edgesOf(scc[0]).includes(scc[0]);
  if (!isCycle) continue;
  const allDone = scc.every(id => taskById.get(id).status === 'done');
  const msg = `Dependency cycle detected: ${scc.join(' -> ')}`;
  if (allDone) warnings.push(`${msg} [warning: cycle confined to done tasks, frozen history]`);
  else errors.push(msg);
}

// --- Invariant 4: at most one task has status active ---

const activeTasks = tasks.filter(t => t.status === 'active');
if (activeTasks.length > 1) {
  errors.push(`Multiple active tasks found: ${activeTasks.map(t => t.id).join(', ')} (at most one task may be active)`);
}

// --- Invariant 5: every Context reference resolves to an existing heading ---
// Same resolution rules as CONTRACT#data-model/context-manifest: the prefix
// before "#" names a file under .forge/ (CONTRACT, UX, DESIGN, SPEC, or a
// specs/name / other multi-file contract); segments after "#" navigate nested
// headings. The resolution itself lives in lib/markdown.js, shared with the
// other gate scripts.

const loadFile = createLoader(path.join(ROOT, '.forge'));

for (const t of tasks) {
  if (!t.contextRaw || t.contextRaw.toLowerCase() === 'none') continue;
  const refs = t.contextRaw.split(',').map(s => s.trim()).filter(Boolean);
  for (const ref of refs) {
    const result = resolveRef(ref, loadFile, { displayBase: '.forge/' });
    if (!result.ok) errors.push(`${t.id}: Context reference ${result.reason}`);
  }
}

// --- Invariant 6: feature/fix gates invoke a test command, not solely
//     structural checks (grep, ls, test -f). Exempt: gates whose only file
//     targets are non-code artifacts (e.g. markdown command/template files) —
//     CONTRACT#rules/gate-patterns designates structural checks as the correct
//     strategy for markdown artifacts, so those gates were never meant to run
//     a test suite in the first place. ---

function hasTestInvocation(gate) {
  return /\btests?\//i.test(gate) ||
    /\bnpm\s+(run\s+)?test\b/i.test(gate) ||
    /\byarn\s+test\b/i.test(gate) ||
    /\bpytest\b/i.test(gate) ||
    /\bjest\b/i.test(gate) ||
    /\bmocha\b/i.test(gate) ||
    /\bgo\s+test\b/i.test(gate) ||
    /\bcargo\s+test\b/i.test(gate) ||
    /\btest-[\w-]+\.sh\b/i.test(gate);
}

function referencesCodeFile(gate) {
  const words = gate.split(/\s+/);
  for (const w of words) {
    const clean = w.replace(/^["'`]+|["'`]+$/g, '').replace(/[,;)]+$/, '');
    const extMatch = /\.([A-Za-z0-9]+)$/.exec(clean);
    if (extMatch && CODE_EXTENSIONS.includes(extMatch[1].toLowerCase())) return true;
  }
  return false;
}

for (const t of tasks) {
  if (!t.gate || t.gate.startsWith('manual:')) continue;
  if (t.type !== 'feature' && t.type !== 'fix') continue;
  if (!hasTestInvocation(t.gate) && referencesCodeFile(t.gate)) {
    const msg = `${t.id}: ${t.type} gate does not invoke a test command (structural checks only) — \`${t.gate}\``;
    if (t.status === 'pending' || t.status === 'active') errors.push(msg);
    else warnings.push(`${msg} [warning: ${t.status} task, frozen history]`);
  }
}

// --- Invariant 7: checkpoint and investigate gates use the manual: prefix ---

for (const t of tasks) {
  if (!t.gate) continue;
  if (t.type !== 'checkpoint' && t.type !== 'investigate') continue;
  if (!t.gate.trim().startsWith('manual:')) {
    const msg = `${t.id}: ${t.type} gate must use the "manual:" prefix — \`${t.gate}\``;
    if (t.status === 'pending' || t.status === 'active') errors.push(msg);
    else warnings.push(`${msg} [warning: ${t.status} task, frozen history]`);
  }
}

// --- Report ---

if (warnings.length > 0) {
  console.log(`${warnings.length} warning(s):`);
  warnings.forEach(w => console.log(`  - ${w}`));
}

if (errors.length > 0) {
  console.error(`${errors.length} error(s):`);
  errors.forEach(e => console.error(`  - ${e}`));
  console.error('\nWorkplan validation FAILED.');
  process.exit(1);
}

console.log(`\nWorkplan validation passed (${tasks.length} tasks, ${warnings.length} warning(s)).`);
process.exit(0);
```

If it exists, skip — do not overwrite.

If `.forge/scripts/wp.js` does **not** exist, create it with:

<!-- forge-init:embed .forge/scripts/wp.js -->

```javascript
#!/usr/bin/env node
// wp.js — deterministic WORKPLAN.md projection and mutation
// (CONTRACT#rules/workplan-access-discipline)
//
// Usage:
//   node .forge/scripts/wp.js next [TASK-XXX] [--json]
//   node .forge/scripts/wp.js get TASK-XXX [--json]
//   node .forge/scripts/wp.js status [--json]
//   node .forge/scripts/wp.js set TASK-XXX <field> <value> [--force]
//   node .forge/scripts/wp.js append-notes TASK-XXX <text>
//
// Why this exists: task selection is entirely deterministic — unblocked-ness,
// dependency satisfaction, active-task resume, explicit-ID override — so it
// belongs in a script rather than in an agent's context window (Vision pillar
// 2). `/forge-next` and `/forge-status` call this instead of reading
// WORKPLAN.md in full; a 2,000-line workplan then never enters context, and the
// per-session cost drops to the selected task alone.
//
// Format boundary: WORKPLAN.md stays plain, hand-editable markdown. Every
// mutation here rewrites exactly the field lines it targets, leaves the rest of
// the file byte-identical, and is re-linted with check-workplan.js before it is
// allowed to stand — a mutation that fails the lint is reverted, not left on
// disk.
//
// Exit codes: 0 success · 1 usage/validation error · 2 nothing to select.

'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const {
  VALID_STATUSES,
  VALID_TYPES,
  VALID_TRANSITIONS,
  FIELD_NAMES,
  readWorkplan,
  dependsList,
  contextList,
  unmetDeps,
  selectTask,
  setField,
  appendNotes,
} = require('./lib/workplan');
const { createLoader, resolveRef } = require('./lib/markdown');

const ROOT = process.cwd();

const USAGE = `usage: node .forge/scripts/wp.js <command>

  next [TASK-XXX] [--force] [--json]
                               select the task to execute and emit its fields;
                               halts (exit 2) while an open foundation-severity
                               observation exists, unless --force
  get TASK-XXX [--json]        emit one task's fields
  status [--json]              counts, next unblocked task, clarify tasks, open observations
  set TASK-XXX <field> <value> [--force]
                               set Status, Type, Depends, Context, Gate, or Notes
  append-notes TASK-XXX <text> append a line to a task's Notes field`;

function die(message, code) {
  console.error(`wp.js: ${message}`);
  process.exit(code === undefined ? 1 : code);
}

function loadWorkplan() {
  const wp = readWorkplan(ROOT);
  if (!wp) die('.forge/WORKPLAN.md not found. Run /forge-plan to generate one.');
  if (wp.tasks.length === 0) die('no tasks found in .forge/WORKPLAN.md. Run /forge-plan to generate one.');
  return wp;
}

// --- Rendering ---

function taskJson(task) {
  return {
    id: task.id,
    description: task.description,
    status: task.status,
    type: task.type,
    depends: dependsList(task),
    context: contextList(task),
    gate: task.gate,
    notes: task.notes || '',
  };
}

// Notes come last and are printed verbatim, so a multi-line value needs no
// escaping and the reader never has to guess where the field ends.
function printTask(task, selection, warnings) {
  console.log(`Task: ${task.id} — ${task.description}`);
  if (selection) console.log(`Selection: ${selection}`);
  console.log(`Status: ${task.status}`);
  console.log(`Type: ${task.type}`);
  console.log(`Depends: ${task.depends}`);
  console.log(`Context: ${task.contextRaw}`);
  console.log(`Gate: ${task.gate}`);
  for (const w of warnings || []) console.log(`Warning: ${w}`);
  console.log('Notes:');
  console.log(task.notes && task.notes.trim() ? task.notes : '(none)');
}

// --- STATUS.md observations ---
// Reads the Observations table (CONTRACT#data-model/status-md-data-model) and
// returns open rows, foundation severity first. Missing file or missing section
// is normal, not an error — STATUS.md is optional.

function readObservations() {
  const loadFile = createLoader(path.join(ROOT, '.forge'));
  const result = resolveRef('STATUS#observations', loadFile);
  if (!result.ok) return [];

  const rows = [];
  for (const line of result.section.split('\n')) {
    if (!line.trim().startsWith('|')) continue;
    const cells = line.split('|').slice(1, -1).map(c => c.trim());
    if (cells.length < 6) continue;
    if (/^-+$/.test(cells[0].replace(/\s/g, ''))) continue; // separator row
    if (cells[0].toLowerCase() === 'id') continue;          // header row
    const [id, raisedBy, kind, severity, observation, disposition] = cells;
    if (disposition.toLowerCase() !== 'open') continue;
    rows.push({ id, raisedBy, kind, severity: severity.toLowerCase(), observation, disposition });
  }

  // foundation first — the severity that means "stop and reconsider" must not
  // be buried under routine friction rows.
  return rows.sort((a, b) => {
    const rank = s => (s === 'foundation' ? 0 : 1);
    return rank(a.severity) - rank(b.severity);
  });
}

// --- Commands ---

function cmdNext(args, json) {
  const force = args.includes('--force');
  const rest = args.filter(a => a !== '--force');
  const requestedId = rest.find(a => /^TASK-\d+$/i.test(a));
  if (rest.some(a => !/^TASK-\d+$/i.test(a))) {
    die(`unexpected argument for next: ${rest.find(a => !/^TASK-\d+$/i.test(a))}`);
  }
  const wp = loadWorkplan();
  const result = selectTask(wp, requestedId ? requestedId.toUpperCase() : null);

  if (!result.ok) {
    if (json) {
      console.log(JSON.stringify({ ok: false, error: result.error }, null, 2));
      process.exit(result.code);
    }
    die(result.error, result.code);
  }

  // CONTRACT#rules/unattended-execution rule 4: an open foundation-severity
  // observation halts the loop, mechanically rather than advisorily. This is
  // the one hard stop an agent must trigger against its own momentum, so it
  // cannot rest on the agent reading its own warning.
  //
  // Resume is exempt on purpose — the contract has the current task finish
  // cleanly first, so refusal covers new work only. The designed exit is the
  // human triaging the row off `open`; --force is the deliberate override, and
  // agents do not pass it.
  if (result.selection !== 'resume-active' && !force) {
    const blocking = readObservations().filter(o => o.severity === 'foundation');
    if (blocking.length) {
      const rows = blocking.map(o => `  - ${o.id} (${o.raisedBy}, ${o.kind}) — ${o.observation}`).join('\n');
      const message =
        `halted: ${blocking.length} open foundation-severity observation${blocking.length > 1 ? 's' : ''} ` +
        `(CONTRACT#rules/unattended-execution, hard stop 4).\n${rows}\n` +
        'The spec, contract, or approach is suspect and continuing to build compounds debt. ' +
        'A human triages these — set the Disposition to accepted or declined in STATUS.md — ' +
        'or re-runs with --force to continue anyway.';
      if (json) {
        console.log(JSON.stringify({ ok: false, error: message, halted: 'foundation-observation', observations: blocking }, null, 2));
        process.exit(2);
      }
      die(message, 2);
    }
  }

  if (json) {
    console.log(JSON.stringify({
      ok: true,
      selection: result.selection,
      warnings: result.warnings,
      task: taskJson(result.task),
    }, null, 2));
  } else {
    printTask(result.task, result.selection, result.warnings);
  }
}

function cmdGet(args, json) {
  const id = args[0];
  if (!id) die('get requires a task ID.\n\n' + USAGE);
  const wp = loadWorkplan();
  const task = wp.taskById.get(id.toUpperCase());
  if (!task) die(`${id} not found in WORKPLAN.md.`);

  if (json) console.log(JSON.stringify({ ok: true, task: taskJson(task) }, null, 2));
  else printTask(task, null, []);
}

function cmdStatus(args, json) {
  const wp = loadWorkplan();
  const { tasks, taskById } = wp;

  const counts = {};
  for (const s of VALID_STATUSES) counts[s] = 0;
  for (const t of tasks) if (counts[t.status] !== undefined) counts[t.status]++;

  const active = tasks.find(t => t.status === 'active') || null;
  const next = tasks.find(t => t.status === 'pending' && unmetDeps(t, taskById).length === 0) || null;
  const clarify = tasks.filter(t => t.type === 'clarify' && (t.status === 'pending' || t.status === 'active'));
  const blocked = tasks.filter(t => t.status === 'blocked');
  const observations = readObservations();

  const brief = t => ({ id: t.id, description: t.description, status: t.status, type: t.type });

  if (json) {
    console.log(JSON.stringify({
      ok: true,
      total: tasks.length,
      counts,
      active: active ? brief(active) : null,
      next: next ? brief(next) : null,
      clarify: clarify.map(brief),
      blocked: blocked.map(brief),
      observations,
    }, null, 2));
    return;
  }

  console.log(`Tasks: ${tasks.length} total — ${counts.done} done, ${counts.active} active, ${counts.pending} pending, ${counts.blocked} blocked`);
  console.log(`Active: ${active ? `${active.id} — ${active.description}` : 'none'}`);
  console.log(`Next unblocked: ${next ? `${next.id} — ${next.description}` : 'none'}`);

  console.log(clarify.length ? 'Clarify tasks awaiting input:' : 'Clarify tasks awaiting input: none');
  for (const t of clarify) console.log(`  - ${t.id} (${t.status}) — ${t.description}`);

  console.log(blocked.length ? 'Blocked tasks:' : 'Blocked tasks: none');
  for (const t of blocked) console.log(`  - ${t.id} — ${t.description}`);

  console.log(observations.length ? 'Open observations:' : 'Open observations: none');
  for (const o of observations) {
    console.log(`  - [${o.severity}] ${o.id} (${o.raisedBy}) — ${o.observation}`);
  }
}

// Re-lint after every write. check-workplan.js resolves the workplan from the
// working directory, same as this script, so it validates what was just
// written. A failure means the mutation was wrong: put the file back.
function writeAndLint(wp, content, successMessage) {
  const original = fs.readFileSync(wp.path, 'utf8');
  fs.writeFileSync(wp.path, content);

  const lint = spawnSync(process.execPath, [path.join(__dirname, 'check-workplan.js')], {
    cwd: ROOT,
    encoding: 'utf8',
  });

  if (lint.status !== 0) {
    fs.writeFileSync(wp.path, original);
    const detail = `${lint.stdout || ''}${lint.stderr || ''}`.trim();
    die(`mutation rejected — check-workplan.js failed, so WORKPLAN.md was reverted:\n${detail}`);
  }

  console.log(successMessage);
}

function cmdSet(args) {
  const force = args.includes('--force');
  const rest = args.filter(a => a !== '--force');
  const [rawId, rawField, ...valueParts] = rest;
  if (!rawId || !rawField || valueParts.length === 0) die('set requires a task ID, a field, and a value.\n\n' + USAGE);

  const id = rawId.toUpperCase();
  const key = rawField.toLowerCase();
  const value = valueParts.join(' ');

  if (!FIELD_NAMES[key]) {
    die(`unknown field "${rawField}". Expected one of: ${Object.values(FIELD_NAMES).join(', ')}.`);
  }

  const wp = loadWorkplan();
  const task = wp.taskById.get(id);
  if (!task) die(`${id} not found in WORKPLAN.md.`);

  if (key === 'status') {
    if (!VALID_STATUSES.includes(value)) {
      die(`invalid Status "${value}". Expected one of: ${VALID_STATUSES.join(', ')}.`);
    }
    if (value !== task.status) {
      const allowed = VALID_TRANSITIONS[task.status] || [];
      if (!allowed.includes(value) && !force) {
        die(`invalid transition ${task.status} → ${value} for ${id} (CONTRACT#state-machines/task-lifecycle allows: ${allowed.length ? allowed.join(', ') : 'none'}). Use --force to override.`);
      }
    }
    // The one-active-task constraint is enforced on write, not only on read:
    // a script that can create a second active task has dropped the invariant
    // it was supposed to carry over from /forge-next.
    if (value === 'active') {
      const other = wp.tasks.find(t => t.status === 'active' && t.id !== id);
      if (other && !force) {
        die(`${other.id} is currently active. Only one task can be active at a time. Complete or block it first, or use --force.`);
      }
    }
  }

  if (key === 'type' && !VALID_TYPES.includes(value)) {
    die(`invalid Type "${value}". Expected one of: ${VALID_TYPES.join(', ')}.`);
  }

  const result = setField(wp, id, key, value);
  if (!result.ok) die(result.error);

  const before = key === 'status' ? task.status : null;
  writeAndLint(wp, result.content,
    before ? `${id} Status: ${before} → ${value}` : `${id} ${FIELD_NAMES[key]} updated.`);
}

function cmdAppendNotes(args) {
  const [rawId, ...textParts] = args;
  if (!rawId || textParts.length === 0) die('append-notes requires a task ID and text.\n\n' + USAGE);

  const id = rawId.toUpperCase();
  const wp = loadWorkplan();
  if (!wp.taskById.has(id)) die(`${id} not found in WORKPLAN.md.`);

  const result = appendNotes(wp, id, textParts.join(' '));
  if (!result.ok) die(result.error);

  writeAndLint(wp, result.content, `${id} Notes: appended.`);
}

// --- Entry point ---

function main(argv) {
  const json = argv.includes('--json');
  const args = argv.filter(a => a !== '--json');
  const command = args[0];
  const rest = args.slice(1);

  switch (command) {
    case 'next': return cmdNext(rest, json);
    case 'get': return cmdGet(rest, json);
    case 'status': return cmdStatus(rest, json);
    case 'set': return cmdSet(rest);
    case 'append-notes': return cmdAppendNotes(rest);
    case undefined: return die(USAGE);
    default: return die(`unknown command "${command}".\n\n${USAGE}`);
  }
}

main(process.argv.slice(2));
```

If it exists, skip — do not overwrite.
### 12. Report completion

After creating all files, tell the user which files were created (existing files were not overwritten), listing only from this set — and only the ones actually created or modified, not skipped:

- `.forge/VISION.md`
- `.forge/CONTRACT.md`
- `.forge/SPEC.md`
- `.forge/STATUS.md`
- `.forge/templates/scaffold.md`
- `.forge/templates/feature.md`
- `.forge/templates/fix.md`
- `.forge/templates/clarify.md`
- `.forge/templates/refactor.md`
- `.forge/templates/investigate.md`
- `.forge/UX.md` (only if step 6 was answered "yes")
- `.forge/templates/ux-spec.md` (only if step 6 was answered "yes")
- `.forge/DESIGN.md` (only if step 6 was answered "yes")
- `.forge/scripts/check-ux-spec.js` (only if step 6 was answered "yes")
- `.forge/scripts/lib/markdown.js`
- `.forge/scripts/lib/workplan.js`
- `.forge/scripts/check-workplan.js`
- `.forge/scripts/wp.js`
- `.forge/scripts/lib/markdown.js`
- `.forge/scripts/check-workplan.js`
- `.claude/settings.json`
- `CLAUDE.md` (integration block)

Then list next steps, numbered, including only the items that apply:

1. Fill in `.forge/VISION.md` with your project's What, Who, and Pillars.
2. Fill in `.forge/CONTRACT.md` with your project's interfaces, rules, and data model.
3. Fill in `.forge/SPEC.md` with your requirements, or leave it for `/forge-spec` to draft.
4. Fill in `.forge/UX.md` with your screen flows and specs. — **only if step 6 was answered "yes"**
5. Fill in `.forge/DESIGN.md` with your design tokens and component specs. — **only if step 6 was answered "yes"**
6. Run `/forge-plan` to generate a task workplan.

Renumber the remaining steps sequentially if step 4 or 5 above was omitted, so the list has no gaps.

If all applicable files already existed, say: "All Forge files already exist. Nothing was changed."
