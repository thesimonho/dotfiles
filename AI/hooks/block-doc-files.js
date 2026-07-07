#!/usr/bin/env node
/**
 * Hook: Keep stray documentation files out of the repo.
 *
 * The intent is to stop random `.md`/`.txt` files landing in arbitrary places in
 * the repo, not to police files anywhere on disk — so enforcement is scoped to
 * paths inside the repo (relative to cwd). Scratch/temp files elsewhere (e.g.
 * /tmp) are ignored.
 *
 * Inside the repo, allowed .md files are:
 *   - README.md, CLAUDE.md, AGENTS.md (anywhere in the tree)
 *   - Any .md file under docs/
 * .txt files inside the repo are always blocked.
 */

const path = require("node:path");
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
  const cwd = payload.cwd ?? process.cwd();

  for (const filePath of filePathsFrom(payload)) {
    const relative = path.relative(cwd, path.resolve(cwd, filePath));
    // Only police files inside the repo; scratch/temp files elsewhere are not ours.
    if (relative.startsWith("..") || path.isAbsolute(relative)) {
      continue;
    }

    const isTxt = /\.txt$/.test(relative);
    const isMd = /\.md$/.test(relative);
    const isAllowed =
      isMd && (ALWAYS_ALLOWED_MD.test(relative) || DOCS_DIR_MD.test(relative));

    if (isTxt || (isMd && !isAllowed)) {
      block(filePath, ["Allowed: README.md, CLAUDE.md, AGENTS.md, or docs/*.md"]);
    }
  }
});
