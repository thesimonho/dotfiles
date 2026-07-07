#!/usr/bin/env node
/**
 * Unit test for delete-branch-nudge.js.
 *
 * Runs the hook against PostToolUse Bash payloads and asserts what it
 * surfaces on stdout ("" when silent, additionalContext text when firing).
 * Run: node AI/hooks/delete-branch-nudge.test.js
 */

const assert = require("node:assert");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "delete-branch-nudge.js");

/**
 * Runs the hook for a completed Bash command and returns the surfaced
 * additionalContext ("" when the hook stays silent).
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

test("nudges after a fast-forward git merge", () => {
  const surfaced = surfacedFor("git merge --ff feat/widget");
  assert.match(surfaced, /delete the local branch/);
});

test("nudges after a gh pr merge", () => {
  const surfaced = surfacedFor("gh pr merge 42 --squash");
  assert.match(surfaced, /delete the local branch/);
});

test("stays silent for a non-ff merge", () => {
  assert.strictEqual(surfacedFor("git merge feat/widget"), "");
});

test("stays silent for unrelated commands", () => {
  assert.strictEqual(surfacedFor("git status"), "");
});

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n4 passing");
