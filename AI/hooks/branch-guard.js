/**
 * Hook: Block code edits made directly on the default branch (git.md).
 *
 * git.md requires all work to start on a feature branch. Docs/config edits
 * are still allowed on main/master since they are often small housekeeping
 * changes; only edits to recognized code file extensions are blocked.
 *
 * The branch is resolved from the edited file's own repository, not the
 * session cwd: a session parked in the canonical checkout must still be able
 * to edit files inside a linked worktree that sits on a feature branch.
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
 * Walks up from a file to the nearest directory containing a `.git` entry
 * (a directory for a normal checkout, a file for a linked worktree), or null
 * when the file is not inside any repository.
 *
 * @param {string} absoluteFilePath
 * @returns {string|null}
 */
function repositoryRootFor(absoluteFilePath) {
  let directory = path.dirname(absoluteFilePath);
  while (true) {
    if (fs.existsSync(path.join(directory, ".git"))) {
      return directory;
    }
    const parent = path.dirname(directory);
    if (parent === directory) {
      return null;
    }
    directory = parent;
  }
}

/**
 * Resolve the Git metadata directory for a checkout or linked worktree.
 *
 * @param {string} repositoryRoot
 * @returns {string}
 */
function gitMetadataPath(repositoryRoot) {
  const dotGitPath = path.join(repositoryRoot, ".git");
  if (fs.statSync(dotGitPath).isDirectory()) {
    return dotGitPath;
  }

  const gitDirectoryFile = fs.readFileSync(dotGitPath, "utf8").trim();
  const gitDirectory = gitDirectoryFile.match(/^gitdir:\s+(.+)$/)?.[1];
  return path.resolve(repositoryRoot, gitDirectory ?? ".git");
}

/**
 * Reads the branch ref that a file's own repository HEAD points at, or null
 * when it cannot be determined (no repo, detached HEAD, unreadable file).
 *
 * @param {string} absoluteFilePath
 * @returns {string|null}
 */
function branchRefForFile(absoluteFilePath) {
  try {
    const repositoryRoot = repositoryRootFor(absoluteFilePath);
    if (!repositoryRoot) {
      return null;
    }
    const head = fs
      .readFileSync(path.join(gitMetadataPath(repositoryRoot), "HEAD"), "utf8")
      .trim();
    const match = head.match(/^ref:\s+(refs\/heads\/.+)$/);
    return match ? match[1] : null;
  } catch {
    return null;
  }
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
  const cwd = payload.cwd ?? ".";
  const blockedEntries = filePaths
    .filter(isCodeFile)
    .map((filePath) => ({
      filePath,
      branchRef: branchRefForFile(path.resolve(cwd, filePath)),
    }))
    .filter(
      (entry) => entry.branchRef && DEFAULT_BRANCH_REFS.includes(entry.branchRef),
    );

  if (blockedEntries.length === 0) {
    return doNothing();
  }

  return block("Start work in a feature branch, not on the default branch", [
    `Currently on: ${blockedEntries[0].branchRef.replace("refs/heads/", "")}`,
    `Code files: ${blockedEntries.map((entry) => entry.filePath).join(", ")}`,
    "Run: git checkout -b <type>/<short-desc>",
  ]);
}

module.exports = { evaluate };
