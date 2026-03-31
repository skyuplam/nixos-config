{
  isWSL,
  inputs,
  ...
}: {
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    (import ./linux-desktop.nix {
      inherit inputs;
      inherit isWSL;
    })
  ];

  home = {
    # This value determines the Home Manager release that your configuration is compatible with. This
    # helps avoid breakage when a new Home Manager release introduces backwards incompatible changes.
    #
    # You can update Home Manager without changing this value. See the Home Manager release notes for
    # a list of state version changes in each release.
    stateVersion = "26.05";
  };

  xdg.configFile.kanata = {
    enable = true;
    source = builtins.path {
      name = "kanata-config";
      path = ../config/kanata;
    };
  };

  services = {
    swayidle = let
      lock = "${config.programs.noctalia-shell.package}/bin/noctalia-shell ipc call lockScreen lock";
      display = status: "${pkgs.niri}/bin/niri msg action power-${status}-monitors";
    in {
      enable = true;
      timeouts = [
        {
          timeout = 20;
          command = lock;
        }
        {
          timeout = 180;
          command = display "off";
          resumeCommand = display "on";
        }
        {
          timeout = 300;
          command = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
        }
      ];
      events = {
        after-resume = display "on";
        before-sleep = (display "off") + "; " + lock;
        lock = lock;
        unlock = display "on";
      };
    };
  };
}
