#!/usr/bin/env node
/**
 * Hook: Block committing leftover debug logging (workflow.md).
 *
 * workflow.md says logging is fine while debugging, but must be removed
 * before committing. This inspects the staged diff for `git commit` calls
 * and blocks when an added line in a non-test file contains an obvious
 * debug statement. Patterns are deliberately narrow (console.log/debug,
 * `debugger;`, dbg!(), binding.pry, byebug) to avoid false positives on
 * legitimate output calls like print()/fmt.Println, which are too common
 * in real code to flag safely.
 */

const { execFileSync } = require("node:child_process");
const { block } = require("../lib/hooks/hook-response");

const DEBUG_PATTERNS = [
  /debugger;/,
  /console\.log\(/,
  /console\.debug\(/,
  /dbg!\(/,
  /binding\.pry/,
  /byebug/,
];
const TEST_FILE_PATH = /test|spec|__tests__/i;

/**
 * Parses `git diff --cached --unified=0` output into per-file added lines.
 * Only lines starting with `+` (not `+++` file headers) are considered
 * additions; unified=0 keeps line numbers accurate without context noise.
 *
 * @param {string} diff
 * @returns {{file: string, lineNumber: number, text: string}[]}
 */
function addedLinesFrom(diff) {
  const additions = [];
  let currentFile = null;
  let nextLineNumber = null;

  for (const line of diff.split("\n")) {
    const fileHeaderMatch = line.match(/^\+\+\+ b\/(.+)$/);
    if (fileHeaderMatch) {
      currentFile = fileHeaderMatch[1];
      continue;
    }

    const hunkHeaderMatch = line.match(/^@@ -\d+(?:,\d+)? \+(\d+)/);
    if (hunkHeaderMatch) {
      nextLineNumber = Number(hunkHeaderMatch[1]);
      continue;
    }

    if (line.startsWith("+") && !line.startsWith("+++")) {
      additions.push({ file: currentFile, lineNumber: nextLineNumber, text: line.slice(1) });
      nextLineNumber += 1;
    }
  }

  return additions;
}

/**
 * Reads the currently staged diff. Returns "" when there is nothing staged
 * or the cwd is not a git repo, so callers can fail open silently.
 *
 * @param {string} cwd
 * @returns {string}
 */
function stagedDiff(cwd) {
  try {
    return execFileSync("git", ["diff", "--cached", "--unified=0"], { cwd, encoding: "utf8" });
  } catch {
    return "";
  }
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const command = payload.tool_input?.command ?? "";

  if (!/git\s+commit/.test(command)) {
    return;
  }

  const diff = stagedDiff(payload.cwd);
  if (!diff) {
    return;
  }

  const offenders = addedLinesFrom(diff)
    .filter((addition) => addition.file && !TEST_FILE_PATH.test(addition.file))
    .filter((addition) => DEBUG_PATTERNS.some((pattern) => pattern.test(addition.text)));

  if (offenders.length > 0) {
    block(
      "Remove debug logging before committing (workflow.md)",
      offenders.map(
        (addition) => `${addition.file}:${addition.lineNumber}: ${addition.text.trim()}`,
      ),
    );
  }
});
