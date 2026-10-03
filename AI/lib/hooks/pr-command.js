/** Parse simple shell command boundaries without matching quoted argument text. */
const path = require("node:path");

function commands(source) {
  const result = [];
  let words = [],
    word = "",
    started = false,
    quote = null;
  const endWord = () => {
    if (started) words.push(word);
    word = "";
    started = false;
  };
  const endCommand = () => {
    endWord();
    if (words.length) result.push(words);
    words = [];
  };
  for (let i = 0; i < source.length; i++) {
    const character = source[i];
    if (quote) {
      if (character === quote) quote = null;
      else if (
        character === "\\" &&
        quote === '"' &&
        /["\\$`\n]/.test(source[i + 1] ?? "")
      ) {
        if (source[++i] !== "\n") word += source[i];
      } else word += character;
      continue;
    }
    if (character === "'" || character === '"') {
      quote = character;
      started = true;
    } else if (character === "\\") {
      started = true;
      if (source[++i] !== "\n") word += source[i] ?? "";
    } else if (character === "#" && !started) {
      while (i < source.length && source[i] !== "\n") i++;
      endCommand();
    } else if (/[;|&\n()]/.test(character)) endCommand();
    else if (/\s/.test(character)) endWord();
    else {
      word += character;
      started = true;
    }
  }
  endCommand();
  return result;
}

function option(words, names) {
  const valueOptions = new Set([
    "--repo",
    "-R",
    "--hostname",
    "--host",
    "--config",
    "--login",
    "--head",
    "--source-branch",
    "-s",
    "--target-branch",
    "--base",
    "-B",
    "--title",
    "-t",
    "--body",
    "-b",
    "--body-file",
    "-F",
    "--description",
    "--assignee",
    "-a",
    "--label",
    "-l",
    "--milestone",
    "-m",
    "--project",
    "-p",
    "--reviewer",
    "-r",
    "--template",
    "-T",
    "--recover",
  ]);
  for (let i = 0; i < words.length; i++) {
    for (const name of names) {
      if (words[i] === name) return words[i + 1];
      if (words[i].startsWith(name + "="))
        return words[i].slice(name.length + 1);
      if (name.length === 2 && words[i].startsWith(name) && words[i].length > 2)
        return words[i].slice(2);
    }
    if (valueOptions.has(words[i])) i++;
  }
}

function pullRequestCommands(source, initialCwd) {
  let cwd = initialCwd;
  let precedingWork = false;
  const requests = [];
  for (const original of commands(source)) {
    const words = [...original];
    while (
      /^[A-Za-z_]\w*=/.test(words[0] ?? "") ||
      ["rtk", "env", "command"].includes(words[0])
    )
      words.shift();
    if (words[0] === "cd" && words.length === 2) {
      cwd = path.resolve(
        cwd,
        words[1].replace(/^~(?=\/|$)/, process.env.HOME ?? "~"),
      );
      continue;
    }
    const forge = path.basename(words.shift() ?? "");
    if (!["gh", "glab", "tea"].includes(forge)) {
      // Other work must finish before checking its resulting Git state. A push
      // is safe to combine: it doesn't change the code being assessed.
      if (!(forge === "git" && words[0] === "push")) precedingWork = true;
      continue;
    }
    const repository = option(words, ["--repo", "-R"]);
    const branch = option(words, ["--head", "--source-branch", "-s"]);
    // Global options may precede the subcommand (e.g. gh --repo owner/repo pr create).
    while (words[0]?.startsWith("-")) {
      const flag = words.shift();
      if (
        [
          "--repo",
          "-R",
          "--hostname",
          "--host",
          "--config",
          "--login",
        ].includes(flag)
      )
        words.shift();
      else if (
        !["--no-color", "--debug"].includes(flag) &&
        !flag.includes("=") &&
        !/^-[Rs].+/.test(flag)
      )
        break;
    }
    const subcommand =
      forge === "gh" ? "pr" : forge === "glab" ? "mr" : "pulls";
    if (
      (words[0] === subcommand || (forge === "tea" && words[0] === "pull")) &&
      words[1] === "create"
    ) {
      // --help describes creation without creating anything.
      if (!words.includes("--help") && !words.includes("-h"))
        requests.push({ cwd, repository, branch, precedingWork });
    } else {
      precedingWork = true;
    }
  }
  return requests;
}

module.exports = { pullRequestCommands };
