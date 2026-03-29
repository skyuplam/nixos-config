{
  isWSL,
  inputs,
  ...
}: {
  config,
  lib,
  pkgs,
  ...
}: let
  lock = "${pkgs.systemd}/bin/systemctl --user start screen-lock.service";
in {
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

  systemd.user.services.screen-lock = {
    Unit.Description = "Lock screen";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.noctalia-shell}/bin/noctalia-shell ipc call lockScreen lock";
    };
  };

  services = {
    swayidle = let
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
