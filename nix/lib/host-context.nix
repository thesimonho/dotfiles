{
  requirementValues = {
    systems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
    operatingSystems = [
      "arch"
      "darwin"
      "fedora"
      "wsl"
    ];
    desktops = [
      "kde"
      "none"
    ];
    gpuBackends = [
      "none"
      "cuda"
      "rocm"
      "vulkan"
      "metal"
    ];
  };

  /**
    Normalize host module options into the catalog resolver's public input.
  */
  fromConfig =
    {
      config,
      pkgs,
    }:
    {
      system = pkgs.stdenv.hostPlatform.system;
      operatingSystem = config.my.os;
      desktop = config.my.desktop;
      gpuBackend = config.my.gpu.backend;
      hasDesktop = config.my.desktop != "none";
    };
}
