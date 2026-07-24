/** Return used TypeScript modules reachable from one entry point. */

import fs from "node:fs";
import path from "node:path";

const workspaceRoot = fs.realpathSync(process.argv[2]);
const entryPath = resolveInsideWorkspace(process.argv[3]);
const pendingPaths = entryPath ? [entryPath] : [];
const reachablePaths = new Set();

while (pendingPaths.length > 0) {
  const sourcePath = pendingPaths.pop();
  if (!sourcePath || reachablePaths.has(sourcePath)) continue;
  reachablePaths.add(sourcePath);
  pendingPaths.push(...usedRelativeImports(sourcePath));
}

process.stdout.write(
  JSON.stringify(
    [...reachablePaths]
      .map((sourcePath) => path.relative(workspaceRoot, sourcePath))
      .sort(),
  ),
);

/** Return relative modules with bindings used outside their import declaration. */
function usedRelativeImports(sourcePath) {
  const tokens = tokenize(fs.readFileSync(sourcePath, "utf8"));
  const imports = moduleDeclarations(tokens);
  const importTokenIndexes = new Set(
    imports.flatMap(({ start, end }) =>
      Array.from({ length: end - start + 1 }, (_, offset) => start + offset),
    ),
  );
  return imports.flatMap(({ bindings, specifier }) => {
    const isUsed =
      bindings.size === 0 ||
      tokens.some(
        (token, index) =>
          !importTokenIndexes.has(index) &&
          token.kind === "identifier" &&
          bindings.has(token.value),
      );
    if (!isUsed || !specifier.startsWith(".")) return [];
    const importedPath = resolveInsideWorkspace(
      path.resolve(path.dirname(sourcePath), specifier),
    );
    return importedPath ? [importedPath] : [];
  });
}

/** Parse static import and runtime re-export declarations. */
function moduleDeclarations(tokens) {
  const imports = [];
  for (let index = 0; index < tokens.length; index += 1) {
    const declarationKind = tokens[index].value;
    if (
      tokens[index].kind !== "identifier" ||
      !["export", "import"].includes(declarationKind)
    ) {
      continue;
    }
    const nextToken = tokens[index + 1];
    if (!nextToken || nextToken.value === "(") continue;
    if (nextToken.kind === "string") {
      imports.push({
        start: index,
        end: index + 1,
        bindings: new Set(),
        specifier: nextToken.value,
      });
      continue;
    }
    if (nextToken.value === "type") continue;
    const fromIndex = tokens.findIndex(
      (token, tokenIndex) => tokenIndex > index && token.value === "from",
    );
    const specifierToken = tokens[fromIndex + 1];
    if (fromIndex < 0 || specifierToken?.kind !== "string") continue;
    const declarationTokens = tokens.slice(index + 1, fromIndex);
    const bindings =
      declarationKind === "export"
        ? new Set()
        : runtimeBindingNames(declarationTokens);
    if (
      declarationKind === "export" &&
      !declarationTokens.some((token) => token.value === "*") &&
      runtimeBindingNames(declarationTokens).size === 0
    ) {
      continue;
    }
    imports.push({
      start: index,
      end: fromIndex + 1,
      bindings,
      specifier: specifierToken.value,
    });
    index = fromIndex + 1;
  }
  return imports;
}

/** Exclude inline type-only bindings from runtime-use checks. */
function runtimeBindingNames(tokens) {
  const names = new Set();
  let isTypeOnlyBinding = false;
  for (const token of tokens) {
    if (token.value === ",") {
      isTypeOnlyBinding = false;
      continue;
    }
    if (token.value === "type") {
      isTypeOnlyBinding = true;
      continue;
    }
    if (
      token.kind === "identifier" &&
      token.value !== "as" &&
      !isTypeOnlyBinding
    ) {
      names.add(token.value);
    }
  }
  return names;
}

/** Tokenize the TypeScript subset needed to recognize static imports. */
function tokenize(source) {
  const tokens = [];
  for (let index = 0; index < source.length;) {
    const character = source[index];
    const nextCharacter = source[index + 1];
    if (/\s/.test(character)) {
      index += 1;
      continue;
    }
    if (character === "/" && nextCharacter === "/") {
      index = skipLineComment(source, index + 2);
      continue;
    }
    if (character === "/" && nextCharacter === "*") {
      index = skipBlockComment(source, index + 2);
      continue;
    }
    if (character === '"' || character === "'") {
      const [value, nextIndex] = readQuotedString(source, index, character);
      tokens.push({ kind: "string", value });
      index = nextIndex;
      continue;
    }
    if (character === "`") {
      index = skipQuotedValue(source, index, character);
      continue;
    }
    if (/[A-Za-z_$]/.test(character)) {
      const match = source.slice(index).match(/^[A-Za-z_$][\w$]*/);
      tokens.push({ kind: "identifier", value: match[0] });
      index += match[0].length;
      continue;
    }
    tokens.push({ kind: "punctuation", value: character });
    index += 1;
  }
  return tokens;
}

/** Read one quoted string while honoring escaped characters. */
function readQuotedString(source, start, quote) {
  let value = "";
  for (let index = start + 1; index < source.length; index += 1) {
    if (source[index] === "\\") {
      value += source[index + 1] ?? "";
      index += 1;
      continue;
    }
    if (source[index] === quote) return [value, index + 1];
    value += source[index];
  }
  return [value, source.length];
}

/** Skip a template literal that cannot contain a static import declaration. */
function skipQuotedValue(source, start, quote) {
  return readQuotedString(source, start, quote)[1];
}

/** Return the first position after a line comment. */
function skipLineComment(source, start) {
  const newlineIndex = source.indexOf("\n", start);
  return newlineIndex < 0 ? source.length : newlineIndex + 1;
}

/** Return the first position after a block comment. */
function skipBlockComment(source, start) {
  const closingIndex = source.indexOf("*/", start);
  return closingIndex < 0 ? source.length : closingIndex + 2;
}

/** Resolve supported source forms without following paths outside the workspace. */
function resolveInsideWorkspace(specifier) {
  const unresolvedPath = path.isAbsolute(specifier)
    ? specifier
    : path.resolve(workspaceRoot, specifier);
  const withoutRuntimeExtension = unresolvedPath.replace(/\.(?:js|jsx)$/, "");
  const candidates = [
    unresolvedPath,
    `${withoutRuntimeExtension}.ts`,
    `${withoutRuntimeExtension}.tsx`,
    path.join(withoutRuntimeExtension, "index.ts"),
    path.join(withoutRuntimeExtension, "index.tsx"),
  ];
  for (const candidate of candidates) {
    if (!fs.existsSync(candidate) || !fs.statSync(candidate).isFile()) continue;
    const resolvedCandidate = fs.realpathSync(candidate);
    const relativeCandidate = path.relative(workspaceRoot, resolvedCandidate);
    if (
      !relativeCandidate.startsWith("..") &&
      !path.isAbsolute(relativeCandidate)
    ) {
      return resolvedCandidate;
    }
  }
  return null;
}
