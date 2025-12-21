{ pkgs, ... }: {
  programs = {
    plasma = {
      enable = true;
      input.keyboard = {
        numlockOnStartup = "on";
        repeatDelay = 400;
        repeatRate = 25;
      };
      kwin.effects = { wobblyWindows.enable = true; };
      panels = [{
        floating = true;
        location = "bottom";
        opacity = "translucent";
        screen = "all";
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.pager"
          "org.kde.plasma.taskmanager"
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemmonitor.cpu"
          "org.kde.plasma.systemmonitor.memory"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }];
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
