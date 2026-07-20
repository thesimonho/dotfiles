/**
 * Hook: Block code edits made directly on the default branch (git.md).
 *
 * git.md requires all work to start on a feature branch. Docs/config edits
 * are still allowed on main/master since they are often small housekeeping
 * changes; only edits to recognized code file extensions are blocked.
 */

const fs = require("node:fs");
const path = require("node:path");
const { block, doNothing } = require("../lib/hooks/policy-result");

const DEFAULT_BRANCH_REFS = ["refs/heads/main", "refs/heads/master"];
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
  "sh",
  "lua",
  "vue",
  "svelte",
]);

/**
 * Reads the branch ref that .git/HEAD points at, or null when it cannot be
 * determined (missing repo, detached HEAD, unreadable file).
 *
 * @param {string} cwd
 * @returns {string|null}
 */
function currentBranchRef(cwd) {
  try {
    const head = fs.readFileSync(path.join(gitMetadataPath(cwd), "HEAD"), "utf8").trim();
    const match = head.match(/^ref:\s+(refs\/heads\/.+)$/);
    return match ? match[1] : null;
  } catch {
    return null;
  }
}

/**
 * Resolve the Git metadata directory for a checkout or linked worktree.
 *
 * @param {string} cwd
 * @returns {string}
 */
function gitMetadataPath(cwd) {
  const dotGitPath = path.join(cwd, ".git");
  if (fs.statSync(dotGitPath).isDirectory()) {
    return dotGitPath;
  }

  const gitDirectoryFile = fs.readFileSync(dotGitPath, "utf8").trim();
  const gitDirectory = gitDirectoryFile.match(/^gitdir:\s+(.+)$/)?.[1];
  return path.resolve(cwd, gitDirectory ?? ".git");
}

/**
 * Returns whether the file path has one of the recognized code extensions.
 *
 * @param {string} filePath
 * @returns {boolean}
 */
function isCodeFile(filePath) {
  const extension = path.extname(filePath).slice(1).toLowerCase();
  return CODE_EXTENSIONS.has(extension);
}

function evaluate(payload) {
  const filePaths = payload.tool_input?.file_paths ?? [payload.tool_input?.file_path].filter(Boolean);
  const codeFilePaths = filePaths.filter(isCodeFile);

  if (codeFilePaths.length === 0) {
    return doNothing();
  }

  const branchRef = currentBranchRef(payload.cwd ?? ".");

  if (branchRef && DEFAULT_BRANCH_REFS.includes(branchRef)) {
    return block("Start work in a feature branch, not on the default branch", [
      `Currently on: ${branchRef.replace("refs/heads/", "")}`,
      `Code files: ${codeFilePaths.join(", ")}`,
      "Run: git checkout -b <type>/<short-desc>",
    ]);
  }

  return doNothing();
}

module.exports = { evaluate };
