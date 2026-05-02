{
  inputs,
  pkgsUnstable,
  system,
}:

let
  llmAgents = inputs.llm-agents.packages.${system};
in
{
  /*
    Catalog of AI tools shipped as plain packages. Each entry is data only —
    bundles tag the entry; the dispatcher in default.nix turns them into
    home.packages. Tools with non-trivial setup (Claude link tree, llama-cpp
    custom build, llama-swap service) live in sibling module bodies, not here.
  */
  claude-code = {
    package = llmAgents.claude-code;
    bundles = [ "cli-agents" ];
  };
  codex = {
    package = llmAgents.codex;
    bundles = [ "cli-agents" ];
  };
  pi = {
    package = llmAgents.pi;
    bundles = [ "cli-agents" ];
  };
  skills = {
    package = llmAgents.skills;
    bundles = [ "cli-agents" ];
  };
  agent-browser = {
    package = llmAgents.agent-browser;
    bundles = [ "tooling" ];
  };
  rtk = {
    package = llmAgents.rtk;
    bundles = [ "tooling" ];
  };
  huggingface-hub = {
    package = pkgsUnstable.python3Packages.huggingface-hub;
    bundles = [ "tooling" ];
  };
}
