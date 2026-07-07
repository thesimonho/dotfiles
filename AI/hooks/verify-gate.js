#!/usr/bin/env node
/**
 * Hook: Verify Stop-gate — OBSERVE-ONLY phase.
 *
 * At turn-end, if code changed this session and no verification ran after it, the
 * gate records what it *would* have blocked to an observe log. It does NOT block
 * yet — this phase measures the false-positive rate (e.g. stops to ask a
 * clarifying question) before blocking is armed. Wire under the Stop event.
 *
 * To arm blocking later: on a would-block, emit exit code 2 with the reason
 * instead of only logging (respecting the stop_hook_active loop guard, already
 * handled below).
 */

const fs = require("node:fs");
const path = require("node:path");
const state = require("../lib/hooks/session-state");

const OBSERVE_LOG = path.join(state.STATE_DIR, "..", "verify-observe.log");

// A project has real verification tooling when one of these is present at cwd.
const TOOLING_MARKERS = [
  "justfile",
  "Justfile",
  "package.json",
  "Cargo.toml",
  "pyproject.toml",
  "go.mod",
];

/**
 * Whether the working directory has a verification toolchain worth gating on.
 *
 * @param {string} cwd
 * @returns {boolean}
 */
function hasTooling(cwd) {
  return TOOLING_MARKERS.some((marker) => fs.existsSync(path.join(cwd, marker)));
}

/**
 * Append a would-block record to the observe log (best-effort).
 *
 * @param {string} cwd
 * @param {string} timestamp
 */
function recordWouldBlock(cwd, timestamp) {
  try {
    fs.mkdirSync(path.dirname(OBSERVE_LOG), { recursive: true });
    fs.appendFileSync(
      OBSERVE_LOG,
      `${timestamp}\t${cwd}\tcode changed but no verify ran after the last edit\n`,
    );
  } catch {
    // observe-only telemetry must never break the stop
  }
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);

  if (payload.stop_hook_active) {
    return; // loop guard: we already acted this turn
  }

  const session = state.read(payload.session_id);
  const cwd = payload.cwd ?? process.cwd();

  if (session.dirty && hasTooling(cwd)) {
    recordWouldBlock(cwd, new Date().toISOString());
  }
  // OBSERVE-ONLY: never block. Exit 0.
});
