#!/usr/bin/env node
// check-spec.js — validate a spec file's structural readiness
// Usage: node .forge/scripts/check-spec.js <file> [--max-unresolved N]
// Exit 0 = valid, Exit 1 = invalid (errors printed to stderr)

const fs = require('fs');
const path = require('path');
const { parseHeadings, findHeading, sectionRange, normalizeSlug } = require('./lib/markdown');

const args = process.argv.slice(2);
const fileArg = args.find(a => !a.startsWith('--'));
const maxUnresolvedFlagIdx = args.indexOf('--max-unresolved');
const maxUnresolved = maxUnresolvedFlagIdx !== -1 ? Number(args[maxUnresolvedFlagIdx + 1]) : 0;

if (!fileArg) {
  console.error('Usage: node .forge/scripts/check-spec.js <file> [--max-unresolved N]');
  process.exit(1);
}

const specPath = path.isAbsolute(fileArg) ? fileArg : path.join(process.cwd(), fileArg);
if (!fs.existsSync(specPath)) {
  console.error(`Error: ${fileArg} not found`);
  process.exit(1);
}

const content = fs.readFileSync(specPath, 'utf8').replace(/\r\n/g, '\n');
const headings = parseHeadings(content);
const errors = [];

// --- Required top-level sections (CONTRACT#data-model/spec-data-model) ---
const requiredSections = ['Overview', 'Requirements', 'Non-Goals'];
for (const name of requiredSections) {
  if (!findHeading(headings, normalizeSlug(name), { level: 2 })) {
    errors.push(`Missing section: ## ${name}`);
  }
}

// --- Requirements: at least one REQ with acceptance criteria, no placeholder/TODO text ---
const requirementsHeading = findHeading(headings, normalizeSlug('Requirements'), { level: 2 });
if (requirementsHeading) {
  const reqSectionRange = sectionRange(headings, requirementsHeading, content.length);
  const reqSection = content.slice(reqSectionRange.start, reqSectionRange.end);
  const reqHeadings = parseHeadings(reqSection).filter(h => h.level === 3);

  if (reqHeadings.length === 0) {
    errors.push('Requirements section has no requirement headings (### [req-slug] Name)');
  }

  let hasAcceptanceCriteria = false;
  for (const h of reqHeadings) {
    const bracketMatch = /^\[([^\]]+)\]/.exec(h.text);
    const label = bracketMatch ? bracketMatch[1] : h.text;

    const range = sectionRange(reqHeadings, h, reqSection.length);
    const nl = reqSection.indexOf('\n', range.start);
    const bodyStart = nl === -1 || nl > range.end ? range.end : nl;
    const body = reqSection.slice(bodyStart, range.end);
    const withoutComments = body.replace(/<!--[\s\S]*?-->/g, '').trim();

    if (!withoutComments) {
      errors.push(`Requirement [${label}] is empty or placeholder-only (no content outside HTML comments)`);
      continue;
    }

    if (/\bTODO\b/i.test(withoutComments) || /\bTBD\b/i.test(withoutComments)) {
      errors.push(`Requirement [${label}] contains placeholder text (TODO/TBD)`);
    }

    const acIdx = withoutComments.search(/acceptance criteria/i);
    if (acIdx !== -1) {
      const afterAc = withoutComments.slice(acIdx);
      const hasBullet = afterAc.split('\n').some(line => {
        const trimmed = line.trim();
        return (trimmed.startsWith('-') || trimmed.startsWith('*')) && trimmed.replace(/^[-*]\s*/, '').length > 0;
      });
      if (hasBullet) hasAcceptanceCriteria = true;
    }
  }

  if (reqHeadings.length > 0 && !hasAcceptanceCriteria) {
    errors.push('No requirement has acceptance criteria (expected an "Acceptance criteria" line followed by a bullet list in at least one requirement)');
  }
}

// --- Unresolved markers above threshold (default: zero blocking) ---
const unresolvedLines = [];
content.split('\n').forEach((line, i) => {
  if (line.includes('<!-- UNRESOLVED')) unresolvedLines.push(i + 1);
});
if (unresolvedLines.length > maxUnresolved) {
  errors.push(
    `${unresolvedLines.length} unresolved marker(s) exceed the allowed threshold of ${maxUnresolved} (lines: ${unresolvedLines.join(', ')})`
  );
}

if (errors.length > 0) {
  console.error(`Spec "${fileArg}" validation failed:\n`);
  errors.forEach(e => console.error(`  - ${e}`));
  process.exit(1);
}

console.log(`Spec "${fileArg}" is valid.`);
process.exit(0);
