#!/usr/bin/env node
// check-ux-spec.js — validate one screen spec in .forge/UX.md by screen name
// Usage: node .forge/scripts/check-ux-spec.js "Screen Name"
// Exit 0 = valid, Exit 1 = invalid (errors printed to stderr)

const fs = require('fs');
const path = require('path');
const { parseHeadings, normalizeSlug, findHeading, sectionRange, findRoot, splitTableRow } = require('./lib/markdown');

const screenName = process.argv[2];
if (!screenName) {
  console.error('Usage: node .forge/scripts/check-ux-spec.js "Screen Name"');
  process.exit(1);
}

// Nearest ancestor of the working directory holding .forge/ (TASK-072).
const uxPath = path.join(findRoot(), '.forge', 'UX.md');
if (!fs.existsSync(uxPath)) {
  console.error('Error: .forge/UX.md not found');
  process.exit(1);
}

const content = fs.readFileSync(uxPath, 'utf8').replace(/\r\n/g, '\n');

// Find the screen's "#### Screen: <name>" heading and extract through the next
// heading at the same level or higher. Scanning goes through lib/markdown.js so
// that `#`-prefixed lines inside ``` fences are not mistaken for headings — a
// quoted spec skeleton inside a screen used to truncate the section early.
const headings = parseHeadings(content);
const screenHeading = findHeading(headings, normalizeSlug(screenName), { level: 4, prefix: 'Screen' });
if (!screenHeading) {
  console.error(`Error: Screen "${screenName}" not found in UX.md`);
  process.exit(1);
}

// Body excludes the heading line itself, matching the previous implementation.
const { start, end } = sectionRange(headings, screenHeading, content.length);
const nl = content.indexOf('\n', start);
const bodyStart = nl === -1 || nl > end ? end : nl;
const screenContent = content.slice(bodyStart, end);

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

// Sub-sections are located the same fence-aware way as the screen itself, so a
// quoted "##### States" inside a fence is not mistaken for the real one.
const subHeadings = parseHeadings(screenContent);

// Check States table exists and has at least one data row
const statesHeading = findHeading(subHeadings, normalizeSlug('States'), { level: 5 });
if (!statesHeading) {
  errors.push('Missing section: ##### States');
} else {
  const statesRange = sectionRange(subHeadings, statesHeading, screenContent.length);
  const statesBody = screenContent.slice(statesRange.start, statesRange.end);
  const dataRows = statesBody.split('\n').filter(line => {
    const trimmed = line.trim();
    return trimmed.startsWith('|') && !trimmed.includes('---') && !/^\|\s*State\s*\|/i.test(trimmed);
  });
  if (dataRows.length === 0) {
    errors.push('States table has no data rows');
  }

  // Reject vague terms in the Experience column only (3rd cell) — State/Trigger labels
  // may legitimately contain words like "slow" or "fast" without violating precision.
  // Through the shared splitter, never a bare split on the pipe character
  // (CONTRACT#data-model/markdown-table-parsing: no caller re-implements table
  // splitting). A cell may legitimately contain an escaped `\|`, and a naive
  // split counts that as a column break — shifting the vague-term check onto
  // the wrong cell, so a vague Experience value passes silently.
  const experienceCells = dataRows.map(row => {
    const cells = splitTableRow(row);
    return cells[2] !== undefined ? cells[2].trim() : '';
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
if (!findHeading(subHeadings, normalizeSlug('Edge Cases'), { level: 5 })) {
  errors.push('Missing section: ##### Edge Cases');
}

if (errors.length > 0) {
  console.error(`Screen "${screenName}" spec validation failed:\n`);
  errors.forEach(e => console.error(`  - ${e}`));
  process.exit(1);
}

console.log(`Screen "${screenName}" spec is valid.`);
process.exit(0);
