#!/usr/bin/env node
/**
 * Hook: Re-surface a file's own working-instructions when the agent touches it.
 *
 * A file can carry directives for how to work with it inside an
 * `<INSTRUCTION>...</INSTRUCTION>` block (e.g. a roadmap: "clear items as they
 * complete"). Those directives decay: the agent reads the file early, then
 * finishes the task many turns later with the instruction buried far up-context.
 *
 * On every Read/Edit this hook re-emits any `<INSTRUCTION>` blocks as fresh
 * context, so the file's contract sits at the decision point rather than in a
 * stale tool result. It stays silent for the (vast majority of) files that carry
 * no such block, so it adds no noise.
 */

const fs = require("node:fs");
const path = require("node:path");
const { addContext } = require("../lib/hooks/hook-response");

// Files larger than this are skipped unread — instruction blocks live in small
// hand-maintained files (roadmaps, READMEs), not large generated or binary ones.
const MAX_BYTES = 256 * 1024;

// Cap the surfaced text so a huge block can't flood context every time the file
// is touched; the agent can re-read the file for the full detail.
const MAX_SURFACED_CHARS = 1500;

const INSTRUCTION_BLOCK = /<INSTRUCTION>([\s\S]*?)<\/INSTRUCTION>/gi;

/**
 * The file path a Read/Edit targeted, across Claude and Codex tool shapes.
 *
 * @param {object} toolInput
 * @returns {string}
 */
function targetPathFrom(toolInput) {
  return toolInput.file_path ?? toolInput.path ?? "";
}

/**
 * Read a file only when it exists and is small enough to be a hand-authored doc.
 * Returns null when the file is missing, too large, or unreadable.
 *
 * @param {string} absolutePath
 * @returns {string|null}
 */
function readSmallFile(absolutePath) {
  try {
    const stat = fs.statSync(absolutePath);
    if (!stat.isFile() || stat.size > MAX_BYTES) {
      return null;
    }
    return fs.readFileSync(absolutePath, "utf8");
  } catch {
    return null;
  }
}

/**
 * Extract and join the text of every `<INSTRUCTION>` block in a document.
 *
 * @param {string} content
 * @returns {string}
 */
function instructionsFrom(content) {
  const blocks = [];
  for (const match of content.matchAll(INSTRUCTION_BLOCK)) {
    const text = match[1].trim();
    if (text) {
      blocks.push(text);
    }
  }
  return blocks.join("\n\n");
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const target = targetPathFrom(payload.tool_input ?? {});
  if (!target) {
    return;
  }

  const cwd = payload.cwd ?? process.cwd();
  const absolute = path.resolve(cwd, target);
  const content = readSmallFile(absolute);
  if (content === null) {
    return;
  }

  const instructions = instructionsFrom(content);
  if (!instructions) {
    return;
  }

  const relative = path.relative(cwd, absolute) || target;
  const surfaced =
    instructions.length > MAX_SURFACED_CHARS
      ? `${instructions.slice(0, MAX_SURFACED_CHARS)}\n…(truncated — re-read the file for the rest)`
      : instructions;

  addContext(
    "PostToolUse",
    `Working-instructions declared in ${relative} — follow them before you finish:\n${surfaced}`,
  );
});
