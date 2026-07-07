#!/usr/bin/env node
/**
 * Unit test for branch-guard.js.
 *
 * Writes a fake cwd with a .git/HEAD file pointing at different refs and
 * runs the hook against Edit/Write payloads to assert block vs allow.
 * Run: node AI/hooks/branch-guard.test.js
 */

const assert = require("node:assert");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "branch-guard.js");

/**
 * Creates a fake repo dir with a .git/HEAD pointing at the given ref.
 *
 * @param {string} ref
 * @returns {string}
 */
function fakeRepoOnRef(ref) {
  const repo = fs.mkdtempSync(path.join(os.tmpdir(), "branch-guard-"));
  fs.mkdirSync(path.join(repo, ".git"));
  fs.writeFileSync(path.join(repo, ".git", "HEAD"), `ref: ${ref}\n`);
  return repo;
}

/**
 * Runs the hook for an edit to filePath in cwd and returns the exit code
 * (0 when it allows).
 *
 * @param {string} cwd
 * @param {string} filePath
 * @returns {number}
 */
function exitCodeFor(cwd, filePath) {
  try {
    execFileSync("node", [HOOK], {
      input: JSON.stringify({ cwd, tool_input: { file_path: filePath } }),
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

test("blocks a code edit on main", () => {
  const repo = fakeRepoOnRef("refs/heads/main");
  assert.strictEqual(exitCodeFor(repo, "src/index.ts"), 2);
});

test("blocks a code edit on master", () => {
  const repo = fakeRepoOnRef("refs/heads/master");
  assert.strictEqual(exitCodeFor(repo, "main.py"), 2);
});

test("allows a code edit on a feature branch", () => {
  const repo = fakeRepoOnRef("refs/heads/feat/x");
  assert.strictEqual(exitCodeFor(repo, "src/index.ts"), 0);
});

test("allows a doc edit on main", () => {
  const repo = fakeRepoOnRef("refs/heads/main");
  assert.strictEqual(exitCodeFor(repo, "README.md"), 0);
});

test("allows a config edit on main", () => {
  const repo = fakeRepoOnRef("refs/heads/main");
  assert.strictEqual(exitCodeFor(repo, "config.json"), 0);
});

test("allows when .git/HEAD is unreadable", () => {
  const repo = fs.mkdtempSync(path.join(os.tmpdir(), "branch-guard-norepo-"));
  assert.strictEqual(exitCodeFor(repo, "src/index.ts"), 0);
});

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n6 passing");
