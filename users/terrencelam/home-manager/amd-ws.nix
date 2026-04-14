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
  noctaliaPkg = config.programs.noctalia-shell.package;
  noctaliaBin = "${noctaliaPkg}/bin/noctalia-shell";
  niriBin = "${pkgs.niri}/bin/niri";

  lockScript = pkgs.writeShellScript "lock-noctalia" ''
    export QS_CONFIG_PATH="${noctaliaPkg}/share/noctalia-shell"
    for i in $(seq 1 8); do
      ${noctaliaBin} ipc call lockScreen lock && exit 0
      sleep 0.25
    done
    exit 1
  '';

  powerOff = pkgs.writeShellScript "niri-display-off" ''
    ${niriBin} msg action power-off-monitors
  '';

  powerOn = pkgs.writeShellScript "niri-display-on" ''
    ${niriBin} msg action power-on-monitors
  '';
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
    stateVersion = "25.11";
  };

  systemd.user.services.swayidle = {
    Unit = {
      Description = "swayidle (custom)";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };

    Service = {
      Type = "simple";
      # explicit env
      Environment = [
        "QS_CONFIG_PATH=${noctaliaPkg}/share/noctalia-shell"
        "PATH=/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
      ];
      # Pull in the graphical session environment (WAYLAND_DISPLAY, XDG_RUNTIME_DIR, etc.)
      PassEnvironment = "WAYLAND_DISPLAY XDG_RUNTIME_DIR";
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          timeout 20 '${lockScript}' \
          timeout 180 '${powerOff}' \
                    resume '${powerOn}' \
          before-sleep '${lockScript}' \
          lock '${lockScript}' \
          unlock '${powerOn}' \
          after-resume '${powerOn}'
      '';
      Restart = "on-failure";
      RestartSec = 1;
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  services = {
    swayidle = let
      lock = "${config.programs.noctalia-shell.package}/bin/noctalia-shell ipc call lockScreen lock";
      display = status: "${pkgs.niri}/bin/niri msg action power-${status}-monitors";
    in {
      enable = false;
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
