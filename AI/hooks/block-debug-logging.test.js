#!/usr/bin/env node
/**
 * Unit test for block-debug-logging.js.
 *
 * Sets up a real temp git repo, stages a file, and runs the hook against a
 * `git commit` payload so its `git diff --cached` has real content to read.
 * Run: node AI/hooks/block-debug-logging.test.js
 */

const assert = require("node:assert");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "block-debug-logging.js");

/**
 * Creates a fresh temp git repo and returns its path.
 *
 * @returns {string}
 */
function freshRepo() {
  const repo = fs.mkdtempSync(path.join(os.tmpdir(), "debug-log-hook-"));
  execFileSync("git", ["init", "-q"], { cwd: repo });
  execFileSync("git", ["config", "user.email", "test@example.com"], { cwd: repo });
  execFileSync("git", ["config", "user.name", "Test"], { cwd: repo });
  return repo;
}

/**
 * Writes a file, stages it, and returns the repo path unchanged.
 *
 * @param {string} repo
 * @param {string} name
 * @param {string} body
 */
function stageFile(repo, name, body) {
  fs.writeFileSync(path.join(repo, name), body);
  execFileSync("git", ["add", name], { cwd: repo });
}

/**
 * Runs the hook for a `git commit` payload in the given cwd and returns the
 * exit code (0 when it allows).
 *
 * @param {string} cwd
 * @returns {number}
 */
function exitCodeFor(cwd) {
  try {
    execFileSync("node", [HOOK], {
      input: JSON.stringify({ cwd, tool_input: { command: 'git commit -m "fix: thing"' } }),
      stdio: ["pipe", "ignore", "ignore"],
    });
    return 0;
  } catch (error) {
    return error.status;
  }
}

let failures = 0;
/** @param {string} name @param {() => void} fn */
function test(name, fn) {
  try {
    fn();
    console.log(`  ok  ${name}`);
  } catch (error) {
    failures += 1;
    console.error(`FAIL  ${name}: ${error.message}`);
  }
}

test("blocks staged debug logging in a non-test file", () => {
  const repo = freshRepo();
  stageFile(repo, "app.js", 'function run() {\n  console.log("x");\n  return 1;\n}\n');
  assert.strictEqual(exitCodeFor(repo), 2);
});

test("allows staged code with no debug logging", () => {
  const repo = freshRepo();
  stageFile(repo, "app.js", "function run() {\n  return 1;\n}\n");
  assert.strictEqual(exitCodeFor(repo), 0);
});

test("allows debug logging staged inside a test file", () => {
  const repo = freshRepo();
  stageFile(repo, "app.test.js", 'console.log("debug output during test");\n');
  assert.strictEqual(exitCodeFor(repo), 0);
});

test("ignores commands that are not git commit", () => {
  const repo = freshRepo();
  stageFile(repo, "app.js", 'console.log("x");\n');
  const exitCode = (() => {
    try {
      execFileSync("node", [HOOK], {
        input: JSON.stringify({ cwd: repo, tool_input: { command: "git status" } }),
        stdio: ["pipe", "ignore", "ignore"],
      });
      return 0;
    } catch (error) {
      return error.status;
    }
  })();
  assert.strictEqual(exitCode, 0);
});

test("exits cleanly when nothing is staged", () => {
  const repo = freshRepo();
  assert.strictEqual(exitCodeFor(repo), 0);
});

test("exits cleanly when cwd is not a git repo", () => {
  const nonRepo = fs.mkdtempSync(path.join(os.tmpdir(), "not-a-repo-"));
  assert.strictEqual(exitCodeFor(nonRepo), 0);
});

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n6 passing");
