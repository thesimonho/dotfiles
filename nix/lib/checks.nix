{
  lib,
  inputs,
  home-manager,
  sharedModules,
  pkgsFor,
  unstableFor,
  pinnedFor,
}:

let
  catalogLib = import ./catalog.nix { inherit lib; };
  hostContextLib = import ./host-context.nix;

  /*
    Build a home-manager configuration from inline modules. Mirrors mkHost
    in flake.nix but takes modules directly instead of reading hosts/<name>.nix.
  */
  mkSyntheticHost =
    {
      system,
      name,
      modules,
    }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor {
        inherit system;
        hostName = name;
      };
      extraSpecialArgs = {
        inherit inputs;
        pkgsUnstable = unstableFor {
          inherit system;
          hostName = name;
        };
        pkgsPinned = pinnedFor {
          inherit system;
          hostName = name;
        };
      };
      modules = sharedModules ++ modules;
    };

  /*
    Eval-only check derivation. Forces module evaluation (which triggers
    type checks like enum-on-bundles and the catalog-shape assertion) by
    serializing a digest of the resolved config. Does not build home.packages,
    just reads their names.
  */
  mkEvalCheck =
    system: hmConfig:
    let
      pkgs = pkgsFor {
        inherit system;
        hostName = "_check";
      };
      failed = builtins.filter (a: !a.assertion) hmConfig.config.assertions;
      digest = builtins.toJSON {
        packages = map (p: p.pname or p.name or "anon") hmConfig.config.home.packages;
        files = builtins.attrNames hmConfig.config.home.file;
        activation = builtins.attrNames hmConfig.config.home.activation;
      };
    in
    if failed != [ ] then
      throw "Assertions failed:\n  - ${lib.concatStringsSep "\n  - " (map (a: a.message) failed)}"
    else
      pkgs.writeText "eval-check.json" digest;

  /*
    Exercise catalog selection through its public interface. This keeps host
    applicability and rejected-entry diagnostics stable independently of any
    one domain dispatcher.
  */
  mkCatalogEngineCheck =
    system:
    let
      pkgs = pkgsFor {
        inherit system;
        hostName = "_catalog-check";
      };
      result = catalogLib.resolveCatalog {
        catalog.desktop = {
          bundles = [ "agents" ];
          requirements = {
            systems = [ "x86_64-linux" ];
            operatingSystems = [ ];
            desktops = [ ];
            hasDesktop = true;
            gpuBackends = [ ];
          };
        };
        bundles = [ "agents" ];
        enabled = [ ];
        hostContext = {
          inherit system;
          operatingSystem = "arch";
          desktop = "none";
          gpuBackend = "none";
          hasDesktop = false;
        };
      };
      digest = builtins.toJSON {
        applicable = builtins.attrNames result.applicableEntries;
        rejected = result.rejectedEntries.desktop.reasons;
      };
    in
    assert result.applicableEntries == { };
    assert result.rejectedEntries.desktop.reasons == [ "requires hasDesktop=true" ];
    pkgs.writeText "catalog-engine-check.json" digest;

  # Verify the shared requirement enums reject undeclared host identities.
  mkCatalogTypeCheck =
    system:
    let
      pkgs = pkgsFor {
        inherit system;
        hostName = "_catalog-type-check";
      };
      catalogType = catalogLib.mkCatalogType {
        bundleNames = [ "test" ];
        inherit (hostContextLib) requirementValues;
      };
      invalidCatalogEvaluation = builtins.tryEval (
        builtins.deepSeq
          (lib.evalModules {
            modules = [
              {
                options.catalog = lib.mkOption { type = catalogType; };
                config.catalog.invalid.requirements.operatingSystems = [ "undeclared-os" ];
              }
            ];
          }).config.catalog
          true
      );
    in
    assert !invalidCatalogEvaluation.success;
    pkgs.writeText "catalog-type-check.json" (builtins.toJSON { rejectsUnknownHostValues = true; });

  mkChatgptCheck =
    {
      system,
      hmConfig,
      expected,
    }:
    let
      pkgs = pkgsFor {
        inherit system;
        hostName = "_chatgpt-check";
      };
      actual = builtins.hasAttr "ai.chatgpt" hmConfig.config.my.nativePackages.catalog;
    in
    assert actual == expected;
    pkgs.writeText "chatgpt-check.json" (builtins.toJSON { inherit actual expected; });

  # Authentication contracts are module evaluations, not unit tests. Check
  # native/rollback branches plus hosts with no identities through HM itself.
  mkAuthCheck =
    system: hmConfig:
    let
      c = hmConfig.config;
      linux = c.my.os != "darwin";
      wsl = c.my.os == "wsl";
      native = c.my.os == "arch" && c.my.desktop == "kde" && c.my.kdeNativeAuth;
      ids = c.my._identities;
      signing = lib.filterAttrs (_: id: id.gpg != null && (id.gpg.sign or false)) ids;
      services = c.systemd.user.services;
      hasLoader = services ? ssh-add-keys;
      hasPreset = services ? gpg-preset-passphrases;
      packages = map (p: p.pname or p.name or "") c.home.packages;
      legacy = [
        "secret-askpass"
        "ssh-add-keys"
        "ssh-keys"
        "gpg-preset"
        "gpg-preset-driver"
        "gpg-keys"
      ];
      ssh = c.programs.ssh.settings;
      checkIdentity =
        name: id:
        let
          secret = c.age.secrets."identity-ssh-${name}";
        in
        secret.path == "${c.home.homeDirectory}/.ssh/${id.sshKeyFile}"
        && secret.mode == "600"
        && !secret.symlink
        && ssh.${id.sshHost}.data.IdentityFile == secret.path
        && ssh.${id.sshHost}.data.HostName == id.sshProxyHost
        && ssh.${id.sshHost}.data.Port == id.sshPort
        && ssh.${id.sshHost}.data.ForwardAgent
        && c.xdg.configFile."git/identity-${name}".text != "";
      pkgs = pkgsFor {
        inherit system;
        hostName = "_auth-check";
      };
    in
    assert hasLoader == (linux && !wsl && ids != { });
    assert hasPreset == (linux && !wsl && !native && signing != { });
    assert (services ? ssh-agent) == linux;
    assert !(c.systemd.user.sockets ? ssh-agent);
    assert !c.services.gpg-agent.enableSshSupport;
    assert lib.all (name: checkIdentity name ids.${name}) (builtins.attrNames ids);
    assert !(ssh ? "*"); # No untested Apple-specific settings on any host.
    assert
      !native
      || (
        lib.all (name: !(lib.elem name packages)) legacy
        && c.services.gpg-agent.pinentry.package == null
        && c.services.gpg-agent.extraConfig == "pinentry-program /usr/bin/pinentry-qt"
        && lib.elem "PINENTRY_KDE_USE_WALLET=1" services.gpg-agent.Service.Environment
        && lib.hasInfix "SSH_ASKPASS=/usr/bin/ksshaskpass" c.xdg.configFile."environment.d/ssh.conf".text
        && builtins.hasAttr "apps.kde-authentication" c.my.nativePackages.catalog
      );
    assert
      !wsl
      || (
        lib.elem "gpg-preset-driver" packages
        && lib.elem "secret-askpass" packages
        && c.home.sessionVariables.SSH_AUTH_SOCK == "$XDG_RUNTIME_DIR/ssh-agent.socket"
      );
    assert
      linux
      || (
        c.services.gpg-agent.pinentry.package.pname == "pinentry-mac"
        && lib.all (name: !(lib.elem name packages)) legacy
      );
    pkgs.writeText "authentication-check.json" (
      builtins.toJSON {
        inherit native hasLoader hasPreset;
        identities = builtins.attrNames ids;
      }
    );

  kdeVariant =
    native: identities:
    mkSyntheticHost {
      system = "x86_64-linux";
      name = "auth-kde";
      modules = [
        {
          my = {
            hostName = "auth-kde";
            os = "arch";
            desktop = "kde";
            kdeNativeAuth = native;
            inherit identities;
            apps.bundles = [ "security" ];
          };
          home = {
            username = "test";
            homeDirectory = "/home/test";
          };
        }
      ];
    };

  /*
    Synthetic host that enables every bundle. Catches catalog entries whose
    tagged bundle no real host happens to enable. Keep `apps.bundles` /
    `ai.bundles` in sync with the bundleNames lists in their catalogs.
  */
  kitchenSinkLinux = mkSyntheticHost {
    system = "x86_64-linux";
    name = "kitchen-sink";
    modules = [
      {
        my = {
          hostName = "kitchen-sink";
          os = "arch";
          desktop = "none";
          gpu.backend = "none";
          apps.bundles = [
            "cli"
            "security"
            "fonts"
            "communication"
            "dev"
            "cloud"
          ];
          ai.bundles = [
            "cli"
            "agents"
            "skills"
          ];
        };
        home = {
          username = "test";
          homeDirectory = "/home/test";
        };
      }
    ];
  };
