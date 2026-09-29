#!/usr/bin/env node
// migrate-notes.js — externalize oversized inline Notes into task records
// (CONTRACT#data-model/task-record-data-model, CONTRACT#rules/workplan-access-discipline)
//
// Usage:
//   node .forge/scripts/migrate-notes.js [--dry-run] [--all] [--force]
//
// Why this exists: the externalization threshold only governs notes written
// from now on. Projects that predate it carry the whole debt inline — the
// motivating case is a workplan at 2,177 lines across 67 tasks, most of it
// narrative that CONTRACT#rules/workplan-access-discipline says does not belong
// in the DAG. Without a migration the threshold helps new projects only.
//
// For every task whose Notes exceed 3 lines this writes
// `.forge/notes/TASK-XXX.md` in Task Record Data Model shape and replaces the
// Notes field with a one-line summary plus the record path. Notes of 3 lines or
// fewer are left byte-identical — a file per one-line note is churn.
//
// Summaries are generated mechanically (first sentence of the notes, falling
// back to the task description) rather than by an agent: 67 agent-written
// summaries is its own context problem, and a human can improve any of them
// afterward by hand.
//
// Safety: Forge supports projects where `.forge/` is never committed, so there
// is no git history to recover from. Records are written before WORKPLAN.md is
// touched, a `.bak` is taken immediately before the rewrite, an existing record
// is never overwritten, and a rewrite that fails check-workplan.js is reverted.
//
// Exit codes: 0 success (including nothing to migrate) · 1 usage/safety refusal.

'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const { readWorkplan, parseWorkplan, setField } = require('./lib/workplan');
const { findRoot } = require('./lib/markdown');

// Nearest ancestor of the working directory holding .forge/ (TASK-072).
const ROOT = findRoot();
const WORKPLAN_PATH = path.join(ROOT, '.forge', 'WORKPLAN.md');
const NOTES_DIR = path.join(ROOT, '.forge', 'notes');
const BACKUP_PATH = `${WORKPLAN_PATH}.bak`;

const USAGE = `usage: node .forge/scripts/migrate-notes.js [--dry-run] [--all] [--force]

  --dry-run  report what would be migrated and write nothing
  --all      migrate every status, not just done tasks
  --force    migrate even if check-workplan.js does not pass first`;

// The externalization threshold, in lines of the Notes value as it stands in
// the workplan (CONTRACT#data-model/task-record-data-model). "More than 3",
// so a note of exactly 3 lines stays inline.
const THRESHOLD = 3;

// Already-migrated residue: a summary followed by the record path. Recognized
// explicitly rather than relying on the line count alone, so a hand-expanded
// summary that grew past the threshold is still not re-migrated.
const RECORD_POINTER_RE = /Record:\s*\.forge\/notes\/TASK-\d+\.md/i;

const FILES_LINE_RE = /^\s*Files:\s*(.+)$/i;

function die(message) {
  console.error(`migrate-notes.js: ${message}`);
  process.exit(1);
}

// --- Summary generation ---

// A sentence ends at a period followed by whitespace or end-of-value. That
// keeps `.forge/notes/x.md` and `wp.js` intact, which a naive split on "." does
// not — and paths are the most common thing in these notes.
function firstSentence(text) {
  const flat = text.replace(/\s+/g, ' ').trim();
  if (!flat) return '';
  const m = /^(.*?[.!?])(?:\s|$)/.exec(flat);
  return (m ? m[1] : flat).trim();
}

// Long enough to name what the record contains, short enough to stay a summary.
const SUMMARY_MAX = 160;

function truncate(s) {
  if (s.length <= SUMMARY_MAX) return s;
  const cut = s.slice(0, SUMMARY_MAX - 1);
  const space = cut.lastIndexOf(' ');
  return `${(space > 40 ? cut.slice(0, space) : cut).replace(/[.,;:\s]+$/, '')}…`;
}

// The summary is load-bearing: it is what lets a reader judge whether opening
// the record is warranted, without opening it. A bare pointer relocates the
// problem instead of solving it, so there is always prose before the path —
// the description when the notes yield no usable sentence.
function summarize(task, body) {
  const sentence = firstSentence(body.replace(/^\s*[-*]\s+/, ''));
  const text = sentence || task.description || 'Migrated task notes';
  return `${truncate(text)} Record: .forge/notes/${task.id}.md`;
}

// --- Record rendering ---

// A mechanical migration cannot tell a decision from a deviation from a plain
// account of what happened, and guessing would put words in the original
// author's mouth. So the notes land whole under Outcome, with a provenance line
// saying why the record is flat; Decisions and Deviations are omitted rather
// than fabricated. Only a `Files:` line is lifted, because that convention is
// unambiguous.
function buildRecord(task, body, today) {
  const bodyLines = [];
  const files = [];

  for (const line of body.split('\n')) {
    const m = FILES_LINE_RE.exec(line);
    if (m) {
      for (const p of m[1].split(',').map(s => s.trim()).filter(Boolean)) files.push(p);
      continue;
    }
    bodyLines.push(line);
  }

  while (bodyLines.length && bodyLines[bodyLines.length - 1].trim() === '') bodyLines.pop();

  const out = [
    `# ${task.id} — ${task.description}`,
    '',
    `*Migrated from the WORKPLAN.md Notes field on ${today}. The notes are reproduced`,
    'under Outcome as they were written; Decisions and Deviations were not recorded',
    'separately at the time.*',
    '',
    '## Outcome',
    '',
    ...bodyLines,
  ];

  if (files.length) {
    out.push('', '## Files', '', ...files.map(p => `- ${p}`));
  }

  return `${out.join('\n').replace(/\s+$/, '')}\n`;
}

