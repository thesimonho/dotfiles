#!/usr/bin/env node

import { spawn } from "node:child_process";
import { readFileSync, realpathSync } from "node:fs";
import { dirname, join } from "node:path";

const MAXIMUM_LAUNCHER_DEPTH = 4;

/**
 * Follow Nix launcher wrappers until reaching the current Codex app directory.
 *
 * Home Manager keeps the first launcher path stable across generations, while
 * each wrapper points at the next immutable store path in the launcher chain.
 */
function findCodexAppDirectory(launcherPath, remainingDepth = MAXIMUM_LAUNCHER_DEPTH) {
  if (remainingDepth === 0) {
    throw new Error("Codex Desktop launcher chain is too deep");
  }

  const resolvedLauncherPath = realpathSync(launcherPath);
  const launcherContents = readFileSync(resolvedLauncherPath, "utf8");
  const execTarget = launcherContents.match(/^exec "([^"]+)"/m)?.[1];

  if (!execTarget) {
    throw new Error(`Could not find exec target in ${resolvedLauncherPath}`);
  }

  if (execTarget.endsWith("/opt/codex-desktop/start.sh")) {
    return dirname(execTarget);
  }

  return findCodexAppDirectory(execTarget, remainingDepth - 1);
}

/** Launch the reaper without holding the SessionStart hook open. */
function launchReaper() {
  if (process.env.CODEX_MCP_HELPER_REAPER_DISABLE === "1") {
    return;
  }

  const homeDirectory = process.env.HOME;
  if (!homeDirectory) {
    return;
  }

  const stableLauncherPath = join(
    homeDirectory,
    ".local/state/nix/profiles/home-manager/home-path/bin/codex-desktop",
  );
  const appDirectory = findCodexAppDirectory(stableLauncherPath);
  const reaperPath = join(
    appDirectory,
    ".codex-linux/mcp-helper-reaper/codex-mcp-helper-reaper",
  );
  const reaperArguments = [
    "--codex-parent",
    String(process.ppid),
    "--include-orphans",
    "--app-dir",
    appDirectory,
    "--delay",
    process.env.CODEX_MCP_HELPER_REAPER_DELAY ?? "3",
    "--passes",
    process.env.CODEX_MCP_HELPER_REAPER_PASSES ?? "3",
    "--interval",
    process.env.CODEX_MCP_HELPER_REAPER_INTERVAL ?? "2",
    "--term-timeout",
    process.env.CODEX_MCP_HELPER_REAPER_TERM_TIMEOUT ?? "2",
    "--quiet",
  ];

  spawn(reaperPath, reaperArguments, {
    detached: true,
    stdio: "ignore",
  }).unref();
}

try {
  launchReaper();
} catch {
  // Cleanup is best-effort and must never prevent a Codex session from starting.
}
