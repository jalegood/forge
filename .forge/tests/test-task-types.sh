#!/usr/bin/env bash
set -e

# Drift test over the task-type enum's five restatements (TASK-080, closes
# OBS-012).
#
# `VALID_TYPES` in lib/workplan.js is the executable source of truth — the only
# copy that can reject a bad value. Four prose copies exist beside it, each
# earning its place (a copyable template, documented script output, two tables
# carrying per-type gate guidance), so the duplication is deliberate and the
# *absence of a check on it* was the defect: `checkpoint` silently fell out of
# forge-plan.md's table and stayed missing until TASK-036 noticed by hand.
#
# Both directions are asserted at every site. A type dropped from a table is
# invisible guidance; a type added to prose but never to the enum is a value
# every workplan write will reject — and only the second direction would have
# caught the `checkpoint` drift's mirror image. The enum is *derived* from
# lib/workplan.js rather than hardcoded here, so this test never becomes a
# sixth copy to drift.

node - <<'NODE'
const fs = require('fs');
const assert = require('assert');

const { VALID_TYPES } = require(process.cwd() + '/.forge/scripts/lib/workplan.js');
const enumSet = new Set(VALID_TYPES);
assert.ok(enumSet.size >= 5, 'VALID_TYPES suspiciously small — did the parse break?');

let failures = 0;
function checkSite(label, found) {
  const foundSet = new Set(found);
  let siteFailures = 0;
  for (const t of enumSet) {
    if (!foundSet.has(t)) { console.log(`FAIL: ${label} is missing type "${t}"`); siteFailures++; }
  }
  for (const t of foundSet) {
    if (!enumSet.has(t)) { console.log(`FAIL: ${label} names "${t}", which is not in VALID_TYPES`); siteFailures++; }
  }
  failures += siteFailures;
  if (siteFailures === 0) console.log(`  ${label}: OK (${found.length} types)`);
}

// Site 2: CONTRACT.md Task Types table — first backticked cell of each row.
{
  const s = fs.readFileSync('.forge/CONTRACT.md', 'utf8');
  const section = s.split(/^### Task Types$/m)[1].split(/^### /m)[0];
  const found = [...section.matchAll(/^\| `([a-z-]+)`/gm)].map(m => m[1]);
  checkSite('CONTRACT.md Task Types table', found);
}

// Sites 3 and 4: forge-plan.md — the fenced task-format Type line (a template
// planners copy verbatim) and the task-types table.
{
  const s = fs.readFileSync('.claude/commands/forge-plan.md', 'utf8');
  const typeLine = s.match(/^- \*\*Type:\*\* ([a-z-| ]+)$/m);
  assert.ok(typeLine, 'forge-plan.md has no fenced task-format Type line');
  checkSite('forge-plan.md fenced task format', typeLine[1].split('|').map(t => t.trim()).filter(Boolean));

  const tableRows = [...s.matchAll(/^\| `([a-z-]+)` +\|/gm)].map(m => m[1]);
  checkSite('forge-plan.md task-types table', tableRows);
}

// Site 5: forge-next.md — the wp.js output-shape block documents the literal
// Type line the script prints.
{
  const s = fs.readFileSync('.claude/commands/forge-next.md', 'utf8');
  const typeLine = s.match(/^Type: ([a-z-| ]+)$/m);
  assert.ok(typeLine, 'forge-next.md has no wp.js output-shape Type line');
  checkSite('forge-next.md wp.js output shape', typeLine[1].split('|').map(t => t.trim()).filter(Boolean));
}

if (failures) { console.log(`\n${failures} task-type drift failure(s).`); process.exit(1); }
NODE

echo ""
echo "All task-type enum sites agree with VALID_TYPES."