// --- Lint ---

function lint() {
  return spawnSync(process.execPath, [path.join(__dirname, 'check-workplan.js')], {
    cwd: ROOT,
    encoding: 'utf8',
  });
}

// --- Main ---

function main(argv) {
  const dryRun = argv.includes('--dry-run');
  const all = argv.includes('--all');
  const force = argv.includes('--force');
  const unknown = argv.find(a => !['--dry-run', '--all', '--force'].includes(a));
  if (unknown) die(`unexpected argument "${unknown}".\n\n${USAGE}`);

  const wp = readWorkplan(ROOT);
  if (!wp) die('.forge/WORKPLAN.md not found. Run /forge-plan to generate one.');
  if (wp.tasks.length === 0) die('no tasks found in .forge/WORKPLAN.md.');

  // Pre-flight lint. Migrating a workplan that is already broken makes the .bak
  // the only way back, and in these projects nothing stands behind it. The
  // result is kept because it is also what makes the post-write lint below
  // meaningful: a workplan that did not lint before cannot be held to linting
  // after, and treating that as damage would revert a migration that was fine.
  const preClean = lint();
  if (preClean.status !== 0 && !force) {
    const detail = `${preClean.stdout || ''}${preClean.stderr || ''}`.trim();
    die(`refusing to migrate — check-workplan.js does not pass on the current WORKPLAN.md:\n${detail}\n\nFix the workplan first, or re-run with --force.`);
  }
  const wasClean = preClean.status === 0;

  // --- Select candidates ---
  // Done tasks only by default. A pending or active task's Notes are the
  // planner's instructions to the agent that will execute it, and a record is
  // read only when a task declares it in its Context field — so externalizing
  // them puts working instructions somewhere /forge-next will never look. A
  // blocked task's Notes say what is blocking it, which its resumption needs.
  // `--all` is there for the human who has decided otherwise.
  const candidates = [];
  const skipped = [];

  for (const task of wp.tasks) {
    const body = (task.notes || '').replace(/\s+$/, '');
    if (!body) continue;
    if (RECORD_POINTER_RE.test(body)) continue;
    if (body.split('\n').length <= THRESHOLD) continue;
    if (!all && task.status !== 'done') {
      skipped.push({ task, reason: `status is ${task.status} — use --all to include it` });
      continue;
    }
    const recordPath = path.join(NOTES_DIR, `${task.id}.md`);
    if (fs.existsSync(recordPath)) {
      skipped.push({ task, reason: `.forge/notes/${task.id}.md already exists — not overwriting it` });
      continue;
    }
    candidates.push({ task, body, recordPath });
  }

  for (const s of skipped) console.log(`skip ${s.task.id}: ${s.reason}`);

  if (candidates.length === 0) {
    console.log('Nothing to migrate.');
    return;
  }

  for (const c of candidates) {
    const lines = c.body.split('\n').length;
    console.log(`${dryRun ? 'would migrate' : 'migrate'} ${c.task.id}: ${lines} lines -> .forge/notes/${c.task.id}.md`);
  }

  if (dryRun) {
    console.log(`Would migrate ${candidates.length} task(s). Nothing was written.`);
    return;
  }

  // --- Write records first ---
  // Additive and reversible: if anything below fails, the records are the only
  // thing on disk and the workplan still holds the notes they were built from.
  const today = new Date().toISOString().slice(0, 10);
  fs.mkdirSync(NOTES_DIR, { recursive: true });
  for (const c of candidates) {
    fs.writeFileSync(c.recordPath, buildRecord(c.task, c.body, today));
  }

  // --- Then rewrite the workplan ---
  // setField works from parsed line ranges, so the parse is refreshed after
  // each edit rather than tracking how the previous edit shifted the file.
  let content = wp.content;
  for (const c of candidates) {
    const parsed = parseWorkplan(content);
    const result = setField(parsed, c.task.id, 'notes', summarize(c.task, c.body));
    if (!result.ok) die(`could not rewrite ${c.task.id} Notes: ${result.error} (records were written; WORKPLAN.md is unchanged)`);
    content = result.content;
  }

  const original = fs.readFileSync(WORKPLAN_PATH, 'utf8');
  fs.writeFileSync(BACKUP_PATH, original);
  fs.writeFileSync(WORKPLAN_PATH, content);

  const post = lint();
  if (post.status !== 0) {
    const detail = `${post.stdout || ''}${post.stderr || ''}`.trim();
    if (wasClean) {
      fs.writeFileSync(WORKPLAN_PATH, original);
      die(`migration rejected — check-workplan.js failed afterward, so WORKPLAN.md was restored:\n${detail}\n\nThe records under .forge/notes/ were left in place for inspection.`);
    }
    console.log(`warning: check-workplan.js still fails. It failed before the migration too and --force was passed, so this is not attributed to the rewrite:\n${detail}`);
  }

  console.log(`Migrated ${candidates.length} task(s). Backup: .forge/WORKPLAN.md.bak`);
}

main(process.argv.slice(2));
