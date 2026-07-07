#!/usr/bin/env node
/**
 * Unit test for memory-redirect.js.
 *
 * Runs the hook against sample Edit/Write payloads and asserts the surfaced
 * additionalContext ("" when the hook stays silent). Run: node AI/hooks/memory-redirect.test.js
 */

const assert = require("node:assert");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "memory-redirect.js");

/**
 * Run the hook for a file path and return the surfaced additionalContext
 * ("" when the hook stays silent).
 *
 * @param {string} filePath
 * @returns {string}
 */
function surfacedFor(filePath) {
  const stdout = execFileSync("node", [HOOK], {
    input: JSON.stringify({ tool_input: { file_path: filePath } }),
    encoding: "utf8",
  });
  if (!stdout.trim()) {
    return "";
  }
  return JSON.parse(stdout).hookSpecificOutput.additionalContext;
}

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

test("fires for a memory markdown path", () => {
  const surfaced = surfacedFor("/home/x/.claude/projects/y/memory/foo.md");
  assert.match(surfaced, /ENFORCEABLE/);
});

test("stays silent for a non-memory path", () => {
  assert.strictEqual(surfacedFor("src/app.ts"), "");
});

test("stays silent for a memory path that isn't markdown", () => {
  assert.strictEqual(surfacedFor("/home/x/.claude/projects/y/memory/foo.json"), "");
});

test("stays silent for a markdown path outside memory", () => {
  assert.strictEqual(surfacedFor("docs/README.md"), "");
});

test("stays silent when no file_path is given", () => {
  assert.strictEqual(surfacedFor(""), "");
});

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n5 passing");
