#!/usr/bin/env bash
set -e

# Validates .forge/scripts/lib/markdown.js — the shared section resolver that
# check-workplan.js, check-ux-spec.js, wp.js and /forge-next all depend on for
# turning a Context reference into a slice of a document.
#
# The resolver had no test file when TASK-050 extracted it from its two callers,
# and the extraction silently dropped the requirement-heading rule
# (CONTRACT#data-model/context-manifest). That regression was invisible: a
# dropped matching rule looks exactly like an unresolvable reference, so the
# only symptom was that `SPEC#requirements/req-*` refs could never be written.
# The bracketed-heading cases below are the guard against losing it again; the
# rest pin the properties the callers rely on.

cd "$(dirname "$0")/../.."

node - << 'NODE'
'use strict';
const assert = require('assert');
const md = require('./.forge/scripts/lib/markdown.js');

let failures = 0;
function check(name, fn) {
  try { fn(); console.log('  ' + name + ': OK'); }
  catch (e) { failures++; console.log('  ' + name + ': FAILED — ' + e.message); }
}

// A one-file loader, so reference resolution can be tested without touching disk.
function loaderFor(files) {
  const cache = {};
  for (const [rel, content] of Object.entries(files)) {
    cache[rel] = { content, headings: md.parseHeadings(content) };
  }
  return rel => cache[rel] || null;
}

const SPEC = [
  '# Spec',
  '',
  '## Overview',
  '',
  'Prose.',
  '',
  '## Requirements',
  '',
  '### [req-login] User Login',
  '',
  'The user signs in.',
  '',
  '### [req-logout] User Logout',
  '',
  'The user signs out.',
  '',
  '## Non-Goals',
  '',
  '### [req-login] Decoy In A Sibling Section',
  '',
  'Must not be reachable from requirements/req-login.',
  '',
].join('\n');

// Same slugs, prose names rewritten — a manifest written against the old names
// must keep resolving.
const SPEC_REWORDED = SPEC
  .replace('[req-login] User Login', '[req-login] Authenticating an existing account')
  .replace('[req-logout] User Logout', '[req-logout] Ending a session');

const load = loaderFor({ 'SPEC.md': SPEC });
const loadReworded = loaderFor({ 'SPEC.md': SPEC_REWORDED });

// --- the requirement-heading rule ---

check('bracketed heading matches its bare slug', () => {
  const r = md.resolveRef('SPEC#requirements/req-login', load);
  assert.ok(r.ok, r.reason);
  assert.strictEqual(r.heading.text, '[req-login] User Login');
  assert.ok(r.section.includes('The user signs in.'));
});

check('rewording the requirement name does not break the reference', () => {
  const r = md.resolveRef('SPEC#requirements/req-login', loadReworded);
  assert.ok(r.ok, r.reason);
  assert.strictEqual(r.heading.text, '[req-login] Authenticating an existing account');
});

check('the trailing name text is not part of the match', () => {
  // Matching on "slug + name" is the failure mode the rule exists to prevent:
  // it resolves today and breaks the next time the prose is edited.
  const r = md.resolveRef('SPEC#requirements/req-login-user-login', load);
  assert.ok(!r.ok, 'a slug+name reference must not resolve');
});

check('the rule is about bracketed headings, not about SPEC.md', () => {
  const doc = ['# Design', '', '## Components', '', '### [button] Primary Button', '', 'Spec.', ''].join('\n');
  const r = md.resolveRef('specs/design#components/button', loaderFor({ 'specs/design.md': doc }));
  assert.ok(r.ok, r.reason);
});

check('bracketed matching is scoped by the parent segment', () => {
  const r = md.resolveRef('SPEC#requirements/req-login', load);
  assert.ok(r.ok, r.reason);
  assert.ok(!r.section.includes('Decoy'), 'must resolve inside Requirements, not Non-Goals');
});

// --- properties the callers depend on ---

check('plain headings still match by slug', () => {
  const r = md.resolveRef('SPEC#requirements', load);
  assert.ok(r.ok, r.reason);
  assert.ok(r.section.startsWith('## Requirements'));
});

check('a section ends at the next same-or-higher heading', () => {
  const r = md.resolveRef('SPEC#overview', load);
  assert.ok(r.ok, r.reason);
  assert.ok(r.section.includes('Prose.'));
  assert.ok(!r.section.includes('## Requirements'));
});

