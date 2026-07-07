#!/usr/bin/env node
/**
 * Unit test for surface-file-header.js.
 *
 * Writes temp files with/without an <INSTRUCTION> block, runs the hook against
 * Read/Edit payloads pointing at them, and asserts what it surfaces on stdout.
 * Run: node AI/hooks/surface-file-header.test.js
 */

const assert = require("node:assert");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "surface-file-header.js");
const workdir = fs.mkdtempSync(path.join(os.tmpdir(), "surface-hook-"));

/**
 * Write a fixture file in the temp workdir and return its absolute path.
 *
 * @param {string} name
 * @param {string} body
 * @returns {string}
 */
function fixture(name, body) {
  const filePath = path.join(workdir, name);
  fs.writeFileSync(filePath, body);
  return filePath;
}

/**
 * Run the hook for a touched file and return the surfaced additionalContext
 * ("" when the hook stays silent).
 *
 * @param {string} filePath
 * @returns {string}
 */
function surfacedFor(filePath) {
  const stdout = execFileSync("node", [HOOK], {
    input: JSON.stringify({ cwd: workdir, tool_input: { file_path: filePath } }),
    encoding: "utf8",
  });
  if (!stdout.trim()) {
    return "";
  }
  return JSON.parse(stdout).hookSpecificOutput.additionalContext;
}

const roadmap = fixture(
  "roadmap.md",
  "# Roadmap\n\n<INSTRUCTION>\nClear items as they are completed.\n</INSTRUCTION>\n\n- [ ] widget rewrite\n",
);
const plainFile = fixture("plain.md", "# Notes\n\nJust some text, no directives.\n");
const multiBlock = fixture(
  "multi.md",
  "<INSTRUCTION>First rule.</INSTRUCTION>\ntext\n<INSTRUCTION>Second rule.</INSTRUCTION>\n",
);

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

test("surfaces a file's INSTRUCTION block", () => {
  const surfaced = surfacedFor(roadmap);
  assert.match(surfaced, /Clear items as they are completed/);
  assert.match(surfaced, /roadmap\.md/);
});

test("stays silent for a file with no INSTRUCTION block", () => {
  assert.strictEqual(surfacedFor(plainFile), "");
});

test("stays silent for a missing file", () => {
  assert.strictEqual(surfacedFor(path.join(workdir, "nope.md")), "");
});

test("surfaces every INSTRUCTION block in a file", () => {
  const surfaced = surfacedFor(multiBlock);
  assert.match(surfaced, /First rule/);
  assert.match(surfaced, /Second rule/);
});

fs.rmSync(workdir, { recursive: true, force: true });

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n4 passing");
