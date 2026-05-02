{
  config,
  pkgs,
  lib,
  ...
}:

let
  meta = import ../secrets/meta.nix;
  selectedIdentities = lib.filterAttrs (name: _: lib.elem name config.my.identities) meta.identities;

  # Generate git identity config files from selected identities
  gitIdentityFiles = lib.mapAttrs' (name: id: {
    name = "git/identity-${name}";
    value = {
      text = ''
        [user]
          email = ${id.email}
      ''
      + lib.optionalString (id.gpg != null && id.gpg.sign) ''
          signingKey = ${id.gpg.keyId}
        [commit]
          gpgSign = true
        [tag]
          gpgSign = true
      '';
    };
  }) selectedIdentities;

  # Generate includeIf rules that route git identity based on remote URL
  # Each identity can have multiple patterns (SSH and HTTPS)
  gitIncludes = lib.concatLists (
    lib.mapAttrsToList (
      name: id:
      map (pattern: {
        condition = "hasconfig:remote.*.url:${pattern}";
        path = "${config.xdg.configHome}/git/identity-${name}";
      }) id.remotePatterns
    ) selectedIdentities
  );
in
{
  programs.git = {
    enable = true;
    lfs = {
      enable = true;
    };
    maintenance = {
      enable = true;
    };
    includes = gitIncludes;
    settings = {
      user = {
        name = "Simon Ho";
      };
      init = {
        defaultBranch = "main";
      };
      core = {
        autocrlf = "input";
      };
      rerere = {
        enabled = true;
      };
      column = {
        ui = "auto";
      };
      branch = {
        sort = "-committerdate";
      };
      fetch = {
        writeCommitGraph = true;
      };
      merge = {
        conflictStyle = "zdiff3";
      };
      credential = {
        helper = "${pkgs.gh}/bin/gh auth git-credential";
        useHttpPath = true;
      };
    };
  };

  xdg.configFile = gitIdentityFiles;
}
