#!/usr/bin/env node
/**
 * Hook: Block unnecessary documentation file creation.
 *
 * Allowed .md files:
 *   - README.md, CLAUDE.md, AGENTS.md (anywhere in the tree)
 *   - Any .md file under ./docs/
 *
 * .txt files are always blocked.
 */

const { block } = require("../lib/hooks/hook-response");

const ALWAYS_ALLOWED_MD = /(^|\/)(README|CLAUDE|AGENTS)\.md$/;
const DOCS_DIR_MD = /^docs\//;

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
  for (const path of filePathsFrom(payload)) {
    const isTxt = /\.txt$/.test(path);
    const isMd = /\.md$/.test(path);

    const isAllowed =
      isMd && (ALWAYS_ALLOWED_MD.test(path) || DOCS_DIR_MD.test(path));

    if (isTxt || (isMd && !isAllowed)) {
      block(path, ["Allowed: README.md, CLAUDE.md, AGENTS.md, or docs/*.md"]);
    }
  }
});