in
{
  /*
    Build the `checks.<system>` attrset for `nix flake check`. Pass in the
    real homeConfigurations so each gets an eval-only check derivation.
  */
  mkChecks = homeConfigurations: {
    x86_64-linux = {
      auth-desktop = mkAuthCheck "x86_64-linux" homeConfigurations.desktop;
      auth-wsl = mkAuthCheck "x86_64-linux" homeConfigurations.work-wsl;
      auth-rollback = mkAuthCheck "x86_64-linux" (kdeVariant false [ "personal" ]);
      auth-empty = mkAuthCheck "x86_64-linux" (kdeVariant true [ ]);
      auth-other-linux = mkAuthCheck "x86_64-linux" kitchenSinkLinux;
      catalog-engine = mkCatalogEngineCheck "x86_64-linux";
      catalog-types = mkCatalogTypeCheck "x86_64-linux";
      chatgpt = mkChatgptCheck {
        system = "x86_64-linux";
        hmConfig = homeConfigurations.desktop;
        expected = true;
      };
      chatgpt-wsl = mkChatgptCheck {
        system = "x86_64-linux";
        hmConfig = homeConfigurations.work-wsl;
        expected = false;
      };
      desktop = mkEvalCheck "x86_64-linux" homeConfigurations.desktop;
      work-wsl = mkEvalCheck "x86_64-linux" homeConfigurations.work-wsl;
      kitchen-sink = mkEvalCheck "x86_64-linux" kitchenSinkLinux;
    };
    aarch64-darwin = {
      auth-mac = mkAuthCheck "aarch64-darwin" homeConfigurations.work-macbook;
      chatgpt = mkChatgptCheck {
        system = "aarch64-darwin";
        hmConfig = homeConfigurations.work-macbook;
        expected = true;
      };
      work-macbook = mkEvalCheck "aarch64-darwin" homeConfigurations.work-macbook;
    };
  };
}
