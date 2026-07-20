#!/usr/bin/env node
/**
 * Hook: Nudge toward LSP navigation when a Grep/Glob pattern is a bare symbol.
 *
 * tools.md prefers LSP (goToDefinition / findReferences / workspaceSymbol) over
 * Grep/Glob for code navigation, reserving Grep/Glob for text/config search. A
 * bare identifier pattern (no spaces, no regex metacharacters) is the signature
 * of "I'm looking for a symbol" rather than a text phrase, so that's the only
 * shape this fires on.
 */

const { addContext, doNothing } = require("../lib/hooks/policy-result");

// A bare code identifier: letters/digits/underscore, optionally dotted
// (e.g. `foo.bar`), with no spaces or regex metacharacters.
const BARE_IDENTIFIER = /^[A-Za-z_][A-Za-z0-9_.]*$/;

function evaluate(payload) {
  const pattern = payload.tool_input?.pattern ?? "";

  if (!BARE_IDENTIFIER.test(pattern)) {
    return doNothing();
  }

  return addContext(
    "Searching for a symbol — prefer LSP (goToDefinition / findReferences / workspaceSymbol) over Grep/Glob for code navigation; use Grep only for text/config.",
  );
}

module.exports = { evaluate };
