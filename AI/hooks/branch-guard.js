#!/usr/bin/env node
/**
 * Hook: Block code edits made directly on the default branch (git.md).
 *
 * git.md requires all work to start on a feature branch. Docs/config edits
 * are still allowed on main/master since they are often small housekeeping
 * changes; only edits to recognized code file extensions are blocked.
 */

const fs = require("node:fs");
const path = require("node:path");
const { block } = require("../lib/hooks/hook-response");

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
    const head = fs.readFileSync(path.join(cwd, ".git", "HEAD"), "utf8").trim();
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

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const filePath = payload.tool_input?.file_path ?? "";

  if (!filePath || !isCodeFile(filePath)) {
    return;
  }

  const branchRef = currentBranchRef(payload.cwd ?? ".");

  if (branchRef && DEFAULT_BRANCH_REFS.includes(branchRef)) {
    block("Start work in a feature branch, not on the default branch (git.md)", [
      `Currently on: ${branchRef.replace("refs/heads/", "")}`,
      "Run: git checkout -b <type>/<short-desc>",
    ]);
  }
});
