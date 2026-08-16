// markdown.js — shared markdown section resolution (CONTRACT#data-model/context-manifest)
//
// One implementation of "find a heading, extract through the next same-or-higher
// heading". Previously duplicated in check-ux-spec.js (ad-hoc regex, not
// fence-aware) and check-workplan.js (level-scoped, fence-aware). The
// fence-aware version is the correct one and is what lives here — CONTRACT.md
// alone holds fenced blocks containing heading-like lines, so a scanner that
// ignores fences truncates real sections early.
//
// Exports: parseHeadings, normalizeSlug, headingCompact, sectionRange,
//          findHeading, resolveSegments, resolveRef, createLoader

'use strict';

const fs = require('fs');
const path = require('path');

// --- Slug comparison ---
// Compacts to lowercase alnum-only. Deliberately looser than a strict
// hyphen-slug: it tolerates the mixed "x.md-data-model" / "xmd-data-model"
// punctuation already present in this project's hand-written Context fields.

function normalizeSlug(s) {
  return s.trim().toLowerCase().replace(/[^a-z0-9]/g, '');
}

// UX.md headings carry a "Flow: " / "Screen: " label prefix that is part of the
// document convention, not part of the name being referenced.
//
// A heading that opens with a bracketed token — `### [req-login] User Login` —
// compacts to the bracketed token alone (CONTRACT#data-model/context-manifest,
// requirement-heading matching). The trailing text is a prose name that gets
// reworded; the slug is the identifier and does not. Matching the whole heading
// would make every manifest reference break on the next copy edit. The rule is
// about the bracket, not about SPEC.md — per-feature files under `.forge/specs/`
// carry the same heading shape.
function headingCompact(text) {
  const stripped = text.trim().replace(/^(Flow|Screen):\s*/, '');
  const bracketed = /^\[([^\]]+)\]/.exec(stripped);
  return normalizeSlug(bracketed ? bracketed[1] : stripped);
}

// --- Heading scan ---
// Returns [{ level, text, index }] where index is the offset of the heading
// line's first character. Lines inside ``` fences are not headings.

function parseHeadings(fileContent) {
  const lines = fileContent.split('\n');
  const headings = [];
  let offset = 0;
  let inFence = false;
  for (const line of lines) {
    if (/^\s*```/.test(line)) {
      inFence = !inFence;
    } else if (!inFence) {
      const m = /^(#{1,6})\s+(.*)$/.exec(line);
      if (m) headings.push({ level: m[1].length, text: m[2].trim(), index: offset });
    }
    offset += line.length + 1;
  }
  return headings;
}

// --- Section extraction ---
// A section runs from its heading (inclusive) to just before the next heading
// at the same level or higher.

function sectionRange(headings, match, contentLength) {
  const next = headings.find(h => h.index > match.index && h.level <= match.level);
  return { start: match.index, end: next ? next.index : contentLength };
}

// Find the first heading whose compacted text equals `slug`, within an optional
// scope window and level constraints.
//   scopeStart/scopeEnd — offset window to search (default: whole document)
//   minLevel            — heading must be deeper than this (nested navigation)
//   level               — heading must be exactly this level
//   prefix              — heading text must start with this label (e.g. 'Screen')
function findHeading(headings, slug, opts = {}) {
  const {
    scopeStart = 0,
    scopeEnd = Infinity,
    minLevel = 0,
    level = null,
    prefix = null,
  } = opts;

  return headings.find(h => {
    if (h.index < scopeStart || h.index >= scopeEnd) return false;
    if (h.level <= minLevel) return false;
    if (level !== null && h.level !== level) return false;
    if (prefix !== null && !new RegExp(`^${prefix}:\s*`).test(h.text)) return false;
    return headingCompact(h.text) === slug;
  });
}

// --- Segment navigation ---
// Walks "a/b/c" style reference segments. Each segment is matched within the
// previous segment's section and must be strictly deeper than it, so
// `requirements/req-login` cannot match a `req-login` heading in a sibling
// section. Returns the resolved range on success.
//
// `file` is { content, headings }. `label` is used only in error text.

function resolveSegments(file, segments, label) {
  const ref = label || segments.join('/');
  if (!segments.length) return { ok: false, reason: `"${ref}" has no path segments` };

  let scopeStart = 0;
  let scopeEnd = file.content.length;
  let minLevel = 0;
  let match = null;

  for (const seg of segments) {
    match = findHeading(file.headings, normalizeSlug(seg), { scopeStart, scopeEnd, minLevel });
    if (!match) return { ok: false, reason: `"${ref}" — no heading matching "${seg}" found`, segment: seg };

    const range = sectionRange(file.headings, match, file.content.length);
    scopeStart = range.start;
    scopeEnd = range.end;
    minLevel = match.level;
  }

  return {
    ok: true,
    heading: match,
    start: scopeStart,
    end: scopeEnd,
    section: file.content.slice(scopeStart, scopeEnd),
  };
}

// --- File loading ---
// Reference prefixes name a file under the given base directory: `CONTRACT` ->
// CONTRACT.md, `specs/auth` -> specs/auth.md, `notes/TASK-029` ->
// notes/TASK-029.md. Returns a cached loader; missing files resolve to null.

function createLoader(baseDir) {
  const cache = new Map();
  return function loadFile(relPath) {
    if (cache.has(relPath)) return cache.get(relPath);
    const full = path.join(baseDir, relPath);
    let data = null;
    if (fs.existsSync(full)) {
      const content = fs.readFileSync(full, 'utf8').replace(/\r\n/g, '\n');
      data = { content, headings: parseHeadings(content) };
    }
    cache.set(relPath, data);
    return data;
  };
}

// --- Full reference resolution ---
// "PREFIX#segment/segment" -> resolved section. `loadFile` maps a relative path
// to { content, headings } or null. `displayBase` is cosmetic only: it prefixes
// the file path in error text so messages name the path a human would type.

function resolveRef(ref, loadFile, opts = {}) {
  const displayBase = opts.displayBase || '';
  const hashIdx = ref.indexOf('#');
  if (hashIdx === -1) return { ok: false, reason: `"${ref}" is malformed (missing #)` };
  const prefix = ref.slice(0, hashIdx).trim();
  const refPath = ref.slice(hashIdx + 1).trim();
  if (!prefix || !refPath) return { ok: false, reason: `"${ref}" is malformed` };

  const shown = `${displayBase}${prefix}.md`;
  const file = loadFile(`${prefix}.md`);
  if (!file) return { ok: false, reason: `"${ref}" — source file ${shown} not found` };

  const segments = refPath.split('/').map(s => s.trim()).filter(Boolean);
  const result = resolveSegments(file, segments, ref);
  if (!result.ok) return { ok: false, reason: `${result.reason} in ${shown}` };
  return Object.assign({ file: prefix }, result);
}

module.exports = {
  normalizeSlug,
  headingCompact,
  parseHeadings,
  sectionRange,
  findHeading,
  resolveSegments,
  createLoader,
  resolveRef,
};
