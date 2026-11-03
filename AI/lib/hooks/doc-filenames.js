/** Shared documentation filename policy. Each list has a distinct purpose. */

// Root Markdown files that may be created or edited.
const ROOT_MARKDOWN_ALLOWLIST = new Set([
  "AGENTS.md",
  "CLAUDE.md",
  "README.md",
  "CONTRIBUTING.md",
  "CODE_OF_CONDUCT.md",
  "SECURITY.md",
  "CHANGELOG.md",
  "PRODUCT.md",
  "DESIGN.md",
  "VISION.md",
  "TODO.md",
]);

// Filenames eligible to declare agent.on-change couplings anywhere in a tree.
// Other Markdown files must be at the scan root or under docs/ to be discovered.
const COUPLING_DISCOVERY_FILENAMES = new Set([
  "README.md",
  "INDEX.md",
  "AGENTS.md",
  "SKILL.md",
]);

module.exports = {
  ROOT_MARKDOWN_ALLOWLIST,
  COUPLING_DISCOVERY_FILENAMES,
};
