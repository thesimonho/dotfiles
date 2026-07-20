#!/usr/bin/env node
/**
 * Hook: Nudge toward splitting up code files that have grown too large.
 *
 * coding-style.md caps files at 800 lines ("MANY SMALL FILES > FEW LARGE
 * FILES"). A single Edit/Write rarely pushes a file over that line on its own,
 * so this checks the file's size *after* the write lands and nudges rather than
 * blocks — the agent may be mid-refactor and about to split the file anyway.
 *
 * Only applies to source-code extensions; docs, config, and data files aren't
 * subject to the file-size guidance.
 */

const fs = require("node:fs");
const path = require("node:path");
const { addContext, doNothing } = require("../lib/hooks/policy-result");

const MAX_LINES = 800;

const CODE_EXTENSIONS = new Set([
  "js",
  "jsx",
  "ts",
  "tsx",
  "mjs",
  "cjs",
  "py",
  "go",
  "rs",
  "dart",
  "java",
  "kt",
  "rb",
  "c",
  "cc",
  "cpp",
  "h",
  "hpp",
  "nix",
  "lua",
  "vue",
  "svelte",
]);

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
 * Whether a path's extension is one coding-style.md's file-size cap applies to.
 *
 * @param {string} filePath
 * @returns {boolean}
 */
function isCodeFile(filePath) {
  const extension = path.extname(filePath).slice(1).toLowerCase();
  return CODE_EXTENSIONS.has(extension);
}

/**
 * Count the lines in a file, or null when it can't be read.
 *
 * @param {string} absolutePath
 * @returns {number|null}
 */
function lineCountOf(absolutePath) {
  try {
    const content = fs.readFileSync(absolutePath, "utf8");
    return content.split("\n").length;
  } catch {
    return null;
  }
}

function evaluate(payload) {
  const target = targetPathFrom(payload.tool_input ?? {});
  if (!target || !isCodeFile(target)) {
    return doNothing();
  }

  const cwd = payload.cwd ?? process.cwd();
  const absolutePath = path.resolve(cwd, target);
  const lineCount = lineCountOf(absolutePath);
  if (lineCount === null || lineCount <= MAX_LINES) {
    return doNothing();
  }

  return addContext(
    `${target} is ${lineCount} lines — over the 800-line cap; consider extracting utilities into smaller files.`,
  );
}

module.exports = { evaluate };
