#!/usr/bin/env node
/**
 * Unit test for block-plan-references.js.
 *
 * Runs the hook as a child process against sample tool payloads and asserts the
 * exit code (0 = allow, 2 = block). Run: node AI/hooks/docs/block-plan-references.test.js
 */

const assert = require("node:assert");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "block-plan-references.js");

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
    name: "blocks a plan reference added to code (Claude Edit)",
    payload: {
      tool_input: {
        file_path: "src/index.js",
        new_string: "// See docs/plans/20260703-1500-widget-jsx-rewrite.html for context",
      },
    },
    expect: 2,
  },
  {
    name: "blocks a bare date-stamped plan filename in a doc (Claude Write)",
    payload: {
      tool_input: {
        file_path: "modules/watch/README.md",
        content: "Architecture: 20260628-1715-watch-port.html",
      },
    },
    expect: 2,
  },
  {
    name: "blocks a plan reference in a Codex apply_patch",
    payload: {
      tool_input: {
        command: "*** Update File: app/main.py\n+# see docs/plans/20260704-animated-icons.md §4",
      },
    },
    expect: 2,
  },
  {
    name: "allows clean content with no plan reference",
    payload: {
      tool_input: { file_path: "src/index.js", content: "export const answer = 42;" },
    },
    expect: 0,
  },
  {
    name: "allows prose mentioning the plans directory without a filename",
    payload: {
      tool_input: {
        file_path: "AI/hooks/README.md",
        content: "Plans live in the docs/plans directory and get archived.",
      },
    },
    expect: 0,
  },
  {
    name: "allows a plan editing/citing other plans (target under docs/plans/)",
    payload: {
      tool_input: {
        file_path: "docs/plans/20260706-reliability.html",
        content: "supersedes docs/plans/20260101-old.html",
      },
    },
    expect: 0,
  },
  {
    name: "allows an archived plan referencing plans",
    payload: {
      tool_input: {
        file_path: "docs/archive/20260101-old.md",
        content: "See docs/plans/20260101-old.html",
      },
    },
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
