/**
 * Minimal reader for the `agent:` frontmatter block used by the surfacer and the
 * coupling-surface hooks. It is NOT a general YAML parser — it understands
 * exactly the two optional fields the hooks need:
 *
 *   ---
 *   agent:
 *     instruction: Update this map when the mapped directory changes.
 *     on-change: "src/features/**"     # a scalar, a ["a","b"] flow list, or a
 *   ---                                # block list of "- glob" lines below
 *
 * Node ships no YAML parser and hooks take no dependencies, so this stays small
 * and lenient: anything it cannot read is treated as absent.
 */

/**
 * The raw frontmatter block (text between the leading `---` fences), or null.
 *
 * @param {string} content
 * @returns {string|null}
 */
function frontmatterBlock(content) {
  const match = /^---\r?\n([\s\S]*?)\r?\n---\r?(?:\n|$)/.exec(content);
  return match ? match[1] : null;
}

/**
 * Strip surrounding single/double quotes from a scalar value.
 *
 * @param {string} value
 * @returns {string}
 */
function unquote(value) {
  const trimmed = value.trim();
  const quoted = /^(['"])([\s\S]*)\1$/.exec(trimmed);
  return quoted ? quoted[2] : trimmed;
}

/**
 * Parse an inline flow list `["a", "b"]` into its items.
 *
 * @param {string} value
 * @returns {string[]}
 */
function parseFlowList(value) {
  return value
    .replace(/^\[|\]$/g, "")
    .split(",")
    .map((item) => unquote(item))
    .filter(Boolean);
}

/**
 * Collect a YAML block list (`  - glob`) that follows an `on-change:` line.
 *
 * @param {string[]} lines
 * @param {number} startIndex the on-change: line index
 * @param {string[]} out globs are pushed here
 * @returns {number} the index of the last consumed line
 */
function collectBlockList(lines, startIndex, out) {
  let lastIndex = startIndex;
  for (let j = startIndex + 1; j < lines.length; j++) {
    const item = lines[j].match(/^\s+-\s*(.+)$/);
    if (!item) {
      break;
    }
    out.push(unquote(item[1]));
    lastIndex = j;
  }
  return lastIndex;
}

/**
 * Read the optional agent.instruction and agent.on-change fields from a document.
 *
 * @param {string} content
 * @returns {{instruction: string|null, onChange: string[]}}
 */
function parseAgentFrontmatter(content) {
  const block = frontmatterBlock(content);
  if (!block) {
    return { instruction: null, onChange: [] };
  }

  const lines = block.split("\n");
  const agentIndex = lines.findIndex((line) => /^agent:\s*$/.test(line));
  if (agentIndex === -1) {
    return { instruction: null, onChange: [] };
  }

  let instruction = null;
  const onChange = [];
  for (let i = agentIndex + 1; i < lines.length; i++) {
    const line = lines[i];
    if (/^\S/.test(line)) {
      break; // a new top-level key ends the agent block
    }

    const instructionMatch = line.match(/^\s+instruction:\s*(.+)$/);
    if (instructionMatch) {
      instruction = unquote(instructionMatch[1]);
      continue;
    }

    const onChangeMatch = line.match(/^\s+on-change:\s*(.*)$/);
    if (onChangeMatch) {
      const value = onChangeMatch[1].trim();
      if (value.startsWith("[")) {
        onChange.push(...parseFlowList(value));
      } else if (value) {
        onChange.push(unquote(value));
      } else {
        i = collectBlockList(lines, i, onChange);
      }
    }
  }

  return { instruction, onChange };
}

module.exports = { parseAgentFrontmatter };
