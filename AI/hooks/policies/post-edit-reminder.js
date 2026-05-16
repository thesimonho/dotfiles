#!/usr/bin/env node
/**
 * Hook: Remind agents to verify after editing files.
 */

const { addContext } = require("../../lib/hooks/hook-response");

addContext(
  "PostToolUse",
  "Reminder (no need to respond): Run the project formatter, typechecker, linter. Also check: functions < 30 lines, functions have docstrings, file < 800 lines, no hardcoded values (use existing types/const).",
);
