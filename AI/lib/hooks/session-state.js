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

// Session files are never deleted when a session ends, so they'd otherwise
// accumulate forever. Prune ones untouched for this long, but only check once
// per PRUNE_INTERVAL_MS (via a marker file's mtime) so a directory scan isn't
// happening on every single hook invocation.
const MAX_AGE_MS = 14 * 24 * 60 * 60 * 1000;
const PRUNE_INTERVAL_MS = 24 * 60 * 60 * 1000;
const PRUNE_MARKER = path.join(STATE_DIR, ".last-prune");

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
 * Delete session files untouched for longer than MAX_AGE_MS, at most once per
 * PRUNE_INTERVAL_MS. Best-effort: any failure here must never break the
 * caller's actual read/write.
 */
function pruneStaleSessions() {
  try {
    const markerAge = Date.now() - fs.statSync(PRUNE_MARKER).mtimeMs;
    if (markerAge < PRUNE_INTERVAL_MS) {
      return;
    }
  } catch {
    // no marker yet — proceed with a prune pass
  }

  try {
    for (const entry of fs.readdirSync(STATE_DIR)) {
      if (!entry.endsWith(".json")) {
        continue;
      }
      const entryPath = path.join(STATE_DIR, entry);
      if (Date.now() - fs.statSync(entryPath).mtimeMs > MAX_AGE_MS) {
        fs.rmSync(entryPath, { force: true });
      }
    }
  } catch {
    // directory may not exist yet, or a concurrent hook won the race — fine
  }

  try {
    fs.writeFileSync(PRUNE_MARKER, "");
  } catch {
    // best-effort throttle marker; a missed write just means we re-scan sooner
  }
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
  pruneStaleSessions();
  return next;
}

module.exports = { read, update, STATE_DIR };
