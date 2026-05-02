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

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      cudaCapabilities = [ "8.6" ];

      nixpkgsConfig =
        system:
        {
          allowUnfree = true;
        }
        // lib.optionalAttrs (system == "x86_64-linux") {
          inherit cudaCapabilities;
        };

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ ];
          config = nixpkgsConfig system;
        };

      unstableFor =
        system:
        import nixpkgs-unstable {
          inherit system;
          overlays = [ ];
          config = nixpkgsConfig system;
        };

      lib = nixpkgs.lib;
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

      homeConfigurations."home" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor "x86_64-linux";
        extraSpecialArgs = {
          inherit inputs;
          pkgsUnstable = unstableFor "x86_64-linux";
        };
        modules = [
          inputs.nix-flatpak.homeManagerModules.nix-flatpak
          inputs.plasma-manager.homeModules.plasma-manager
          agenix.homeManagerModules.default
          inputs.nix-index-database.homeModules.nix-index
          ./hosts/work.nix
          ./hosts/home.nix
          ./modules/system.nix
          ./modules/common.nix
          ./modules/kde.nix
          ./modules/secrets.nix
          ./modules/gpg.nix
          ./modules/ssh.nix
          ./modules/AI.nix
          { home.stateVersion = "25.05"; } # dont touch this
        ];
      };
      homeConfigurations."work" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor "aarch64-darwin";
        extraSpecialArgs = {
          inherit inputs;
          pkgsUnstable = unstableFor "aarch64-darwin";
        };
        modules = [
          inputs.nix-flatpak.homeManagerModules.nix-flatpak
          agenix.homeManagerModules.default
          inputs.nix-index-database.homeModules.nix-index
          ./hosts/work.nix
          ./modules/system.nix
          ./modules/common.nix
          ./modules/secrets.nix
          ./modules/gpg.nix
          ./modules/ssh.nix
          ./modules/AI.nix
          { home.stateVersion = "25.05"; } # dont touch this
        ];
      };
    };
}
