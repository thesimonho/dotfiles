#!/usr/bin/env node
/**
 * Unit test for lsp-nudge.js.
 *
 * Runs the hook against sample Grep/Glob payloads and asserts the surfaced
 * additionalContext ("" when the hook stays silent). Run: node AI/hooks/lsp-nudge.test.js
 */

const assert = require("node:assert");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "lsp-nudge.js");

/**
 * Run the hook for a Grep/Glob pattern and return the surfaced
 * additionalContext ("" when the hook stays silent).
 *
 * @param {string} toolName
 * @param {string} pattern
 * @returns {string}
 */
function surfacedFor(toolName, pattern) {
  const stdout = execFileSync("node", [HOOK], {
    input: JSON.stringify({ tool_name: toolName, tool_input: { pattern } }),
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

test("fires for a bare symbol in Grep", () => {
  const surfaced = surfacedFor("Grep", "computeTotalPrice");
  assert.match(surfaced, /LSP/);
});

test("fires for a dotted symbol in Grep", () => {
  const surfaced = surfacedFor("Grep", "user.email");
  assert.match(surfaced, /LSP/);
});

test("stays silent for a text phrase with spaces", () => {
  assert.strictEqual(surfacedFor("Grep", "TODO fix this"), "");
});

test("stays silent for a regex pattern", () => {
  assert.strictEqual(surfacedFor("Grep", "^export (const|function)"), "");
});

test("stays silent for a glob path pattern", () => {
  assert.strictEqual(surfacedFor("Glob", "src/**/*.tsx"), "");
});

test("stays silent when no pattern is given", () => {
  assert.strictEqual(surfacedFor("Grep", ""), "");
});

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n6 passing");
