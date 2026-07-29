{
  description = "Cross-platform config using Home Manager (Linux/macOS)";

  nixConfig = {
    max-jobs = "auto";
    cores = 0;
    download-buffer-size = 128;
    connect-timeout = 60;
    stalled-download-timeout = 300;
    warn-dirty = false;

    extra-substituters = [
      "https://cache.numtide.com"
      "https://cuda-maintainers.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Frozen nixpkgs for heavy rebuilds (llama-cpp, ffmpeg). Excluded from
    # `just update`; bump explicitly with `just update-pinned`.
    #
    # A release channel is no longer usable here: nixos-26.05 froze llama-cpp
    # at b9190 (2026-05-16), which predates the Mellum architecture landing in
    # llama.cpp at ~b9485 (2026-06-02), so Tabby's darwin completion server
    # cannot load Mellum2. Naming the `nixpkgs-unstable` branch instead is the
    # obvious move and the wrong one — it is the same ref as the input above,
    # but resolves to a *separate* lock node, so the two drift into different
    # checkouts of one branch as `just update` and `just update-pinned` bump
    # them at different times, and nothing stays frozen.
    #
    # So pin the revision. The constraint the old comment was reaching for is
    # about which commit, not how it is named: a raw master commit has no
    # darwin builds and forces local recompiles through flaky test phases,
    # whereas a commit the `nixpkgs-unstable` branch actually pointed at is
    # Hydra-built by definition. Evaluation is identical either way for the
    # same rev, so naming it by SHA costs nothing and buys an immovable pin.
    # `just update-pinned` advances this to the current channel tip; do not
    # hand-edit it to an arbitrary master SHA.
    nixpkgs-pinned.url = "github:NixOS/nixpkgs/38a4887411571457d700c51c64a6e49ead2ed5ab";
    # Workaround pin for tabby only: 26.05 and unstable rustc reject its
    # vendored metrics-0.22.3 crate (rust-lang/rust#141402), and 25.11 is the
    # newest channel with a Hydra-cached aarch64-darwin binary.
    # TODO: (late 2026) once nixpkgs PR #485360 (tabby 0.28.0 -> 0.32.0) lands
    # in unstable, point the AI catalog's tabby entry back at pkgsUnstable,
    # delete this input, and remove it from PINNED in the justfile.
    nixpkgs-tabby.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    llm-agents.url = "github:numtide/llm-agents.nix";

    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Claude Desktop with the Cowork VM backend wired up (firmware/virtiofsd
    # paths patched for non-Debian distros). numtide/llm-agents ships the same
    # upstream binary but without this, so Cowork can't find OVMF on Arch.
    claude-desktop-bin = {
      url = "github:patrickjaja/claude-desktop-bin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      agenix,
      ...
    }:
    let
      # CUDA: narrow to the actual GPU's compute capability so CUDA-using
      # packages don't compile for ~7 archs. UPDATE ON GPU UPGRADE.
      # Reference (consumer NVIDIA):
      #   Ampere     RTX 30xx / A-series        "8.6"
      #   Ada        RTX 40xx                   "8.9"
      #   Hopper     H100                       "9.0"
      #   Blackwell  RTX 50xx                   "12.0"
      # Full list: https://developer.nvidia.com/cuda-gpus
      #
      # Module evaluation can't feed into pkgs (pkgs is constructed before
      # modules evaluate), so capabilities live here keyed by host name.
      hostCudaCapabilities = {
        desktop = [ "8.6" ];
      };

      nixpkgsConfig =
        hostName:
        {
          allowUnfree = true;
        }
        // lib.optionalAttrs (hostCudaCapabilities ? ${hostName}) {
          cudaCapabilities = hostCudaCapabilities.${hostName};
        };

      pkgsFor =
        {
          system,
          hostName,
        }:
        import nixpkgs {
          inherit system;
          overlays = [ ];
          config = nixpkgsConfig hostName;
        };

      unstableFor =
        {
          system,
          hostName,
        }:
        import nixpkgs-unstable {
          inherit system;
          overlays = [ ];
          config = nixpkgsConfig hostName;
        };

      pinnedFor =
        {
          system,
          hostName,
        }:
        import inputs.nixpkgs-pinned {
          inherit system;
          overlays = [ ];
          config = nixpkgsConfig hostName;
        };

      lib = nixpkgs.lib;

      # Modules every host imports unconditionally. Each one is a no-op
      # until its host opts in via my.* options.
      sharedModules = [
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        inputs.nix-index-database.homeModules.nix-index
        inputs.codex-desktop-linux.homeManagerModules.default
        agenix.homeManagerModules.default
        ./modules/system.nix
        ./modules/apps
        ./modules/common.nix
        ./modules/zsh.nix
        ./modules/git.nix
        ./modules/mise.nix
        ./modules/yazi.nix
        ./modules/nvim.nix
        ./modules/kde.nix
        ./modules/secrets.nix
        ./modules/gpg.nix
        ./modules/ssh.nix
        ./modules/wsl.nix
        ./modules/ai
        { home.stateVersion = "25.05"; } # dont touch this
      ];
      mkHost =
        { name, system }:
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
          modules = sharedModules ++ [
            ./hosts/${name}.nix
            { my.hostName = name; }
          ];
        };

      checksLib = import ./lib/checks.nix {
        inherit
          lib
          inputs
          home-manager
          sharedModules
          pkgsFor
          unstableFor
          pinnedFor
          ;
      };
    in
    {
      apps.x86_64-linux.hm = {
        type = "app";
        program = "${home-manager.packages.x86_64-linux.home-manager}/bin/home-manager";
        meta.description = "Home Manager CLI";
      };
      apps.aarch64-darwin.hm = {
        type = "app";
        program = "${home-manager.packages.aarch64-darwin.home-manager}/bin/home-manager";
        meta.description = "Home Manager CLI";
      };

      # List of available hosts
      homeConfigurations.desktop = mkHost {
        name = "desktop";
        system = "x86_64-linux";
      };
      homeConfigurations.work-macbook = mkHost {
        name = "work-macbook";
        system = "aarch64-darwin";
      };
      homeConfigurations.work-wsl = mkHost {
        name = "work-wsl";
        system = "x86_64-linux";
      };

      # `nix flake check` entries. Eval-only — forces module evaluation
      # (catches bundle-rename mistakes, enum violations, failed assertions)
      # without building heavy derivations like llama-cpp.
      checks = checksLib.mkChecks self.homeConfigurations;
    };
}
