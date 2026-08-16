#!/usr/bin/env node
// prose.js — grep a markdown file's prose, ignoring fenced code blocks.
//
// Why this exists: gates assert that a command file *instructs* something, but
// several command files now carry large fenced payloads — `/forge-init` embeds
// four scripts verbatim and is 88% fenced by line count. A plain
// `grep -q "Observations" .claude/commands/forge-init.md` matches a comment
// inside the embedded wp.js source and reports the deliverable present when it
// was never built (TASK-031 passed this way while /forge-init created no
// STATUS.md stub at all). A gate that a headless loop can satisfy without doing
// the work is worse than no gate: it marks the task done and moves on.
//
// Usage: node .forge/scripts/prose.js <file> <pattern>...
// Exits 0 only when every pattern (case-insensitive) matches outside fences.

'use strict';

const fs = require('fs');

const [file, ...patterns] = process.argv.slice(2);
if (!file || patterns.length === 0) {
  console.error('usage: node .forge/scripts/prose.js <file> <pattern>...');
  process.exit(1);
}
if (!fs.existsSync(file)) {
  console.error(`prose.js: ${file} not found.`);
  process.exit(1);
}

const prose = [];
let inFence = false;
for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
  if (/^\s*```/.test(line)) { inFence = !inFence; continue; }
  if (!inFence) prose.push(line);
}
const text = prose.join('\n');

const missing = patterns.filter(p => !new RegExp(p, 'i').test(text));
if (missing.length) {
  console.error(`prose.js: ${file} prose does not match: ${missing.join(', ')}`);
  process.exit(1);
}
