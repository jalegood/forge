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
