#!/usr/bin/env node
/**
 * Unit test for check-conventional-commit.js.
 *
 * Runs the hook as a child process against sample `git commit` payloads and
 * asserts the exit code (0 = allow, 2 = block).
 * Run: node AI/hooks/check-conventional-commit.test.js
 */

const assert = require("node:assert");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "check-conventional-commit.js");

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

const longSubject = "a".repeat(71);

const cases = [
  {
    name: "allows a valid short conventional subject",
    payload: { tool_input: { command: 'git commit -m "feat: add widget support"' } },
    expect: 0,
  },
  {
    name: "allows a valid conventional subject with scope and breaking marker",
    payload: { tool_input: { command: 'git commit -m "feat(api)!: change response shape"' } },
    expect: 0,
  },
  {
    name: "blocks a non-conventional subject",
    payload: { tool_input: { command: 'git commit -m "added a widget"' } },
    expect: 2,
  },
  {
    name: "blocks a conventional subject exceeding 70 characters",
    payload: { tool_input: { command: `git commit -m "feat: ${longSubject}"` } },
    expect: 2,
  },
  {
    name: "allows a conventional subject using $'...' quoting",
    payload: { tool_input: { command: "git commit -m $'fix: handle empty input'" } },
    expect: 0,
  },
  {
    name: "allows commits without -m (editor opens)",
    payload: { tool_input: { command: "git commit" } },
    expect: 0,
  },
  {
    name: "ignores commands that are not git commit",
    payload: { tool_input: { command: "git status" } },
    expect: 0,
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