check('heading-like lines inside a fence are not headings', () => {
  const doc = [
    '# Contract', '', '## Data Model', '', 'Before the fence.', '',
    '```markdown', '## Requirements', '### [req-example] Example', '```', '',
    'After the fence.', '', '## Rules', '', 'Other section.', '',
  ].join('\n');
  const fenced = loaderFor({ 'CONTRACT.md': doc });
  const r = md.resolveRef('CONTRACT#data-model', fenced);
  assert.ok(r.ok, r.reason);
  assert.ok(r.section.includes('After the fence.'), 'section truncated at the fence');
  assert.ok(!r.section.includes('Other section.'), 'section ran past its real end');
  const decoy = md.resolveRef('CONTRACT#data-model/req-example', fenced);
  assert.ok(!decoy.ok, 'a fenced example heading must not be addressable');
});

check('parseTable keys rows by column name and honors escapes', () => {
  // CONTRACT#data-model/markdown-table-parsing (TASK-081): `\|` is a literal
  // pipe, a pipe inside a backtick span is content, and readers parse by
  // column name so a row survives a column being added elsewhere.
  const doc = [
    '| ID | Text | State |',
    '| -- | ---- | ----- |',
    '| A1 | an escaped \\| pipe | open |',
    '| A2 | code `a | b` span | closed |',
  ].join('\n');
  const t = md.parseTable(doc);
  assert.ok(t.ok, JSON.stringify(t.errors));
  assert.strictEqual(t.rows.length, 2);
  assert.strictEqual(t.rows[0].cells['Text'], 'an escaped | pipe');
  assert.strictEqual(t.rows[0].cells['State'], 'open');
  assert.strictEqual(t.rows[1].cells['Text'], 'code `a | b` span');
  assert.strictEqual(t.rows[1].cells['State'], 'closed');
});

check('parseTable reports a malformed row as an error, never a dropped row', () => {
  const doc = [
    '| ID | Text | State |',
    '| -- | ---- | ----- |',
    '| A1 | an unescaped | pipe | open |',
    '| A2 | fine | open |',
  ].join('\n');
  const t = md.parseTable(doc);
  assert.ok(!t.ok, 'a malformed row must fail the parse');
  assert.strictEqual(t.errors.length, 1, 'exactly one malformed row');
  assert.strictEqual(t.errors[0].lineNumber, 3);
  assert.ok(/escape/.test(t.errors[0].reason), 'the error must say how to fix it');
  // the well-formed row still parses — the error does not hide the rest
  assert.strictEqual(t.rows.length, 1);
  assert.strictEqual(t.rows[0].cells['ID'], 'A2');
});

check('parseTable ignores heading-like tables inside fences', () => {
  const doc = [
    '```markdown',
    '| Bogus | Header |',
    '| ----- | ------ |',
    '| x | y |',
    '```',
    '',
    '| Real | Col |',
    '| ---- | --- |',
    '| 1 | 2 |',
  ].join('\n');
  const t = md.parseTable(doc);
  assert.ok(t.ok, JSON.stringify(t.errors));
  assert.deepStrictEqual(t.columns, ['Real', 'Col']);
  assert.strictEqual(t.rows.length, 1);
});

check('punctuation-mismatched references match by alphanumeric compaction', () => {
  // Normative rule in CONTRACT#data-model/context-manifest (TASK-079): both
  // heading text and reference segment reduce to lowercase alphanumerics
  // before comparison. The pinned case is live in this repo's TASK-006 —
  // `claudemd-integration-block` against `### CLAUDE.md Integration Block` —
  // which a hyphen-preserving slugify breaks ("claude-md-..." vs "claudemd-...").
  // This file exists because a matching rule was silently dropped once
  // (req-slug, 2026-08-16); this is the second such rule made addressable.
  const doc = [
    '# Contract', '', '## Interfaces', '',
    '### CLAUDE.md Integration Block', '', 'Three lines.', '',
    '### UX.md Data Model', '', 'Structure.', '',
  ].join('\n');
  const load = loaderFor({ 'CONTRACT.md': doc });
  const r = md.resolveRef('CONTRACT#interfaces/claudemd-integration-block', load);
  assert.ok(r.ok, 'claudemd-integration-block must match CLAUDE.md Integration Block: ' + (r.reason || ''));
  assert.ok(r.section.includes('Three lines.'));
  const r2 = md.resolveRef('CONTRACT#interfaces/ux.md-data-model', load);
  assert.ok(r2.ok, 'ux.md-data-model must match UX.md Data Model: ' + (r2.reason || ''));
  const r3 = md.resolveRef('CONTRACT#interfaces/claude-md-integration-block', load);
  assert.ok(r3.ok, 'the hyphen-variant reference must also compact to a match');
});

