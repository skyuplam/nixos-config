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
    stateVersion = "26.05";
  };

  xdg.configFile.kanata = {
    enable = true;
    source = builtins.path {
      name = "kanata-config";
      path = ../config/kanata;
    };
  };

  systemd.user.services.swayidle = {
    Unit = {
      Description = "swayidle (custom)";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };

    Service = {
      Type = "simple";
      # explicit env
      Environment = [
        "QS_CONFIG_PATH=${noctaliaPkg}/share/noctalia-shell"
        "PATH=/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
      ];
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
          timeout 20 '${lockScript}' \
          timeout 180 '${powerOff}' \
                    resume '${powerOn}' \
          timeout 300 '${pkgs.systemd}/bin/systemctl sleep' \
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
}
