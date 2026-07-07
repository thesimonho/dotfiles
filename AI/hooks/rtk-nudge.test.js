#!/usr/bin/env node
/**
 * Unit test for rtk-nudge.js.
 *
 * Runs the hook against sample Bash payloads and asserts the surfaced
 * additionalContext ("" when the hook stays silent). Run: node AI/hooks/rtk-nudge.test.js
 */

const assert = require("node:assert");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "rtk-nudge.js");

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

test("stays silent when rtk is already used", () => {
  assert.strictEqual(surfacedFor("rtk git status"), "");
});

test("stays silent for a command outside the curated set", () => {
  assert.strictEqual(surfacedFor("curl https://example.com"), "");
});

test("fires for a bare curated command", () => {
  const surfaced = surfacedFor("git status");
  assert.match(surfaced, /rtk/);
  assert.match(surfaced, /git/);
});

test("fires for a curated command chained with &&", () => {
  const surfaced = surfacedFor("git add . && git commit -m 'msg' && git push");
  assert.match(surfaced, /rtk git/);
});

test("handles a leading sudo prefix", () => {
  const surfaced = surfacedFor("sudo docker ps");
  assert.match(surfaced, /rtk docker/);
});

test("handles a leading env-var assignment", () => {
  const surfaced = surfacedFor("FOO=bar npm run build");
  assert.match(surfaced, /rtk npm/);
});

test("stays silent when rtk appears mid-command as a real word", () => {
  assert.strictEqual(surfacedFor("git log | rtk grep foo"), "");
});

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n7 passing");
