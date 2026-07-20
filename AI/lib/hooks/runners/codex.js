#!/usr/bin/env node

const { runPolicy } = require("../run-policy");

runPolicy("codex", process.argv[2]).catch((error) => {
  console.error(`[Hook] ${error.message}`);
  process.exitCode = 1;
});
