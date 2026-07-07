#!/usr/bin/env node
/**
 * Unit test for justfile-nudge.js.
 *
 * Writes temp dirs with/without a justfile, runs the hook against Bash payloads
 * pointing at them, and asserts the surfaced additionalContext ("" when the
 * hook stays silent). Run: node AI/hooks/justfile-nudge.test.js
 */

const assert = require("node:assert");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "justfile-nudge.js");

/**
 * Create a fresh temp directory, optionally seeded with a justfile.
 *
 * @param {{withJustfile?: boolean, capitalized?: boolean}} [options]
 * @returns {string}
 */
function makeWorkdir({ withJustfile = false, capitalized = false } = {}) {
  const workdir = fs.mkdtempSync(path.join(os.tmpdir(), "justfile-hook-"));
  if (withJustfile) {
    const name = capitalized ? "Justfile" : "justfile";
    fs.writeFileSync(path.join(workdir, name), "build:\n  echo building\n");
  }
  return workdir;
}

/**
 * Run the hook for a Bash command in a given cwd and return the surfaced
 * additionalContext ("" when the hook stays silent).
 *
 * @param {string} cwd
 * @param {string} command
 * @returns {string}
 */
function surfacedFor(cwd, command) {
  const stdout = execFileSync("node", [HOOK], {
    input: JSON.stringify({ cwd, tool_input: { command } }),
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

const withJustfile = makeWorkdir({ withJustfile: true });
const withCapitalizedJustfile = makeWorkdir({ withJustfile: true, capitalized: true });
const withoutJustfile = makeWorkdir();

test("fires for npm run build when a justfile exists", () => {
  const surfaced = surfacedFor(withJustfile, "npm run build");
  assert.match(surfaced, /justfile/);
});

test("fires for a bare tool invocation when a justfile exists", () => {
  const surfaced = surfacedFor(withJustfile, "pytest tests/");
  assert.match(surfaced, /just --list/);
});

test("recognizes a capitalized Justfile", () => {
  const surfaced = surfacedFor(withCapitalizedJustfile, "cargo test");
  assert.match(surfaced, /justfile/);
});

test("stays silent when no justfile exists", () => {
  assert.strictEqual(surfacedFor(withoutJustfile, "npm run build"), "");
});

test("stays silent when the command already uses just", () => {
  assert.strictEqual(surfacedFor(withJustfile, "just build"), "");
});

test("stays silent for a non build/test/lint command", () => {
  assert.strictEqual(surfacedFor(withJustfile, "npm install"), "");
});

fs.rmSync(withJustfile, { recursive: true, force: true });
fs.rmSync(withCapitalizedJustfile, { recursive: true, force: true });
fs.rmSync(withoutJustfile, { recursive: true, force: true });

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n6 passing");
