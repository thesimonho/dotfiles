#!/usr/bin/env node
/**
 * Unit test for compaction-nudge.js.
 *
 * Runs the hook against sample Bash payloads and asserts the surfaced
 * additionalContext ("" when the hook stays silent). Run: node AI/hooks/compaction-nudge.test.js
 */

const assert = require("node:assert");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "compaction-nudge.js");

/**
 * Run the hook for a Bash command and return the surfaced additionalContext
 * ("" when the hook stays silent).
 *
 * @param {string} command
 * @returns {string}
 */
function surfacedFor(command) {
  const stdout = execFileSync("node", [HOOK], {
    input: JSON.stringify({ tool_input: { command } }),
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

test("fires for gh pr create", () => {
  const surfaced = surfacedFor("gh pr create --fill");
  assert.match(surfaced, /Task boundary/);
});

test("fires for gh pr merge", () => {
  const surfaced = surfacedFor("gh pr merge --squash");
  assert.match(surfaced, /Task boundary/);
});

test("fires for git merge with --ff", () => {
  const surfaced = surfacedFor("git merge --ff-only feature/foo");
  assert.match(surfaced, /Task boundary/);
});

test("fires for git push", () => {
  const surfaced = surfacedFor("git push origin main");
  assert.match(surfaced, /Task boundary/);
});

test("stays silent for a plain git merge without --ff", () => {
  assert.strictEqual(surfacedFor("git merge feature/foo"), "");
});

test("stays silent for an unrelated command", () => {
  assert.strictEqual(surfacedFor("ls -la"), "");
});

test("stays silent when no command is given", () => {
  assert.strictEqual(surfacedFor(""), "");
});

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n7 passing");
