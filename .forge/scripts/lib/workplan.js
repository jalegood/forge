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
