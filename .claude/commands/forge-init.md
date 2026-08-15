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

### 4. Create `.forge/templates/` with all 6 template files if absent

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

### 5. Ask whether the project has a user-facing interface, then create `.forge/UX.md` if needed

Ask the human: **"Does this project have a user-facing interface (UI/UX)?"**

If the answer is unclear, ask again — do not guess a default.

- **If no:** skip this step, step 6 (`DESIGN.md`), and step 7 (`check-ux-spec.js`) entirely. Do not create `.forge/UX.md`, `.forge/DESIGN.md`, or `.forge/scripts/check-ux-spec.js`. Proceed to step 8.
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

Also create `.forge/templates/ux-spec.md` if absent (only reached when step 5 was answered "yes" — skipped otherwise):

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

### 6. Create `.forge/DESIGN.md` if absent

Only run this step if step 5 was answered "yes". If it was answered "no", this step was already skipped.

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

### 7. Create `.forge/scripts/check-ux-spec.js` if absent

Only run this step if step 5 was answered "yes". If it was answered "no", this step was already skipped.

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

### 8. Create `.claude/settings.json` if absent

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

### 9. Append Forge integration block to `CLAUDE.md` if absent

Check if `CLAUDE.md` exists in the project root.

- If `CLAUDE.md` does **not** exist, create it with exactly:

```markdown
## Forge

- Pipeline: .forge/ (VISION.md, CONTRACT.md, WORKPLAN.md)
- Workflow: /forge-next → review → commit → /clear
- Do not modify CONTRACT.md without asking first
```

- If `CLAUDE.md` exists, check whether it already contains `Pipeline: .forge/`. If it does, skip — do not append. If it does not contain that line, append the integration block to the end of the file (preceded by a blank line).

### 10. Create `.forge/scripts/check-workplan.js` and `.forge/scripts/lib/markdown.js` if absent

Unconditional — these are not gated on the step 5 interface question. `/forge-next` and `/forge-plan` both run the workplan lint after every WORKPLAN.md write and treat a nonzero exit as a hard block, so a project without these files cannot complete a task.

Create `.forge/scripts/lib/` (both the `scripts` and `lib` directories) if needed.

Both blocks below are exact copies of the engine's scripts. Copy them verbatim — they are diffed against the originals by `.forge/tests/test-init-scripts.sh`, and the `<!-- forge-init:embed -->` markers are what that test keys on. Do not edit the payloads in place; if a script changes, re-copy the whole block.

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

const ROOT = process.cwd();
const workplanPath = path.join(ROOT, '.forge', 'WORKPLAN.md');

if (!fs.existsSync(workplanPath)) {
  console.error('Error: .forge/WORKPLAN.md not found');
  process.exit(1);
}

const content = fs.readFileSync(workplanPath, 'utf8').replace(/\r\n/g, '\n');

const VALID_STATUSES = ['pending', 'active', 'done', 'blocked'];
const VALID_TYPES = ['scaffold', 'feature', 'clarify', 'refactor', 'fix', 'investigate', 'ux-spec', 'checkpoint'];
const CODE_EXTENSIONS = ['js', 'ts', 'jsx', 'tsx', 'py', 'rb', 'go', 'java', 'c', 'cpp', 'cs', 'php', 'rs'];

const errors = [];
const warnings = [];

// --- Parse tasks ---

const headerRegex = /^## \[(TASK-\d+)\]\s*(.*)$/gm;
const headerMatches = [];
let hm;
while ((hm = headerRegex.exec(content)) !== null) {
  headerMatches.push({ id: hm[1], description: hm[2].trim(), index: hm.index });
}

if (headerMatches.length === 0) {
  console.error('Error: no tasks found in WORKPLAN.md');
  process.exit(1);
}

function field(block, name) {
  const re = new RegExp(`^- \\*\\*${name}:\\*\\*\\s*(.*)$`, 'm');
  const fm = re.exec(block);
  return fm ? fm[1].trim() : null;
}

function stripBackticks(s) {
  if (!s) return s;
  const m = /^`([\s\S]*)`$/.exec(s.trim());
  return m ? m[1] : s;
}

const tasks = headerMatches.map((hmt, i) => {
  const start = hmt.index;
  const end = i + 1 < headerMatches.length ? headerMatches[i + 1].index : content.length;
  const block = content.slice(start, end);
  return {
    id: hmt.id,
    description: hmt.description,
    order: i,
    status: field(block, 'Status'),
    type: field(block, 'Type'),
    depends: field(block, 'Depends'),
    contextRaw: field(block, 'Context'),
    gate: stripBackticks(field(block, 'Gate')),
  };
});

const taskById = new Map(tasks.map(t => [t.id, t]));

function dependsList(t) {
  if (!t.depends || t.depends === 'none') return [];
  return t.depends.split(',').map(s => s.trim()).filter(Boolean);
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
for (const hmt of headerMatches) idCounts.set(hmt.id, (idCounts.get(hmt.id) || 0) + 1);
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

### 11. Report completion

After creating all files, tell the user which files were created (existing files were not overwritten), listing only from this set — and only the ones actually created or modified, not skipped:

- `.forge/VISION.md`
- `.forge/CONTRACT.md`
- `.forge/SPEC.md`
- `.forge/templates/scaffold.md`
- `.forge/templates/feature.md`
- `.forge/templates/fix.md`
- `.forge/templates/clarify.md`
- `.forge/templates/refactor.md`
- `.forge/templates/investigate.md`
- `.forge/UX.md` (only if step 5 was answered "yes")
- `.forge/templates/ux-spec.md` (only if step 5 was answered "yes")
- `.forge/DESIGN.md` (only if step 5 was answered "yes")
- `.forge/scripts/check-ux-spec.js` (only if step 5 was answered "yes")
- `.forge/scripts/lib/markdown.js`
- `.forge/scripts/check-workplan.js`
- `.claude/settings.json`
- `CLAUDE.md` (integration block)

Then list next steps, numbered, including only the items that apply:

1. Fill in `.forge/VISION.md` with your project's What, Who, and Pillars.
2. Fill in `.forge/CONTRACT.md` with your project's interfaces, rules, and data model.
3. Fill in `.forge/SPEC.md` with your requirements, or leave it for `/forge-spec` to draft.
4. Fill in `.forge/UX.md` with your screen flows and specs. — **only if step 5 was answered "yes"**
5. Fill in `.forge/DESIGN.md` with your design tokens and component specs. — **only if step 5 was answered "yes"**
6. Run `/forge-plan` to generate a task workplan.

Renumber the remaining steps sequentially if step 4 or 5 above was omitted, so the list has no gaps.

If all applicable files already existed, say: "All Forge files already exist. Nothing was changed."
