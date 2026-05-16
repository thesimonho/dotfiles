#!/usr/bin/env node

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const sourceDirectory = process.env.AGENTS_SOURCE_DIR || path.resolve("AI/agents");
const outputDirectory =
  process.env.AGENTS_OUTPUT_DIR || path.join(sourceDirectory, ".generated");
const codexSkillsDirectory =
  process.env.CODEX_SKILLS_DIR ||
  path.join(process.env.HOME || "~", ".codex", "skills");
const yqBinary = process.env.YQ_BIN || "yq";

const claudeDirectory = path.join(outputDirectory, "claude");
const codexDirectory = path.join(outputDirectory, "codex");
const piDirectory = path.join(outputDirectory, "pi");

function fail(message) {
  console.error(message);
  process.exit(1);
}

function assertYqAvailable() {
  try {
    execFileSync(yqBinary, ["--version"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
  } catch (error) {
    const configuredPath = process.env.YQ_BIN
      ? `Configured YQ_BIN was: ${process.env.YQ_BIN}`
      : "Set YQ_BIN or install yq on PATH.";

    fail(`Unable to run yq, which is required for agent YAML parsing. ${configuredPath}`);
  }
}

function splitAgentFile(filePath) {
  const content = fs.readFileSync(filePath, "utf8");
  const match = content.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);

  if (!match) {
    fail(`${filePath}: expected YAML frontmatter delimited by ---`);
  }

  return {
    frontmatter: parseFrontmatter(match[1], filePath),
    body: match[2].trim(),
  };
}

function parseFrontmatter(input, filePath) {
  try {
    const json = yqFromContent(input, false);

    return JSON.parse(json) || {};
  } catch (error) {
    fail(`${filePath}: invalid YAML frontmatter: ${error.message}`);
  }
}

function ensureRequiredFields(filePath, metadata) {
  for (const field of ["name", "description"]) {
    if (!metadata[field] || typeof metadata[field] !== "string") {
      fail(`${filePath}: missing required string field "${field}"`);
    }
  }
}

function writeClaudeAgent(fileName, metadata, body) {
  const claudeMetadata = {
    name: metadata.name,
    description: metadata.description,
    ...(metadata.claude || {}),
  };

  fs.writeFileSync(
    path.join(claudeDirectory, fileName),
    `---\n${yamlStringify(removeNullish(claudeMetadata))}---\n\n${body}\n`,
  );
}

function writeCodexAgent(fileName, metadata, body) {
  const codexMetadata = metadata.codex || {};
  const codexAgent = {
    name: metadata.name,
    description: metadata.description,
    ...without(codexMetadata, ["skills"]),
    developer_instructions: body,
  };

  fs.writeFileSync(
    path.join(codexDirectory, fileName.replace(/\.md$/, ".toml")),
    `${tomlStringify({
      ...removeNullish(codexAgent),
      ...codexSkillConfig(codexMetadata.skills),
    })}\n`,
  );
}

function writePiAgent(fileName, metadata, body) {
  const piMetadata = {
    name: metadata.name,
    description: metadata.description,
    ...(metadata.pi || {}),
  };

  fs.writeFileSync(
    path.join(piDirectory, fileName),
    `---\n${yamlStringify(removeNullish(piMetadata))}---\n\n${body}\n`,
  );
}

function without(object, excludedKeys) {
  return Object.fromEntries(
    Object.entries(object).filter(([key]) => !excludedKeys.includes(key)),
  );
}

function yamlStringify(object) {
  return yqFromContent(JSON.stringify(object), true);
}

function yqFromContent(content, shouldEmitYaml) {
  const tempDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "agent-yq-"));
  const tempFile = path.join(tempDirectory, "input");

  try {
    fs.writeFileSync(tempFile, content);
    return execFileSync(
      yqBinary,
      [...(shouldEmitYaml ? ["-y"] : []), ".", tempFile],
      { encoding: "utf8" },
    );
  } finally {
    fs.rmSync(tempDirectory, { force: true, recursive: true });
  }
}

function tomlStringify(object) {
  const scalarEntries = Object.entries(object).filter(
    ([, value]) => !isPlainObject(value),
  );
  const nestedEntries = Object.entries(object).filter(([, value]) =>
    isPlainObject(value),
  );

  return [
    ...scalarEntries.map(([key, value]) => tomlLine(key, value)),
    ...nestedEntries.flatMap(([key, value]) => tomlObject(key, value)),
  ].join("\n");
}

function tomlLine(key, value) {
  if (Array.isArray(value)) {
    return `${key} = [${value.map(tomlValue).join(", ")}]`;
  }

  return `${key} = ${tomlValue(value)}`;
}

function tomlValue(value) {
  if (typeof value === "boolean" || typeof value === "number") {
    return String(value);
  }

  const stringValue = String(value);
  if (stringValue.includes("\n")) {
    return `"""\n${escapeTomlMultiline(stringValue)}\n"""`;
  }

  return JSON.stringify(stringValue);
}

function tomlObject(prefix, object) {
  const scalarEntries = Object.entries(object).filter(
    ([, value]) => !isPlainObject(value),
  );
  const nestedEntries = Object.entries(object).filter(([, value]) =>
    isPlainObject(value),
  );

  return [
    "",
    `[${prefix}]`,
    ...scalarEntries.map(([key, value]) => tomlLine(key, value)),
    ...nestedEntries.flatMap(([key, value]) =>
      tomlObject(`${prefix}.${key}`, value),
    ),
  ];
}

function isPlainObject(value) {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}

function escapeTomlMultiline(value) {
  return value.replaceAll("\\", "\\\\").replaceAll('"""', '\\"\\"\\"');
}

function codexSkillConfig(skills) {
  if (!skills) return {};

  const skillNames = Array.isArray(skills) ? skills : [skills];
  return {
    skills: {
      config: skillNames.map((skillName) => ({
        path: path.join(codexSkillsDirectory, skillName, "SKILL.md"),
        enabled: true,
      })),
    },
  };
}

function removeNullish(object) {
  return Object.fromEntries(
    Object.entries(object).filter(
      ([, value]) => value !== undefined && value !== null,
    ),
  );
}

function resetDirectory(directory) {
  fs.rmSync(directory, { force: true, recursive: true });
  fs.mkdirSync(directory, { recursive: true });
}

assertYqAvailable();
resetDirectory(claudeDirectory);
resetDirectory(codexDirectory);
resetDirectory(piDirectory);

for (const fileName of fs.readdirSync(sourceDirectory).sort()) {
  if (!fileName.endsWith(".md")) {
    continue;
  }

  const filePath = path.join(sourceDirectory, fileName);
  const { frontmatter, body } = splitAgentFile(filePath);

  ensureRequiredFields(filePath, frontmatter);
  writeClaudeAgent(fileName, frontmatter, body);
  writeCodexAgent(fileName, frontmatter, body);
  writePiAgent(fileName, frontmatter, body);
}
