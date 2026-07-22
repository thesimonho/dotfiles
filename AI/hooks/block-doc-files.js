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
 *   - Direct shared agent and instruction-fragment sources under AI/
 * .txt files inside the repo are always blocked.
 */

const path = require("node:path");
const { block, doNothing } = require("../lib/hooks/policy-result");

const ALWAYS_ALLOWED_MD = /(^|\/)(README|CLAUDE|AGENTS)\.md$/;
const DOCS_DIR_MD = /^docs\//;
const INSTRUCTION_SOURCE_MD =
  /^AI\/(agents\/[^/]+|instructions\/fragments\/[^/]+)\.md$/;

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

function evaluate(payload) {
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
      isMd &&
      (ALWAYS_ALLOWED_MD.test(relative) ||
        DOCS_DIR_MD.test(relative) ||
        INSTRUCTION_SOURCE_MD.test(relative));

    if (isTxt || (isMd && !isAllowed)) {
      return block(filePath, ["Allowed: README.md, CLAUDE.md, AGENTS.md, or docs/*.md"]);
    }
  }

  return doNothing();
}

module.exports = { evaluate };
