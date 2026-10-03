#!/usr/bin/env node
const { record } = require("./review-checkpoint");

const usage =
  'Usage: node ~/dotfiles/AI/lib/hooks/review-checkpoint-cli.js reviewed|skip [--reason "..."] [--cwd PATH]';
try {
  const args = process.argv.slice(2);
  const outcome = args.shift();
  let cwd = process.cwd(),
    reason = "";
  while (args.length) {
    const flag = args.shift();
    const value = args.shift();
    if (!value || !["--reason", "--cwd"].includes(flag)) throw new Error(usage);
    if (flag === "--cwd") cwd = value;
    else reason = value;
  }
  if (!["reviewed", "skip"].includes(outcome)) throw new Error(usage);
  const decision = record(cwd, outcome, reason);
  console.log(
    `Recorded ${decision.outcome} for ${decision.branch} at ${decision.head.slice(0, 12)}${reason ? ": " + reason : ""}.`,
  );
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
