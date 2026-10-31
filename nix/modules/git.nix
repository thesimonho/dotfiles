{
  config,
  pkgs,
  lib,
  ...
}:

let
  selectedIdentities = config.my._identities;

  defaultName = config.my.git.defaultIdentity;
  defaultIdentity = if defaultName == null then null else selectedIdentities.${defaultName} or null;
  identitySettings = id: {
    user = {
      name = id.name;
      email = id.email;
      signingKey = id.sshPublicKey;
    };
  };

  gitIdentityFiles = lib.mapAttrs' (name: id: {
    name = "git/identity-${name}";
    value.text = lib.generators.toGitINI (
      identitySettings id
      // {
        commit.gpgSign = true;
        tag.gpgSign = true;
        gpg.format = "ssh";
      }
    );
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
  options.my.git.defaultIdentity = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Selected identity used when no remote rule matches; null requires a matching remote or repository-local identity.";
  };

  config = {
    assertions = [
      {
        assertion = defaultName == null || builtins.hasAttr defaultName selectedIdentities;
        message = "my.git.defaultIdentity must be selected in my.identities.";
      }
    ];
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
        gpg = {
          format = "ssh";
          ssh = {
            program = config.my.onepassword.signerPath;
            allowedSignersFile = "${config.xdg.configHome}/git/allowed-signers";
          };
        };
        commit.gpgSign = true;
        tag.gpgSign = true;
        user = {
          useConfigOnly = true;
        }
        // lib.optionalAttrs (defaultIdentity != null) (identitySettings defaultIdentity).user;
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

    xdg.configFile = gitIdentityFiles // {
      "git/allowed-signers".text =
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (_: id: "${id.email} ${id.sshPublicKey}") selectedIdentities
        )
        + "\n";
    };
  };
}
