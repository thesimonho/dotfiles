#!/usr/bin/env node
/**
 * Hook: Block references to plan files from code, rules, and docs.
 *
 * Plans under docs/plans/ are snapshots — they get archived and superseded, so a
 * reference to one rots the moment the plan moves. The rule (planning.md): do NOT
 * reference plan files in code comments, rules files, or docs/ reference files.
 *
 * A write is blocked when its *content* mentions a plan file AND its *target* is
 * not itself a plan (or an archived plan). Writing/editing a plan that cites other
 * plans is fine; leaving a `See docs/plans/20260101-foo.html` breadcrumb in
 * index.js is not.
 *
 * Agent-neutral: reads Claude (tool_input.content / new_string) and Codex
 * (apply_patch command body) shapes.
 */

const { block } = require("../lib/hooks/hook-response");

// A plan reference: an explicit docs/plans/ path, or a date-stamped plan filename
// like 20260703-1500-widget-jsx-rewrite.html / 20260704-animated-icons.md.
const PLAN_REFERENCE = /docs\/plans\/|\b\d{8}(-\d{4})?-[\w.-]+\.(?:md|html)\b/;

// Targets that are *allowed* to reference plans: the plans themselves and their
// archive. Everything else (code, rules, other docs) is not.
const PLAN_TARGET = /(^|\/)docs\/plans\//;
const ARCHIVE_TARGET = /(^|\/)archive\//;

/**
 * Collect the file path a write targets, across Claude and Codex tool shapes.
 *
 * @param {object} toolInput
 * @returns {string}
 */
function targetPathFrom(toolInput) {
  const direct = toolInput.file_path ?? toolInput.path ?? "";
  if (direct) {
    return direct;
  }

  const command = toolInput.command ?? "";
  const patched = command.match(/^\*\*\* (?:Add|Update) File: (.+)$/m);
  return patched ? patched[1] : "";
}

/**
 * Collect the text a write would introduce, across Claude and Codex tool shapes.
 *
 * @param {object} toolInput
 * @returns {string}
 */
function writtenContentFrom(toolInput) {
  const parts = [
    toolInput.content,
    toolInput.new_string,
    toolInput.command, // Codex apply_patch carries the patch body inline
  ];

  return parts.filter((part) => typeof part === "string").join("\n");
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const toolInput = payload.tool_input ?? {};

  const target = targetPathFrom(toolInput);
  if (PLAN_TARGET.test(target) || ARCHIVE_TARGET.test(target)) {
    return; // a plan (or archived plan) may reference other plans
  }

  const content = writtenContentFrom(toolInput);
  if (PLAN_REFERENCE.test(content)) {
    block("Don't reference plan files from code or docs", [
      `Target: ${target || "(unknown)"}`,
      "Plans under docs/plans/ are snapshots and get archived — the reference will rot.",
      "Put the rationale inline, or link a durable ADR under docs/ instead.",
    ]);
  }
});
