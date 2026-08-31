#!/usr/bin/env node
// obs.js — deterministic STATUS.md Observations query and mutation
// (CONTRACT#interfaces/observation-script)
//
// Usage:
//   node .forge/scripts/obs.js add --kind K --severity S --task TASK-XXX "<text>"
//   node .forge/scripts/obs.js set OBS-XXX <field> <value>
//   node .forge/scripts/obs.js list [--json] [--disposition D] [--severity S]
//   node .forge/scripts/obs.js sweep [--apply]
//
// Why this exists: the row format was restated in ~18 places and hand-written
// every time. A hand-written row is how a literal `|` reaches a cell and
// silently removes the row from every reader — including the foundation hard
// stop, which then reports a clear queue while the row that should have halted
// the loop is invisible. This script is the only supported writer: it mints
// the ID against the file at write time, stamps the date, escapes the text,
// and re-validates through check-status.js before the write is allowed to
// stand.
//
// Write discipline (the pattern wp.js established): write the file, run the
// lint, restore the original and fail loudly if the lint rejects it. A
// mutation that leaves the artifact invalid is worse than a refused one.
//
// Exit codes (CONTRACT#interfaces/script-exit-codes): 0 success · 1 usage or
// validation error.

'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { parseTable, findRoot } = require('./lib/markdown');
const { readWorkplan } = require('./lib/workplan');

const ROOT = findRoot();
const STATUS_PATH = path.join(ROOT, '.forge', 'STATUS.md');

const COLUMNS = ['ID', 'Date', 'Raised by', 'Kind', 'Severity', 'Observation', 'Disposition'];
const KINDS = ['design', 'bug', 'scope', 'friction'];
const SEVERITIES = ['normal', 'foundation'];

// CONTRACT#state-machines/observation-lifecycle. `planned:` and `duplicate:`
// carry a target, so they are matched by prefix rather than listed.
const TRANSITIONS = {
  open: ['accepted', 'declined', 'duplicate:'],
  accepted: ['planned:', 'declined'],
  'planned:': ['closed', 'open'],
  declined: [],
  'duplicate:': [],
  closed: [],
};

const USAGE = `usage: node .forge/scripts/obs.js <command>

  add --kind K --severity S --task TASK-XXX "<text>"
                               append a row: mints the ID at write time, stamps
                               today's date, escapes pipes, disposition "open"
  set OBS-XXX <field> <value>  targeted field write; refuses an invalid
                               Disposition transition
  list [--json] [--disposition D] [--severity S]
                               projection with computed age in days
  sweep [--apply]              deterministic triage: closes planned: rows whose
                               task is done, reports unlinked accepted rows and
                               duplicate text. Reports only unless --apply

  Kinds:      ${KINDS.join(', ')}
  Severities: ${SEVERITIES.join(', ')}`;

function die(message, code) {
  console.error(`obs.js: ${message}`);
  process.exit(code === undefined ? 1 : code);
}

function today() {
  return new Date().toISOString().slice(0, 10);
}

function ageDays(date) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return null;
  return Math.floor((Date.now() - new Date(date + 'T00:00:00Z')) / 86400000);
}

function readStatus() {
  if (!fs.existsSync(STATUS_PATH)) die(`${STATUS_PATH} not found.`);
  return fs.readFileSync(STATUS_PATH, 'utf8');
}

