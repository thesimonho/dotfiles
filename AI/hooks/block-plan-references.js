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

const { block, doNothing } = require("../lib/hooks/policy-result");

// A plan reference: a plan *file* under the plans directory, or a date-stamped
// plan filename anywhere. Requiring a filename (not the bare directory) lets prose
// mention the directory as a concept without tripping this block.
const PLAN_REFERENCE =
  /docs\/plans\/[\w.-]+\.(?:md|html)\b|\b\d{8}(-\d{4})?-[\w.-]+\.(?:md|html)\b/;

// Targets that are *allowed* to reference plans: the plans themselves, their
// archive, and each project's top-level docs index. The index's whole job is to
// link current plans (and it's expected to be kept live per its own on-change
// instruction), so it isn't the kind of stale breadcrumb this hook guards against.
// Everything else (code, rules, other docs) is not.
const PLAN_TARGET = /(^|\/)docs\/plans\//;
const ARCHIVE_TARGET = /(^|\/)archive\//;
const DOCS_INDEX_TARGET = /(^|\/)docs\/README\.md$/;

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

function evaluate(payload) {
  const toolInput = payload.tool_input ?? {};

  const target = targetPathFrom(toolInput);
  if (
    PLAN_TARGET.test(target) ||
    ARCHIVE_TARGET.test(target) ||
    DOCS_INDEX_TARGET.test(target)
  ) {
    return doNothing(); // a plan, an archived plan, or the docs index may reference plans
  }

  const content = writtenContentFrom(toolInput);
  if (PLAN_REFERENCE.test(content)) {
    return block("Don't reference plan files from code or docs", [
      `Target: ${target || "(unknown)"}`,
      "Plans under docs/plans/ are snapshots and get archived — the reference will rot.",
      "Put the rationale inline, or link a durable ADR under docs/ instead.",
    ]);
  }

  return doNothing();
}

module.exports = { evaluate };
