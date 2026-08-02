/**
 * Hook: Keep documentation files out of the repository root.
 *
 * The intent is to keep root-level Markdown from becoming an unstructured
 * documentation surface and to keep untyped text files out of the repository.
 * Documentation next to the code it explains is valid, and durable repository
 * documentation belongs under docs/. Scratch/temp files outside the repo (for
 * example, /tmp) are ignored.
 */

const path = require("node:path");
const { block, doNothing } = require("../lib/hooks/policy-result");

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
    const isRepositoryRootMarkdown =
      path.dirname(relative) === "." && relative.endsWith(".md");
    const isTextFile = relative.endsWith(".txt");

    if (isRepositoryRootMarkdown) {
      return block(filePath, [
        "Do not write Markdown files in the repository root. Put durable documentation under docs/ instead.",
      ]);
    }

    if (isTextFile) {
      return block(filePath, [
        "Do not write .txt files in this repository. Use an appropriate typed format instead.",
      ]);
    }
  }

  return doNothing();
}

module.exports = { evaluate };
