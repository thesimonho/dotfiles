#!/usr/bin/env node
/**
 * Hook: Nudge formatting before a commit.
 *
 * Agent-written code that doesn't match the project's formatting gets reformatted
 * the next time the file is opened in an editor with format-on-save, producing
 * noisy "chore: formatting" churn. This reminds — once per session — to format
 * changed files before committing. It only nudges: formatting is the editor's job
 * and varies by filetype, so a portable hook must not run a formatter itself or
 * depend on a specific editor. It names a formatter config when the project has
 * one, otherwise points at matching the surrounding code. Wire under PreToolUse
 * for git commit.
 */

const fs = require("node:fs");
const path = require("node:path");
const { addContext } = require("../lib/hooks/hook-response");

// Formatter config markers → the tool to name in the nudge.
const FORMATTER_CONFIGS = [
  {
    name: "Prettier",
    files: [
      ".prettierrc",
      ".prettierrc.json",
      ".prettierrc.yaml",
      ".prettierrc.yml",
      ".prettierrc.js",
      ".prettierrc.cjs",
      "prettier.config.js",
      "prettier.config.cjs",
    ],
  },
  { name: "Biome", files: ["biome.json", "biome.jsonc"] },
  { name: "dprint", files: ["dprint.json", "dprint.jsonc", ".dprint.json"] },
  { name: "treefmt", files: ["treefmt.toml", ".treefmt.toml", "treefmt.nix"] },
  { name: "rustfmt", files: ["rustfmt.toml", ".rustfmt.toml"] },
  { name: "EditorConfig", files: [".editorconfig"] },
];

/**
 * Whether package.json declares a top-level "prettier" key.
 *
 * @param {string} cwd
 * @returns {boolean}
 */
function hasPrettierInPackageJson(cwd) {
  try {
    const pkg = JSON.parse(fs.readFileSync(path.join(cwd, "package.json"), "utf8"));
    return Boolean(pkg.prettier);
  } catch {
    return false;
  }
}

/**
 * Name a formatter the project configures, or null when none is detected.
 *
 * @param {string} cwd
 * @returns {string|null}
 */
function detectFormatter(cwd) {
  for (const { name, files } of FORMATTER_CONFIGS) {
    if (files.some((file) => fs.existsSync(path.join(cwd, file)))) {
      return name;
    }
  }
  return hasPrettierInPackageJson(cwd) ? "Prettier" : null;
}

let input = "";
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  const payload = JSON.parse(input);
  const command = payload.tool_input?.command ?? "";
  if (!/git\s+commit/.test(command)) {
    return; // the matcher is broad Bash; only nudge on commits
  }

  const cwd = payload.cwd ?? process.cwd();
  const formatter = detectFormatter(cwd);
  const how = formatter
    ? `to match the project's ${formatter} config`
    : "to match the surrounding code's conventions (indentation, quotes, spacing)";

  addContext(
    "PreToolUse",
    `Before committing: make sure changed files are formatted ${how}, so they don't reformat and churn on the next editor save.`,
  );
});