// Locate the Observations section and its table lines within the file.
function locateTable(text) {
  const lines = text.split('\n');
  let start = -1;
  let inFence = false;
  for (let i = 0; i < lines.length; i++) {
    if (/^\s*(```|~~~)/.test(lines[i])) { inFence = !inFence; continue; }
    if (inFence) continue;
    if (/^## Observations\s*$/.test(lines[i])) { start = i; break; }
    if (start !== -1 && /^## /.test(lines[i])) break;
  }
  if (start === -1) die('STATUS.md has no "## Observations" section.');

  let headerIdx = -1;
  let lastRowIdx = -1;
  for (let i = start + 1; i < lines.length; i++) {
    if (/^## /.test(lines[i])) break;
    if (lines[i].trim().startsWith('|')) {
      if (headerIdx === -1) headerIdx = i;
      lastRowIdx = i;
    }
  }
  if (headerIdx === -1) die('STATUS.md Observations section has no table.');
  return { lines, headerIdx, lastRowIdx };
}

function parseRows(text) {
  const { lines, headerIdx } = locateTable(text);
  const body = lines.slice(headerIdx).join('\n');
  const t = parseTable(body);
  if (!t.ok) {
    const detail = t.errors.map(e => `  ${e.reason}`).join('\n');
    die(`STATUS.md Observations table is malformed — refusing to operate on it.\n${detail}\nRun node .forge/scripts/check-status.js for the full report.`);
  }
  if (t.columns.join(' ') !== COLUMNS.join(' ')) {
    die(`STATUS.md Observations columns are [${t.columns.join(' | ')}], expected [${COLUMNS.join(' | ')}].`);
  }
  return t.rows.map(r => r.cells);
}

// Write, lint, revert on failure. check-status.js is the validator; a mutation
// that leaves STATUS.md invalid never stands.
function writeAndLint(newText, what) {
  const original = fs.readFileSync(STATUS_PATH, 'utf8');
  fs.writeFileSync(STATUS_PATH, newText);
  const lint = spawnSync(process.execPath, [path.join(__dirname, 'check-status.js')], {
    cwd: ROOT,
    encoding: 'utf8',
  });
  if (lint.status !== 0) {
    fs.writeFileSync(STATUS_PATH, original);
    const detail = `${lint.stdout || ''}${lint.stderr || ''}`.trim();
    die(`${what} rejected — check-status.js failed, so STATUS.md was reverted:\n${detail}`);
  }
}

// A bare `|` inside a cell terminates it and silently drops the row from every
// reader (CONTRACT#data-model/markdown-table-parsing). Escaping is this
// script's job precisely so no caller has to remember.
function escapeCell(text) {
  return text.replace(/\r?\n/g, ' ').replace(/\\\|/g, '|').replace(/\|/g, '\\|').trim();
}

function nextId(rows) {
  // Minted against the file at write time, never from a stale read — the same
  // discipline Rules/Task Ordering states for task IDs.
  const max = rows.reduce((m, r) => {
    const n = Number(String(r['ID']).replace('OBS-', ''));
    return Number.isFinite(n) && n > m ? n : m;
  }, 0);
  return `OBS-${String(max + 1).padStart(3, '0')}`;
}

function flagValue(args, name) {
  const i = args.indexOf(name);
  if (i === -1) return null;
  return args[i + 1];
}

// --- Commands ---

function cmdAdd(args) {
  const kind = flagValue(args, '--kind');
  const severity = flagValue(args, '--severity');
  const task = flagValue(args, '--task');
  const text = args.filter((a, i) =>
    !a.startsWith('--') &&
    args[i - 1] !== '--kind' && args[i - 1] !== '--severity' && args[i - 1] !== '--task'
  ).join(' ');

  if (!kind || !severity || !task || !text) die(`add requires --kind, --severity, --task, and text.\n\n${USAGE}`);
  if (!KINDS.includes(kind)) die(`invalid --kind "${kind}". Expected one of: ${KINDS.join(', ')}.`);
  if (!SEVERITIES.includes(severity)) die(`invalid --severity "${severity}". Expected one of: ${SEVERITIES.join(', ')}.`);
  if (!/^TASK-\d+$/i.test(task)) die(`invalid --task "${task}". Expected TASK-XXX.`);

  const original = readStatus();
  const rows = parseRows(original);
  const id = nextId(rows);
  const { lines, lastRowIdx } = locateTable(original);
  const row = `| ${id} | ${today()} | ${task.toUpperCase()} | ${kind} | ${severity} | ${escapeCell(text)} | open |`;
  const out = [...lines.slice(0, lastRowIdx + 1), row, ...lines.slice(lastRowIdx + 1)];
  writeAndLint(out.join('\n'), `${id}`);
  console.log(`${id} recorded (${severity}, ${kind}, raised by ${task.toUpperCase()}).`);
}

function transitionAllowed(from, to) {
  const key = /^planned:/.test(from) ? 'planned:' : /^duplicate:/.test(from) ? 'duplicate:' : from;
  const allowed = TRANSITIONS[key];
  if (!allowed) return false;
  return allowed.some(a => (a.endsWith(':') ? to.startsWith(a) : to === a));
}

function cmdSet(args) {
  const [rawId, rawField, ...valueParts] = args;
  if (!rawId || !rawField || valueParts.length === 0) die(`set requires an observation ID, a field, and a value.\n\n${USAGE}`);
  const id = rawId.toUpperCase();
  const field = COLUMNS.find(c => c.toLowerCase().replace(/[^a-z]/g, '') === rawField.toLowerCase().replace(/[^a-z]/g, ''));
  if (!field) die(`unknown field "${rawField}". Expected one of: ${COLUMNS.join(', ')}.`);
  const value = valueParts.join(' ');

  const original = readStatus();
  const rows = parseRows(original);
  const row = rows.find(r => r['ID'] === id);
  if (!row) die(`${id} not found in STATUS.md.`);

  if (field === 'Disposition' && value !== row['Disposition']) {
    if (!transitionAllowed(row['Disposition'], value)) {
      die(`invalid transition ${row['Disposition']} → ${value} for ${id} (CONTRACT#state-machines/observation-lifecycle allows: ${(TRANSITIONS[/^planned:/.test(row['Disposition']) ? 'planned:' : /^duplicate:/.test(row['Disposition']) ? 'duplicate:' : row['Disposition']] || []).join(', ') || 'none'}).`);
    }
  }
  if (field === 'Kind' && !KINDS.includes(value)) die(`invalid Kind "${value}". Expected one of: ${KINDS.join(', ')}.`);
  if (field === 'Severity' && !SEVERITIES.includes(value)) die(`invalid Severity "${value}". Expected one of: ${SEVERITIES.join(', ')}.`);

  const { lines } = locateTable(original);
  const idx = lines.findIndex(l => l.trim().startsWith(`| ${id} `));
  if (idx === -1) die(`${id}'s row could not be located for rewrite.`);
  const updated = { ...row, [field]: field === 'Observation' ? escapeCell(value) : value };
  lines[idx] = '| ' + COLUMNS.map(c => updated[c]).join(' | ') + ' |';
  writeAndLint(lines.join('\n'), `${id} ${field}`);
  console.log(`${id} ${field}: ${row[field]} → ${updated[field]}`);
}

function cmdList(args) {
  const json = args.includes('--json');
  const wantDisposition = flagValue(args, '--disposition');
  const wantSeverity = flagValue(args, '--severity');

  let rows = parseRows(readStatus()).map(r => ({
    id: r['ID'],
    date: r['Date'],
    ageDays: ageDays(r['Date']),
    raisedBy: r['Raised by'],
    kind: r['Kind'],
    severity: r['Severity'],
    observation: r['Observation'],
    disposition: r['Disposition'],
  }));
  if (wantDisposition) rows = rows.filter(r => r.disposition === wantDisposition || r.disposition.startsWith(wantDisposition));
  if (wantSeverity) rows = rows.filter(r => r.severity === wantSeverity);

  // foundation first: the severity that means "stop and reconsider" must not
  // be buried under routine friction rows.
  rows.sort((a, b) => (a.severity === 'foundation' ? 0 : 1) - (b.severity === 'foundation' ? 0 : 1));

  if (json) { console.log(JSON.stringify({ ok: true, observations: rows }, null, 2)); return; }
  if (!rows.length) { console.log('No observations match.'); return; }
  for (const r of rows) {
    console.log(`${r.id} [${r.severity}/${r.kind}] ${r.disposition} · ${r.ageDays}d · ${r.raisedBy}`);
    console.log(`  ${r.observation}`);
  }
}

function cmdSweep(args) {
  const apply = args.includes('--apply');
  const original = readStatus();
  const rows = parseRows(original);
  const wp = readWorkplan(ROOT);
  const taskStatus = new Map((wp ? wp.tasks : []).map(t => [t.id, t.status]));

  const toClose = [];
  const unlinkedAccepted = [];
  const duplicateText = new Map();

  for (const r of rows) {
    const planned = /^planned:(TASK-\d+)$/.exec(r['Disposition']);
    if (planned && taskStatus.get(planned[1]) === 'done') {
      toClose.push({ id: r['ID'], task: planned[1] });
    }
    if (r['Disposition'] === 'accepted') {
      unlinkedAccepted.push({ id: r['ID'], age: ageDays(r['Date']) });
    }
    const key = r['Observation'].trim().toLowerCase();
    if (!duplicateText.has(key)) duplicateText.set(key, []);
    duplicateText.get(key).push(r['ID']);
  }

  // The only judgment-free transition in the lifecycle: when the named task is
  // done, the observation is resolved by definition. Everything else is
  // reported for a human — this pass makes no judgment call and takes no input.
  if (toClose.length) {
    console.log(`planned: rows whose task is done (${toClose.length}):`);
    for (const c of toClose) console.log(`  ${c.id} — ${c.task} is done → closed`);
  } else {
    console.log('planned: rows whose task is done: none');
  }

  if (unlinkedAccepted.length) {
    console.log(`accepted rows with no task link (${unlinkedAccepted.length}) — awaiting planning:`);
    for (const a of unlinkedAccepted) console.log(`  ${a.id} — accepted ${a.age} days ago`);
  } else {
    console.log('accepted rows with no task link: none');
  }

  const dups = [...duplicateText.values()].filter(ids => ids.length > 1);
  if (dups.length) {
    console.log(`exact-duplicate observation text (${dups.length} group(s)):`);
    for (const ids of dups) console.log(`  ${ids.join(', ')}`);
  } else {
    console.log('exact-duplicate observation text: none');
  }

  if (!apply) {
    if (toClose.length) console.log('\nRe-run with --apply to close the rows above.');
    return;
  }
  if (!toClose.length) return;

  const { lines } = locateTable(original);
  for (const c of toClose) {
    const idx = lines.findIndex(l => l.trim().startsWith(`| ${c.id} `));
    if (idx === -1) continue;
    lines[idx] = lines[idx].replace(/\|\s*planned:TASK-\d+\s*\|\s*$/, '| closed |');
  }
  writeAndLint(lines.join('\n'), 'sweep');
  console.log(`\nClosed ${toClose.length} row(s).`);
}

function main(argv) {
  const [command, ...rest] = argv;
  switch (command) {
    case 'add': return cmdAdd(rest);
    case 'set': return cmdSet(rest);
    case 'list': return cmdList(rest);
    case 'sweep': return cmdSweep(rest);
    case undefined: return die(USAGE);
    default: return die(`unknown command "${command}".\n\n${USAGE}`);
  }
}

main(process.argv.slice(2));
