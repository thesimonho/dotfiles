{
  inputs,
  pkgsUnstable,
  system,
}:

let
  llmAgents = inputs.llm-agents.packages.${system};
in
{
  bundleNames = [
    "cli"
    "agents"
    "skills"
  ];

  /*
    Catalog of AI tools shipped as plain packages. Each entry is data only —
    bundles tag the entry; the dispatcher in default.nix turns them into
    home.packages. Tools with non-trivial setup (Claude link tree, llama-cpp
    custom build, llama-swap service) live in sibling module bodies, not here.
  */
  entries = {
    claude-code = {
      package = llmAgents.claude-code;
      bundles = [ "agents" ];
    };
    codex = {
      package = llmAgents.codex;
      bundles = [ "agents" ];
    };
    pi = {
      package = llmAgents.pi;
      bundles = [ "agents" ];
    };
    skills = {
      package = llmAgents.skills;
      bundles = [ "skills" ];
    };
    agent-browser = {
      package = llmAgents.agent-browser;
      bundles = [ "skills" ];
    };
    rtk = {
      package = llmAgents.rtk;
      bundles = [ "skills" ];
    };
    huggingface-hub = {
      package = pkgsUnstable.python3Packages.huggingface-hub;
      bundles = [ "cli" ];
    };
  };
}
