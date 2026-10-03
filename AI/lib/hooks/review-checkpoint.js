/** A branch-scoped decision, invalidated by committed or uncommitted changes. */
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const state = require("./session-state");

function git(cwd, args) {
  return execFileSync("git", ["-C", cwd, ...args], {
    encoding: "utf8",
    maxBuffer: 32 * 1024 * 1024,
    stdio: ["ignore", "pipe", "pipe"],
  });
}

function hashFile(hash, file) {
  if (fs.lstatSync(file).isSymbolicLink()) {
    hash.update(fs.readlinkSync(file));
    return;
  }
  const descriptor = fs.openSync(file, "r");
  const buffer = Buffer.alloc(64 * 1024);
  try {
    let count;
    while (
      (count = fs.readSync(descriptor, buffer, 0, buffer.length, null)) > 0
    ) {
      hash.update(buffer.subarray(0, count));
    }
  } finally {
    fs.closeSync(descriptor);
  }
}

function snapshot(cwd) {
  const root = fs.realpathSync(
    git(cwd, ["rev-parse", "--show-toplevel"]).trim(),
  );
  const branch = git(root, [
    "symbolic-ref",
    "--quiet",
    "--short",
    "HEAD",
  ]).trim();
  const head = git(root, ["rev-parse", "HEAD"]).trim();
  const hash = crypto.createHash("sha256");
  hash.update(head);
  hash.update(
    git(root, ["status", "--porcelain=v1", "-z", "--untracked-files=all"]),
  );
  hash.update(
    git(root, ["diff", "HEAD", "--binary", "--no-ext-diff", "--no-textconv"]),
  );
  // Include content of new files: status alone cannot detect their later edits.
  const untracked = git(root, [
    "ls-files",
    "--others",
    "--exclude-standard",
    "-z",
  ]);
  for (const file of untracked.split("\0").filter(Boolean)) {
    hash.update(file + "\0");
    hashFile(hash, path.join(root, file));
  }
  return { root, branch, head, fingerprint: hash.digest("hex") };
}

function key(current) {
  return crypto
    .createHash("sha256")
    .update(current.root + "\0" + current.branch)
    .digest("hex");
}

function currentDecision(current) {
  const decision = state.read(key(current), "review-checkpoint");
  if (
    decision.version !== 1 ||
    decision.fingerprint !== current.fingerprint ||
    decision.root !== current.root ||
    decision.branch !== current.branch ||
    decision.head !== current.head ||
    !["reviewed", "skip"].includes(decision.outcome) ||
    (decision.outcome === "skip" && !decision.reason?.trim())
  )
    return null;
  return decision;
}

function record(cwd, outcome, reason = "") {
  if (!["reviewed", "skip"].includes(outcome))
    throw new Error("Choose reviewed or skip.");
  if (outcome === "skip" && !reason.trim())
    throw new Error("A skip requires --reason.");
  const current = snapshot(cwd);
  state.update(
    key(current),
    {
      version: 1,
      ...current,
      outcome,
      reason: reason.trim(),
      recordedAt: new Date().toISOString(),
    },
    "review-checkpoint",
  );
  const saved = currentDecision(current);
  if (!saved || saved.outcome !== outcome || saved.reason !== reason.trim()) {
    throw new Error(
      "Could not save the review checkpoint in the local hook state directory.",
    );
  }
  return saved;
}

module.exports = { snapshot, currentDecision, record, git };
