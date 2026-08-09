/**
 * Per-session scratch state shared across hook invocations.
 *
 * Hooks fire as separate short-lived processes, so anything a hook needs to
 * remember within a session (did code change? did verify run?) lives in a small
 * JSON file keyed by session_id. Used by the verify gate and
 * the nudge throttle.
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
 * Absolute path of a session's state file.
 *
 * Hooks bound to the same event run concurrently, and `update` is a
 * read-modify-write, so writers of one concern can drop another's changes. A
 * namespace gives an independent concern its own file, which is the cheapest
 * way to keep unrelated hooks from interfering.
 *
 * @param {string} sessionId
 * @param {string} [namespace] omit for the default state file
 * @returns {string}
 */
function statePath(sessionId, namespace) {
  const safe = String(sessionId || "unknown").replace(/[^\w.-]/g, "_");
  const suffix = namespace ? `.${namespace}` : "";
  return path.join(STATE_DIR, `${safe}${suffix}.json`);
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
 * @param {string} [namespace]
 * @returns {object}
 */
function read(sessionId, namespace) {
  try {
    return JSON.parse(fs.readFileSync(statePath(sessionId, namespace), "utf8"));
  } catch {
    return {};
  }
}

/**
 * Merge a patch into a session's state and persist it.
 *
 * An unwritable state directory is survivable, so a failed write is swallowed
 * rather than thrown. Hooks run inside sandboxes that may mount the cache
 * read-only, and a policy that throws exits non-zero, which a host can read as
 * a blocked tool call: an unwritable cache would then stop the agent working
 * rather than cost it a marker. Losing the write degrades honestly instead —
 * a nudge repeats, and the verify gate re-surfaces a reminder it already gave.
 *
 * `read` already returns {} for an unreadable file, so both directions of the
 * state round trip now fail soft.
 *
 * @param {string} sessionId
 * @param {object} patch
 * @param {string} [namespace]
 * @returns {object} the new state, persisted only if the cache was writable
 */
function update(sessionId, patch, namespace) {
  const next = { ...read(sessionId, namespace), ...patch };
  try {
    fs.mkdirSync(STATE_DIR, { recursive: true });
    fs.writeFileSync(statePath(sessionId, namespace), JSON.stringify(next));
    pruneStaleSessions();
  } catch {
    // Intentionally silent: see above.
  }
  return next;
}

module.exports = { read, update, STATE_DIR };
