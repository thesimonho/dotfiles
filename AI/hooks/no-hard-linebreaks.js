#!/usr/bin/env node
/**
 * Hook: Nudge away from hard-wrapped prose in markdown files.
 *
 * documentation.md: "do not use hard line breaks; let text wrap naturally."
 * Hard-wrapped paragraphs (each line manually broken around ~70-80 chars) are
 * hard to detect by eye once they're already in a file, and they cause noisy
 * diffs later when a single word changes and reflows the whole paragraph. This
 * checks the file after a Write/Edit/MultiEdit lands and nudges — it never
 * blocks, since the heuristic can't be certain prose was manually wrapped
 * rather than just naturally short.
 *
 * Conservative on purpose: only fires on a run of >=3 consecutive plain-prose
 * lines that all fall in the classic hard-wrap width band (55-100 chars), and
 * skips fenced code blocks and structural lines (headings, lists, quotes,
 * tables, numbered lines).
 */

const fs = require("node:fs");
const path = require("node:path");
const { addContext } = require("../lib/hooks/hook-response");

const MIN_CONSECUTIVE_LINES = 3;
const MIN_WRAP_WIDTH = 55;
const MAX_WRAP_WIDTH = 100;

// Lines that are structural, not free-flowing prose, and so don't count as
// hard-wrap evidence even when their length falls in the wrap-width band.
const STRUCTURAL_LINE = /^\s*(#|-|\*|>|\||\d+\.|```)/;
const FENCE_LINE = /^\s*```/;

/**
 * The file path a Write/Edit/MultiEdit targeted, across Claude and Codex tool
 * shapes.
 *
 * @param {object} toolInput
 * @returns {string}
 */
function targetPathFrom(toolInput) {
  const direct = toolInput.file_path ?? toolInput.path ?? "";
  if (direct) {
    return direct;
  }

  const command = toolInput.command ?? "";
  const patched = command.match(/^\*\*\* (?:Add|Update) File: (.+)$/m);
  return patched ? patched[1] : "";
}

/**
 * Whether a line counts as a "hard-wrap width" plain-prose line: non-blank,
 * not structural, and within the classic wrap-column band.
 *
 * @param {string} line
 * @returns {boolean}
 */
function isWrapWidthProseLine(line) {
  const trimmed = line.trim();
  if (!trimmed || STRUCTURAL_LINE.test(line)) {
    return false;
  }
  return trimmed.length >= MIN_WRAP_WIDTH && trimmed.length <= MAX_WRAP_WIDTH;
}

/**
 * Whether the document contains a run of consecutive hard-wrap-width prose
 * lines long enough to signal manual wrapping, ignoring fenced code blocks.
 *
 * @param {string} content
 * @returns {boolean}
 */
function hasHardWrappedParagraph(content) {
  let insideFence = false;
  let consecutiveCount = 0;

  for (const line of content.split("\n")) {
    if (FENCE_LINE.test(line)) {
      insideFence = !insideFence;
      consecutiveCount = 0;
      continue;
    }

    if (insideFence) {
      continue;
    }

    consecutiveCount = isWrapWidthProseLine(line) ? consecutiveCount + 1 : 0;
    if (consecutiveCount >= MIN_CONSECUTIVE_LINES) {
      return true;
    }
  }

  return false;
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const target = targetPathFrom(payload.tool_input ?? {});
  if (!/\.md$/.test(target)) {
    return;
  }

  const cwd = payload.cwd ?? process.cwd();
  const absolutePath = path.resolve(cwd, target);

  let content;
  try {
    content = fs.readFileSync(absolutePath, "utf8");
  } catch {
    return;
  }

  if (!hasHardWrappedParagraph(content)) {
    return;
  }

  addContext(
    "PostToolUse",
    `${target} looks hard-wrapped; documentation.md prefers letting prose wrap naturally (no hard line breaks).`,
  );
});
