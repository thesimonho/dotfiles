/**
 * Per-session scratch state shared across hook invocations.
 *
 * Hooks fire as separate short-lived processes, so anything a hook needs to
 * remember within a session (did code change? did verify run?) lives in a small
 * JSON file keyed by session_id. Used by the verify gate, coupling gate, and the
 * compaction boundary nudge.
 *
 * The directory is overridable via AGENT_HOOK_STATE_DIR (tests point it at a temp
 * dir); it defaults to a per-user cache location.
 */

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const STATE_DIR =
  process.env.AGENT_HOOK_STATE_DIR || path.join(os.homedir(), ".cache", "agent-hooks", "sessions");

/**
 * Absolute path of the state file for a session.
 *
 * @param {string} sessionId
 * @returns {string}
 */
function statePath(sessionId) {
  const safe = String(sessionId || "unknown").replace(/[^\w.-]/g, "_");
  return path.join(STATE_DIR, `${safe}.json`);
}

/**
 * Read a session's state, or {} when none exists yet.
 *
 * @param {string} sessionId
 * @returns {object}
 */
function read(sessionId) {
  try {
    return JSON.parse(fs.readFileSync(statePath(sessionId), "utf8"));
  } catch {
    return {};
  }
}

/**
 * Merge a patch into a session's state and persist it.
 *
 * @param {string} sessionId
 * @param {object} patch
 * @returns {object} the new state
 */
function update(sessionId, patch) {
  const next = { ...read(sessionId), ...patch };
  fs.mkdirSync(STATE_DIR, { recursive: true });
  fs.writeFileSync(statePath(sessionId), JSON.stringify(next));
  return next;
}

module.exports = { read, update, STATE_DIR };
