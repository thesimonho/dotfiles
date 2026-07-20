/**
 * Normalize the small payload differences that shared policies rely on.
 *
 * Native fields are retained so policies can still use event-specific data.
 *
 * @param {"claude" | "codex"} host
 * @param {object} payload
 * @returns {object}
 */
function normalizePayload(host, payload) {
  const toolInput = payload.tool_input ?? {};
  const filePaths = filePathsFrom(toolInput);

  if (host !== "codex" || payload.tool_name !== "apply_patch") {
    return {
      ...payload,
      tool_input: { ...toolInput, file_paths: filePaths },
    };
  }

  const patch = toolInput.command ?? "";
  return {
    ...payload,
    tool_input: {
      ...toolInput,
      file_path: toolInput.file_path ?? filePaths[0],
      path: toolInput.path ?? filePaths[0],
      file_paths: filePaths,
      content: toolInput.content ?? patch,
      new_string: toolInput.new_string ?? patch,
    },
  };
}

/**
 * @param {object} toolInput
 * @returns {string[]}
 */
function filePathsFrom(toolInput) {
  const directPaths = [toolInput.file_path, toolInput.path].filter(Boolean);
  const patch = toolInput.command ?? "";
  const patchPaths = [...patch.matchAll(/^\*\*\* (?:Add|Update) File: (.+)$/gm)].map(
    (match) => match[1],
  );

  return [...new Set([...directPaths, ...patchPaths])];
}

module.exports = { normalizePayload };
