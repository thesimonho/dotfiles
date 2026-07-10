#!/usr/bin/env node
/**
 * Hook: Coupling surface — remind about a tracked area's doc the first time you
 * touch it this session.
 *
 * A doc can declare, in optional `agent:` frontmatter, which paths it tracks:
 *
 *   ---
 *   agent:
 *     instruction: Update this codemap when the mapped directory changes.
 *     on-change: "src/features/**"      # a scalar or a list of globs
 *   ---
 *
 * The first time (per session) you Read/Edit/Write/MultiEdit a file matching a
 * coupling's `on-change` glob, this surfaces that coupling once, then stays
 * silent for the rest of the session for that coupling — repeating on every
 * touch would just be noise once you've seen it.
 *
 * This used to be paired with a commit-time "you forgot to update the doc" gate
 * (coupling-gate.js), but that gate couldn't tell a doc-worthy change from an
 * irrelevant one — every fix for its false positives (commit-time-only, then
 * per-file dedup) was working around that unreliability rather than fixing it.
 * Surfacing the doc early, when you start touching the area, is the reliable
 * half: it's always a true statement ("this area is tracked, go read it"), and
 * an agent that's seen the doc is already positioned to update it as part of
 * the work rather than being nagged after the fact. The gate was removed;
 * `on-change` now only drives this hook.
 *
 * Coupling docs are discovered by scanning root-level and docs/ markdown once per
 * session (cached in session state; re-scanned if a markdown file is edited).
 * Wire under PostToolUse for Read|Edit|Write|MultiEdit.
 */

const path = require("node:path");
const { addContext } = require("../lib/hooks/hook-response");
const state = require("../lib/hooks/session-state");
const { globToRegExp, discoverCouplings } = require("../lib/hooks/coupling");

/**
 * The file path a Read/Edit/Write/MultiEdit targeted, across Claude and Codex
 * tool shapes.
 *
 * @param {object} toolInput
 * @returns {string}
 */
function targetPathFrom(toolInput) {
  return toolInput.file_path ?? toolInput.path ?? "";
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const target = targetPathFrom(payload.tool_input ?? {});
  if (!target) {
    return;
  }

  const cwd = payload.cwd ?? process.cwd();
  const relative = path.relative(cwd, path.resolve(cwd, target));
  if (relative.startsWith("..")) {
    return; // outside the project
  }

  const sessionId = payload.session_id;
  const session = state.read(sessionId);
  const isMarkdownEdit = payload.tool_name !== "Read" && relative.endsWith(".md");
  let couplings = session.couplings;
  if (!couplings || isMarkdownEdit) {
    couplings = discoverCouplings(cwd);
    state.update(sessionId, { couplings });
  }

  const surfaced = new Set(session.surfacedCouplings ?? []);
  const toSurface = [];
  for (const coupling of couplings) {
    if (coupling.file === relative || surfaced.has(coupling.file)) {
      continue; // it's the doc's own file (surface-file-header handles that), or already surfaced
    }
    if (coupling.globs.some((glob) => globToRegExp(glob).test(relative))) {
      toSurface.push(coupling);
      surfaced.add(coupling.file);
    }
  }

  if (toSurface.length === 0) {
    return;
  }

  state.update(sessionId, { surfacedCouplings: [...surfaced] });

  const lines = toSurface.map((coupling) =>
    coupling.instruction
      ? `${coupling.file}: ${coupling.instruction}`
      : `${coupling.file} tracks this area — read it if relevant.`,
  );
  addContext(
    "PostToolUse",
    `This file is tracked by a doc's on-change coupling — read it if you haven't:\n- ${lines.join("\n- ")}`,
  );
});
