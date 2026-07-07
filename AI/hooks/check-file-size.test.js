#!/usr/bin/env node
/**
 * Unit test for check-file-size.js.
 *
 * Writes temp fixture files (one over the 800-line cap, one small), runs the
 * hook against payloads pointing at them, and asserts the surfaced
 * additionalContext ("" when the hook stays silent).
 * Run: node AI/hooks/check-file-size.test.js
 */

const assert = require("node:assert");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "check-file-size.js");
const workdir = fs.mkdtempSync(path.join(os.tmpdir(), "file-size-hook-"));

/**
 * Write a fixture file with the given number of lines and return its name.
 *
 * @param {string} name
 * @param {number} lineCount
 * @returns {string}
 */
function fixtureWithLines(name, lineCount) {
  const filePath = path.join(workdir, name);
  const lines = Array.from({ length: lineCount }, (_, index) => `line ${index}`);
  fs.writeFileSync(filePath, lines.join("\n"));
  return name;
}

/**
 * Run the hook for a touched file and return the surfaced additionalContext
 * ("" when the hook stays silent).
 *
 * @param {string} fileName
 * @returns {string}
 */
function surfacedFor(fileName) {
  const stdout = execFileSync("node", [HOOK], {
    input: JSON.stringify({ cwd: workdir, tool_input: { file_path: fileName } }),
    encoding: "utf8",
  });
  if (!stdout.trim()) {
    return "";
  }
  return JSON.parse(stdout).hookSpecificOutput.additionalContext;
}

const bigFile = fixtureWithLines("big.js", 900);
const smallFile = fixtureWithLines("small.js", 20);
const bigNonCodeFile = fixtureWithLines("big.json", 900);

let failures = 0;

/**
 * @param {string} name
 * @param {() => void} fn
 */
function test(name, fn) {
  try {
    fn();
    console.log(`  ok  ${name}`);
  } catch (error) {
    failures += 1;
    console.error(`FAIL  ${name}: ${error.message}`);
  }
}

test("fires for a code file over 800 lines", () => {
  const surfaced = surfacedFor(bigFile);
  assert.match(surfaced, /800/);
  assert.match(surfaced, /big\.js/);
});

test("stays silent for a small code file", () => {
  assert.strictEqual(surfacedFor(smallFile), "");
});

test("stays silent for a non-code file over 800 lines", () => {
  assert.strictEqual(surfacedFor(bigNonCodeFile), "");
});

test("stays silent for a missing/unreadable file", () => {
  assert.strictEqual(surfacedFor("does-not-exist.js"), "");
});

fs.rmSync(workdir, { recursive: true, force: true });

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n4 passing");
