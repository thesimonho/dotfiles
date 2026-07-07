#!/usr/bin/env node
/**
 * Unit test for check-plan-filename.js.
 *
 * Runs the hook as a child process against sample Write/Edit payloads and
 * asserts the exit code (0 = allow, 2 = block).
 * Run: node AI/hooks/check-plan-filename.test.js
 */

const assert = require("node:assert");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "check-plan-filename.js");
const PLANS_DIR = ["docs", "plans"].join("/");

/**
 * Run the hook with a payload and return its exit code (0 when it allows).
 *
 * @param {object} payload
 * @returns {number}
 */
function exitCodeFor(payload) {
  try {
    execFileSync("node", [HOOK], {
      input: JSON.stringify(payload),
      stdio: ["pipe", "ignore", "ignore"],
    });
    return 0;
  } catch (error) {
    return error.status;
  }
}

const cases = [
  {
    name: "blocks an un-stamped plan filename",
    payload: { tool_input: { file_path: `${PLANS_DIR}/notes.md` } },
    expect: 2,
  },
  {
    name: "allows a correctly date-stamped plan filename",
    payload: { tool_input: { file_path: `${PLANS_DIR}/${"20260707-thing.html"}` } },
    expect: 0,
  },
  {
    name: "allows a date+time-stamped plan filename",
    payload: { tool_input: { file_path: `${PLANS_DIR}/${"20260707-1530-thing.md"}` } },
    expect: 0,
  },
  {
    name: "stays silent for a non-plan path",
    payload: { tool_input: { file_path: "src/app.ts" } },
    expect: 0,
  },
  {
    name: "blocks an un-stamped plan filename via Codex apply_patch",
    payload: {
      tool_input: {
        command: `*** Add File: ${PLANS_DIR}/notes.md\n+hello`,
      },
    },
    expect: 2,
  },
];

let failures = 0;
for (const testCase of cases) {
  try {
    assert.strictEqual(exitCodeFor(testCase.payload), testCase.expect);
    console.log(`  ok  ${testCase.name}`);
  } catch {
    failures += 1;
    console.error(`FAIL  ${testCase.name} (expected exit ${testCase.expect})`);
  }
}

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log(`\n${cases.length} passing`);
