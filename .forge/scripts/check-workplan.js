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
const { createLoader, resolveRef, findRoot } = require('./lib/markdown');
const {
  VALID_STATUSES,
  VALID_TYPES,
  parseWorkplan,
  dependsList,
} = require('./lib/workplan');

// Nearest ancestor of the working directory holding .forge/, falling back to
// the installed location — works from a subdirectory and by absolute path
// (TASK-072).
const ROOT = findRoot();
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
