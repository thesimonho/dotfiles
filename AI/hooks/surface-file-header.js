#!/usr/bin/env node
/**
 * Hook: Re-surface a file's own working-instructions when the agent touches it.
 *
 * A file can declare directives for how to work with it in optional `agent:`
 * frontmatter:
 *
 *   ---
 *   agent:
 *     instruction: Remove items from this list as they are completed.
 *   ---
 *
 * Those directives decay: the agent reads the file early, then finishes the task
 * many turns later with the instruction buried far up-context. On every Read/Edit
 * this hook re-emits the `agent.instruction` as fresh context, so the file's
 * contract sits at the decision point. It stays silent for the (vast majority of)
 * files that carry no such block, so it adds no noise.
 */

const fs = require("node:fs");
const path = require("node:path");
const { addContext, doNothing } = require("../lib/hooks/policy-result");
const { parseAgentFrontmatter } = require("../lib/hooks/frontmatter");

// Files larger than this are skipped unread — instruction frontmatter lives in
// small hand-maintained files (roadmaps, READMEs, codemaps), not large ones.
const MAX_BYTES = 256 * 1024;

// Cap the surfaced text so a huge instruction can't flood context on every touch.
const MAX_SURFACED_CHARS = 1500;

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

function evaluate(payload) {
  const target = targetPathFrom(payload.tool_input ?? {});
  if (!target) {
    return doNothing();
  }

  const cwd = payload.cwd ?? process.cwd();
  const absolute = path.resolve(cwd, target);
  const content = readSmallFile(absolute);
  if (content === null) {
    return doNothing();
  }

  const { instruction } = parseAgentFrontmatter(content);
  if (!instruction) {
    return doNothing();
  }

  const relative = path.relative(cwd, absolute) || target;
  const surfaced =
    instruction.length > MAX_SURFACED_CHARS
      ? `${instruction.slice(0, MAX_SURFACED_CHARS)}…`
      : instruction;

  return addContext(
    `Working-instruction declared in ${relative} — follow it before you finish:\n${surfaced}`,
  );
}

module.exports = { evaluate };
