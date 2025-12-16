{ pkgs, ... }: {
  programs = {
    plasma = {
      enable = true;
      input.keyboard = {
        numlockOnStartup = "on";
        repeatDelay = 100;
        repeatRate = 60;
      };
      kwin.effects = { wobblyWindows.enable = true; };
    };
    konsole = {
      enable = true;
      defaultProfile = "zsh";
      profiles = {
        zsh = {
          command = "${pkgs.zsh}/bin/zsh";
          font.name = "Fira Code";
          font.size = 12;
          colorScheme = "Breeze";
        };
      };
    };
  };
}
