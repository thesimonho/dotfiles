#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");

const sourceDirectory = process.env.AGENTS_SOURCE_DIR || path.resolve("AI/agents");
const outputDirectory =
  process.env.AGENTS_OUTPUT_DIR || path.join(sourceDirectory, ".generated");
const codexSkillsDirectory =
  process.env.CODEX_SKILLS_DIR ||
  path.join(process.env.HOME || "~", ".codex", "skills");

const claudeDirectory = path.join(outputDirectory, "claude");
const codexDirectory = path.join(outputDirectory, "codex");
const piDirectory = path.join(outputDirectory, "pi");

function fail(message) {
  console.error(message);
  process.exit(1);
}

function splitAgentFile(filePath) {
  const content = fs.readFileSync(filePath, "utf8");
  const match = content.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);

  if (!match) {
    fail(`${filePath}: expected YAML frontmatter delimited by ---`);
  }

  return {
    frontmatter: parseSimpleYaml(match[1], filePath),
    body: match[2].trim(),
  };
}

function parseSimpleYaml(input, filePath) {
  const root = {};
  const stack = [{ indent: -1, value: root }];
  let activeArray = null;

  const lines = input.split("\n");

  for (const [index, rawLine] of lines.entries()) {
    if (!rawLine.trim() || rawLine.trimStart().startsWith("#")) {
      continue;
    }

    const indent = rawLine.match(/^ */)[0].length;
    const line = rawLine.trim();

    if (line.startsWith("- ")) {
      if (!activeArray || indent <= activeArray.indent) {
        fail(`${filePath}:${index + 1}: array item without an array key`);
      }

      activeArray.value.push(parseScalar(line.slice(2).trim()));
      continue;
    }

    activeArray = null;

    while (stack.length > 1 && indent <= stack.at(-1).indent) {
      stack.pop();
    }

    const match = line.match(/^([A-Za-z0-9_-]+):(?:\s*(.*))?$/);
    if (!match) {
      fail(`${filePath}:${index + 1}: unsupported frontmatter line: ${line}`);
    }

    const [, key, rawValue = ""] = match;
    const parent = stack.at(-1).value;

    if (rawValue === "") {
      const value = nextContentLineIsArray(lines, index);
      parent[key] = value;

      if (Array.isArray(value)) {
        activeArray = { indent, value };
      } else {
        stack.push({ indent, value });
      }

      continue;
    }

    parent[key] = parseScalar(rawValue);
  }

  return root;
}

function nextContentLineIsArray(lines, currentIndex) {
  for (const line of lines.slice(currentIndex + 1)) {
    if (!line.trim() || line.trimStart().startsWith("#")) {
      continue;
    }

    return line.trim().startsWith("- ") ? [] : {};
  }

  return {};
}

function parseScalar(value) {
  if (value === "true") return true;
  if (value === "false") return false;
  if (/^\d+$/.test(value)) return Number(value);

  const quotedMatch = value.match(/^["'](.*)["']$/);
  if (quotedMatch) return quotedMatch[1];

  const inlineArrayMatch = value.match(/^\[(.*)]$/);
  if (inlineArrayMatch) {
    return inlineArrayMatch[1]
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean)
      .map(parseScalar);
  }

  return value;
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

  const frontmatter = Object.entries(claudeMetadata)
    .filter(([, value]) => value !== undefined && value !== null)
    .map(([key, value]) => yamlLine(key, value))
    .join("\n");

  fs.writeFileSync(
    path.join(claudeDirectory, fileName),
    `---\n${frontmatter}\n---\n\n${body}\n`,
  );
}

function yamlLine(key, value) {
  if (Array.isArray(value)) {
    const items = value.map((item) => `  - ${yamlScalar(item)}`).join("\n");
    return `${key}:\n${items}`;
  }

  if (isPlainObject(value)) {
    return `${key}:\n${yamlObject(value, 2)}`;
  }

  return `${key}: ${yamlScalar(value)}`;
}

function yamlObject(object, indent) {
  return Object.entries(object)
    .map(([key, value]) => {
      const padding = " ".repeat(indent);

      if (Array.isArray(value)) {
        const items = value
          .map((item) => `${padding}  - ${yamlScalar(item)}`)
          .join("\n");
        return `${padding}${key}:\n${items}`;
      }

      if (isPlainObject(value)) {
        return `${padding}${key}:\n${yamlObject(value, indent + 2)}`;
      }

      return `${padding}${key}: ${yamlScalar(value)}`;
    })
    .join("\n");
}

function yamlScalar(value) {
  if (typeof value === "boolean" || typeof value === "number") {
    return String(value);
  }

  const stringValue = String(value);
  if (/[:#{}[\],&*?|\-<>=!%@`]/.test(stringValue)) {
    return JSON.stringify(stringValue);
  }

  return stringValue;
}

function writeCodexAgent(fileName, metadata, body) {
  const codexMetadata = metadata.codex || {};
  const codexAgent = {
    name: metadata.name,
    description: metadata.description,
    ...without(codexMetadata, ["skills"]),
    developer_instructions: body,
  };

  const toml = [
    ...Object.entries(codexAgent)
      .filter(([, value]) => value !== undefined && value !== null)
      .filter(([, value]) => !isPlainObject(value))
      .map(([key, value]) => tomlLine(key, value)),
    ...Object.entries(codexAgent)
      .filter(([, value]) => isPlainObject(value))
      .flatMap(([key, value]) => tomlObject(key, value)),
    ...codexSkillConfig(codexMetadata.skills),
  ].join("\n");

  fs.writeFileSync(
    path.join(codexDirectory, fileName.replace(/\.md$/, ".toml")),
    `${toml}\n`,
  );
}

function writePiAgent(fileName, metadata, body) {
  const piMetadata = {
    name: metadata.name,
    description: metadata.description,
    ...(metadata.pi || {}),
  };

  const frontmatter = Object.entries(piMetadata)
    .filter(([, value]) => value !== undefined && value !== null)
    .map(([key, value]) => yamlLine(key, value))
    .join("\n");

  fs.writeFileSync(
    path.join(piDirectory, fileName),
    `---\n${frontmatter}\n---\n\n${body}\n`,
  );
}

function without(object, excludedKeys) {
  return Object.fromEntries(
    Object.entries(object).filter(([key]) => !excludedKeys.includes(key)),
  );
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
  if (!skills) return [];

  const skillNames = Array.isArray(skills) ? skills : [skills];
  return skillNames.flatMap((skillName) => [
    "",
    "[[skills.config]]",
    `path = ${tomlValue(path.join(codexSkillsDirectory, skillName, "SKILL.md"))}`,
    "enabled = true",
  ]);
}

function resetDirectory(directory) {
  fs.rmSync(directory, { force: true, recursive: true });
  fs.mkdirSync(directory, { recursive: true });
}

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
