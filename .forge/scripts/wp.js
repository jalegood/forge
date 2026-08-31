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
// Exit codes (CONTRACT#interfaces/script-exit-codes): 0 success · 1 usage or
// validation error · 2 nothing to select · 3 foundation-observation halt · 4
// gate-discrimination probe refusal.

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
const { createLoader, resolveRef, findRoot } = require('./lib/markdown');

// Nearest ancestor of the working directory holding .forge/, falling back to
// the installed location — works from a subdirectory and by absolute path
// (TASK-072).
const ROOT = findRoot();

const USAGE = `usage: node .forge/scripts/wp.js <command>

  next [TASK-XXX] [--force] [--json]
                               select the task to execute and emit its fields;
                               exits 2 when there is nothing to select, and
                               halts (exit 3) while an open foundation-severity
                               observation exists, unless --force
  get TASK-XXX [--json]        emit one task's fields
  status [--json]              counts, next unblocked task, clarify tasks, open observations
  set TASK-XXX <field> <value> [--force]
                               set Status, Type, Depends, Context, Gate, or Notes;
                               pending -> active runs the task's gate first and
                               refuses (exit 4) a gate that already passes
                               pre-work (CONTRACT#rules/gate-discrimination)
  append-notes TASK-XXX <text> append a line to a task's Notes field

Exit codes follow CONTRACT#interfaces/script-exit-codes: 0 success, 1 usage or
validation error, 2 nothing to select, 3 foundation-observation halt, 4
gate-discrimination probe refusal.`;

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
        process.exit(3);
      }
      die(message, 3);
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

      // Gate-discrimination probe (CONTRACT#rules/gate-discrimination,
      // obligation 2): a gate that already passes against the pre-work tree
      // certifies nothing, so the task must not proceed on it. Probing at the
      // pending -> active transition rather than in /forge-next's prose is the
      // point — a step an agent is merely told to run is a step it may skip,
      // which is how all recorded vacuous-gate instances shipped.
      //
      // manual: gates are exempt (no command to run). Resuming an already-
      // active task performs no transition and never reaches this branch.
      // --force is the human's override, same as `next --force`; agents repair
      // the gate instead, via `set TASK-XXX gate '<discriminating gate>'` on
      // the still-pending task.
      if (task.status === 'pending' && !force && !/^manual:/.test(task.gate || '')) {
        const probe = spawnSync('bash', ['-c', task.gate], {
          cwd: ROOT,
          encoding: 'utf8',
          timeout: 300000,
        });
        if (probe.error) {
          die(`gate-discrimination probe could not run the gate (${probe.error.message}). ` +
              `Fix the environment or the gate before activating ${id}.`);
        }
        if (probe.status === 0) {
          const output = `${probe.stdout || ''}${probe.stderr || ''}`.trim();
          die(
            `refused: ${id}'s gate already passes against the pre-work tree, so it cannot ` +
            `verify this task's work (CONTRACT#rules/gate-discrimination).\n` +
            `  Gate: ${task.gate}\n` +
            (output ? `  Output:\n${output.split('\n').map(l => `    ${l}`).join('\n')}\n` : '') +
            `Repair the gate to assert this task's change (wp.js set ${id} gate '<discriminating gate>') and retry. ` +
            `If the gate is right and the work already exists, a prior task absorbed this task's scope — ` +
            `report that to the human instead of proceeding. --force is the human's override.`,
            4
          );
        }
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
