{
  config,
  pkgs,
  pkgsUnstable,
  lib,
  ...
}:

let
  dotfiles = config.my.dotfilesPath;
  gpuBackend = config.my.gpu.backend;
  enabled = gpuBackend != "none";

  # GGUF repos that ship a vision projector (mmproj-F16.gguf).
  # Downloaded idempotently during activation so --mmproj paths in
  # llama-swap.yaml resolve without manual intervention.
  mmprojRepos = [
    "Qwen3.5-9B-GGUF"
    "Qwen3.6-27B-GGUF"
    "Qwen3.6-35B-A3B-GGUF"
  ];

  # Path to host NVIDIA driver lib on non-NixOS (CachyOS, Arch, etc).
  # Used to LD_PRELOAD libcuda.so.1 so the nix-built llama-cpp can find it
  # without polluting LD_LIBRARY_PATH (which would break BLAS linkage).
  hostCudaDriver = "/usr/lib/libcuda.so.1";

  llamaCppPackage =
    (pkgsUnstable.llama-cpp.override {
      blasSupport = true;
      cudaSupport = gpuBackend == "cuda";
      rocmSupport = gpuBackend == "rocm";
      vulkanSupport = gpuBackend == "vulkan";
      metalSupport = gpuBackend == "metal";
    }).overrideAttrs
      (oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgsUnstable.makeWrapper ];
        cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [ "-DGGML_NATIVE=ON" ];
        preConfigure = ''
          export NIX_ENFORCE_NO_NATIVE=0
          ${oldAttrs.preConfigure or ""}
        '';
        postFixup =
          (oldAttrs.postFixup or "")
          + lib.optionalString (gpuBackend == "cuda") ''
            for bin in $out/bin/*; do
              if [ -f "$bin" ] && [ -x "$bin" ]; then
                wrapProgram "$bin" --prefix LD_PRELOAD : ${hostCudaDriver}
              fi
            done
          '';
      });
in
lib.mkIf enabled {
  home.packages = [
    llamaCppPackage
    pkgsUnstable.llama-swap
  ];

  systemd.user.services.llama-swap = {
    Unit = {
      Description = "llama-swap - OpenAI-compatible proxy with model swapping";
      After = [ "network.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "simple";
      Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
      ExecStart = "${pkgsUnstable.llama-swap}/bin/llama-swap --config ${dotfiles}/AI/settings/llama-swap.yaml --listen 127.0.0.1:9292 --watch-config";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  home.activation.downloadMmprojFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for repo in ${lib.concatStringsSep " " mmprojRepos}; do
      target="$HOME/.cache/llama.cpp/$repo/mmproj-F16.gguf"
      if [ ! -f "$target" ]; then
        echo "==> Downloading mmproj for $repo"
        $DRY_RUN_CMD ${pkgsUnstable.python3Packages.huggingface-hub}/bin/hf download \
          "unsloth/$repo" \
          --include "mmproj-F16.gguf" \
          --local-dir "$HOME/.cache/llama.cpp/$repo" || \
          echo "  WARN: failed to download mmproj for $repo (continuing)"
      fi
    done
  '';
}