check('the UX label prefix pattern escapes its whitespace class', () => {
  // A source-level assertion, deliberately, and the reason is worth stating:
  // findHeading builds the prefix test from a template literal, where a
  // single-backslash \s collapses to the plain character `s`, compiling
  // /^Screen:s*/ instead of /^Screen:\s*/. Both patterns accept exactly the
  // same inputs today, because the `*` quantifier permits zero occurrences —
  // so there is NO behavioural difference to assert, and a fixture claiming
  // otherwise would pass with the fix reverted, which proves nothing
  // (the fixture-discrimination rule this suite is built on).
  //
  // It is still a real defect: the pattern does not say what it means, and it
  // becomes wrong the moment anyone tightens `*` to `+` or extends the class.
  // Pinning the source is the only check that can actually fail (TASK-104).
  const src = require('fs').readFileSync('.forge/scripts/lib/markdown.js', 'utf8');
  const line = src.split('\n').find(l => l.includes('${prefix}:'));
  assert.ok(line, 'the prefix test disappeared from findHeading');
  assert.ok(
    line.includes('\\\\s*'),
    'the whitespace class must be escaped as \\\\s* inside the template literal; found: ' + line.trim()
  );
});

check('UX label prefixes are stripped before matching', () => {
  const doc = [
    '# UX Spec', '', '## Flows', '', '### Flow: Sign In', '',
    '#### Screen: Password Entry', '', 'Fields.', '',
  ].join('\n');
  const ux = loaderFor({ 'UX.md': doc });
  assert.ok(md.resolveRef('UX#flows/sign-in', ux).ok);
  const screen = md.resolveRef('UX#flows/sign-in/password-entry', ux);
  assert.ok(screen.ok, screen.reason);
  assert.ok(screen.section.includes('Fields.'));
});

check('unresolved references report the file and the failing segment', () => {
  const r = md.resolveRef('SPEC#requirements/req-nope', load, { displayBase: '.forge/' });
  assert.ok(!r.ok);
  assert.ok(r.reason.includes('req-nope'), r.reason);
  assert.ok(r.reason.includes('.forge/SPEC.md'), r.reason);
  const missing = md.resolveRef('NOPE#anything', load);
  assert.ok(!missing.ok);
  const malformed = md.resolveRef('SPEC-no-hash', load);
  assert.ok(!malformed.ok);
});

// --- the live documents ---

check('every requirement in .forge/SPEC.md is addressable by its slug', () => {
  const fs = require('fs');
  if (!fs.existsSync('.forge/SPEC.md')) { console.log('    (no SPEC.md — skipped)'); return; }
  const realLoad = md.createLoader('.forge');
  const spec = realLoad('SPEC.md');
  const reqs = md.resolveSegments(spec, ['requirements'], 'SPEC#requirements');
  assert.ok(reqs.ok, 'SPEC.md has no Requirements section');
  const slugs = spec.headings
    .filter(h => h.level === 3 && h.index > reqs.start && h.index < reqs.end)
    .map(h => /^\[([^\]]+)\]/.exec(h.text))
    .filter(Boolean)
    .map(m => m[1]);
  assert.ok(slugs.length > 0, 'SPEC.md Requirements has no bracketed headings');
  for (const slug of slugs) {
    const r = md.resolveRef('SPEC#requirements/' + slug, realLoad, { displayBase: '.forge/' });
    assert.ok(r.ok, r.reason);
  }
});

if (failures) { console.log(''); console.log(failures + ' markdown.js check(s) failed.'); process.exit(1); }
NODE

echo ""
echo "All markdown.js checks passed."
