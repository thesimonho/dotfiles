#!/usr/bin/env node
/**
 * Hook: Block writes to build/output directories at the project root.
 *
 * Applies to Write, Edit, and MultiEdit. Checks the file path relative to
 * cwd so that nested dirs with the same name (e.g. src/components/build/)
 * are not blocked — only top-level matches.
 */

const path = require("path");
const { block } = require("../../lib/hooks/hook-response");

const BLOCKED_DIRS = ["dist", "build", ".next", "node_modules", ".git"];

/**
 * Returns file paths from Claude and Codex tool inputs.
 *
 * @param {object} payload
 * @returns {string[]}
 */
function filePathsFrom(payload) {
  const paths = [];
  const filePath = payload.tool_input?.file_path ?? payload.tool_input?.path;
  const command = payload.tool_input?.command ?? "";

  if (filePath) {
    paths.push(filePath);
  }

  for (const match of command.matchAll(/^\*\*\* (?:Add|Update) File: (.+)$/gm)) {
    paths.push(match[1]);
  }

  return paths;
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const cwd = payload.cwd ?? process.cwd();

  for (const filePath of filePathsFrom(payload)) {
    const abs = path.resolve(cwd, filePath);
    const rel = path.relative(cwd, abs);
    const topLevelDir = rel.split(path.sep)[0];

    if (BLOCKED_DIRS.includes(topLevelDir)) {
      block(`Write to ${topLevelDir}/ is not allowed`, [
        `File: ${filePath}`,
        "Build and dependency directories must not be manually modified",
      ]);
    }
  }
});
