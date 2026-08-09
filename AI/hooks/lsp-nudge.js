#!/usr/bin/env node
/**
 * Hook: Nudge toward LSP navigation when a search targets a bare symbol.
 *
 * tools.md prefers LSP (goToDefinition / findReferences / workspaceSymbol) over
 * text search for code navigation, reserving grep for text/config. A bare
 * identifier pattern (no spaces, no regex metacharacters) is the signature of
 * "I'm looking for a symbol" rather than a text phrase, so that's the only
 * shape this fires on.
 *
 * Searches arrive as shell commands, not as a Grep tool call: tools.md requires
 * Bash so rtk can compress output, and Codex has no Grep or Glob tool at all —
 * its only search path is the shell. Reading the command therefore covers both
 * hosts, where matching a Grep tool covered neither in practice.
 */

const { addContext, doNothing } = require("../lib/hooks/policy-result");

// A bare code identifier: letters/digits/underscore, optionally dotted
// (e.g. `foo.bar`), with no spaces or regex metacharacters.
const BARE_IDENTIFIER = /^[A-Za-z_][A-Za-z0-9_.]*$/;

/** Search programs whose first positional argument is the pattern. */
const SEARCH_PROGRAMS = new Set(["grep", "rg", "egrep", "fgrep", "ripgrep"]);

/** Wrappers that precede the real program without changing its arguments. */
const COMMAND_PREFIXES = new Set(["rtk", "command", "sudo", "time", "xargs"]);

/** Shell operators that end the first pipeline stage. */
const STAGE_SEPARATORS = new Set(["|", ";", "&&", "||"]);

/**
 * Split a command into tokens, keeping quoted runs whole.
 *
 * Splitting on whitespace alone turned `grep "user login failed"` into a first
 * token of `user`, which reads as a bare identifier and fired the nudge on a
 * plain text search. The quotes are what distinguish a phrase from a symbol,
 * so they have to survive tokenization.
 *
 * @param {string} command
 * @returns {{ text: string, wasQuoted: boolean }[]}
 */
function tokenize(command) {
  const tokens = [];
  let current = "";
  let quote = null;
  let quoted = false;

  for (const character of command) {
    if (quote) {
      if (character === quote) {
        quote = null;
      } else {
        current += character;
      }
      continue;
    }
    if (character === "'" || character === '"') {
      quote = character;
      quoted = true;
      continue;
    }
    if (/\s/.test(character)) {
      if (current || quoted) {
        tokens.push({ text: current, wasQuoted: quoted });
      }
      current = "";
      quoted = false;
      continue;
    }
    current += character;
  }

  if (current || quoted) {
    tokens.push({ text: current, wasQuoted: quoted });
  }

  return tokens;
}

/**
 * Extract the search pattern from a shell command, if it is a plain search.
 *
 * Only the first pipeline stage is considered: `rg foo | head` searches for a
 * symbol, while `cat x | grep foo` is filtering output that is already in hand
 * and has nothing for LSP to resolve.
 *
 * @param {string} command
 * @returns {string | null}
 */
function searchPattern(command) {
  const all = tokenize(command);
  const separator = all.findIndex(
    (token) => !token.wasQuoted && STAGE_SEPARATORS.has(token.text),
  );
  const tokens = (separator === -1 ? all : all.slice(0, separator)).map(
    (token) => token.text,
  );
  let index = 0;

  while (index < tokens.length && COMMAND_PREFIXES.has(tokens[index])) {
    index += 1;
  }

  const program = tokens[index];
  if (!program || !SEARCH_PROGRAMS.has(program)) {
    return null;
  }

  for (const token of tokens.slice(index + 1)) {
    if (token.startsWith("-")) {
      continue;
    }
    return token.replace(/^['"]|['"]$/g, "");
  }

  return null;
}

function evaluate(payload) {
  const toolInput = payload.tool_input ?? {};
  const pattern = toolInput.pattern ?? searchPattern(toolInput.command ?? "");

  if (!pattern || !BARE_IDENTIFIER.test(pattern)) {
    return doNothing();
  }

  return addContext(
    "Searching for a symbol — prefer LSP (goToDefinition / findReferences / workspaceSymbol) over text search for code navigation; use grep only for text/config.",
  );
}

module.exports = { evaluate, searchPattern };
