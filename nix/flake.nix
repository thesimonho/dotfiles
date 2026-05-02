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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    llm-agents.url = "github:numtide/llm-agents.nix";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{
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

      lib = nixpkgs.lib;

      # Modules every host imports unconditionally. Each one is a no-op
      # until its host opts in via my.* options.
      sharedModules = [
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        inputs.plasma-manager.homeModules.plasma-manager
        agenix.homeManagerModules.default
        inputs.nix-index-database.homeModules.nix-index
        ./modules/system.nix
        ./modules/apps.nix
        ./modules/common.nix
        ./modules/git.nix
        ./modules/mise.nix
        ./modules/yazi.nix
        ./modules/nvim.nix
        ./modules/kde.nix
        ./modules/secrets.nix
        ./modules/gpg.nix
        ./modules/ssh.nix
        ./modules/ai
        { home.stateVersion = "25.05"; } # dont touch this
      ];
    in
    {
      apps.x86_64-linux.hm = {
        type = "app";
        program = "${home-manager.packages.x86_64-linux.home-manager}/bin/home-manager";
      };
      apps.aarch64-darwin.hm = {
        type = "app";
        program = "${home-manager.packages.aarch64-darwin.home-manager}/bin/home-manager";
      };

      homeConfigurations."desktop" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor {
          system = "x86_64-linux";
          hostName = "desktop";
        };
        extraSpecialArgs = {
          inherit inputs;
          pkgsUnstable = unstableFor {
            system = "x86_64-linux";
            hostName = "desktop";
          };
        };
        modules = sharedModules ++ [
          ./hosts/work-macbook.nix
          ./hosts/desktop.nix
        ];
      };
      homeConfigurations."work-macbook" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor {
          system = "aarch64-darwin";
          hostName = "work-macbook";
        };
        extraSpecialArgs = {
          inherit inputs;
          pkgsUnstable = unstableFor {
            system = "aarch64-darwin";
            hostName = "work-macbook";
          };
        };
        modules = sharedModules ++ [
          ./hosts/work-macbook.nix
        ];
      };
    };
}
