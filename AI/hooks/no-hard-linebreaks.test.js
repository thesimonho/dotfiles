#!/usr/bin/env node
/**
 * Unit test for no-hard-linebreaks.js.
 *
 * Writes temp markdown fixtures (hard-wrapped, naturally-wrapped, and one with
 * a fenced code block) and asserts the surfaced additionalContext ("" when the
 * hook stays silent). Run: node AI/hooks/no-hard-linebreaks.test.js
 */

const assert = require("node:assert");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const HOOK = path.join(__dirname, "no-hard-linebreaks.js");
const workdir = fs.mkdtempSync(path.join(os.tmpdir(), "hard-wrap-hook-"));

/**
 * Write a fixture markdown file in the temp workdir and return its name.
 *
 * @param {string} name
 * @param {string} body
 * @returns {string}
 */
function fixture(name, body) {
  fs.writeFileSync(path.join(workdir, name), body);
  return name;
}

/**
 * Run the hook for a touched markdown file and return the surfaced
 * additionalContext ("" when the hook stays silent).
 *
 * @param {string} fileName
 * @returns {string}
 */
function surfacedFor(fileName) {
  const stdout = execFileSync("node", [HOOK], {
    input: JSON.stringify({ cwd: workdir, tool_input: { file_path: fileName } }),
    encoding: "utf8",
  });
  if (!stdout.trim()) {
    return "";
  }
  return JSON.parse(stdout).hookSpecificOutput.additionalContext;
}

// Three consecutive ~72-char lines — the classic hard-wrap signature.
const hardWrapped = fixture(
  "hard-wrapped.md",
  [
    "This is a sentence that has been manually wrapped at roughly seventy chars.",
    "It continues here across several lines instead of one long flowing line.",
    "Each line lands in the fifty five to one hundred character wrap-width band.",
  ].join("\n"),
);

// Single-line paragraphs (one blank line between each) — natural wrapping.
const naturallyWrapped = fixture(
  "natural.md",
  [
    "# Notes",
    "",
    "This is a single long paragraph that just keeps going and going and going and going and never manually breaks across multiple short lines because it wraps naturally in the editor.",
    "",
    "Another short paragraph.",
  ].join("\n"),
);

// A fenced code block whose lines fall in the wrap-width band should not count.
const withFence = fixture(
  "fenced.md",
  [
    "# Example",
    "",
    "```text",
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    "```",
    "",
    "Just some closing text.",
  ].join("\n"),
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

test("fires for a hard-wrapped paragraph", () => {
  const surfaced = surfacedFor(hardWrapped);
  assert.match(surfaced, /hard-wrapped\.md/);
  assert.match(surfaced, /hard-wrapped/);
});

test("stays silent for naturally-wrapped single-line paragraphs", () => {
  assert.strictEqual(surfacedFor(naturallyWrapped), "");
});

test("stays silent for wrap-width lines inside a fenced code block", () => {
  assert.strictEqual(surfacedFor(withFence), "");
});

test("stays silent for a non-markdown file", () => {
  assert.strictEqual(surfacedFor("does-not-exist.js"), "");
});

fs.rmSync(workdir, { recursive: true, force: true });

if (failures > 0) {
  console.error(`\n${failures} failing`);
  process.exit(1);
}
console.log("\n4 passing");
