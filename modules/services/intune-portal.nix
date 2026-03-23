{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.features.intune;
in {
  options.features.intune = {
    enable = mkEnableOption "Microsoft Intune Company Portal";

    package = mkOption {
      type = types.package;
      default = pkgs.intune-portal;
      defaultText = literalExpression "pkgs.intune-portal";
      description = ''
        The Microsoft Intune Company Portal package to use.

        This defaults to our custom-built package with manual version control.
        Change the version by updating pkgs/intune-portal/default.nix and
        rebuilding the system.
      '';
      example = literalExpression "pkgs.intune-portal";
    };

    autoStart = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to automatically start the Intune Portal service on login.

        When enabled, the intune-portal service will start with the user session.
        When disabled, you must manually launch intune-portal from the application menu.
      '';
    };

    enableDesktopIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to install desktop integration files (.desktop files, system tray support).

        This makes Intune Portal available in application menus and provides
        system tray integration for enrollment status and notifications.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Install the Intune Portal package and required dependencies
    # Microsoft Edge is required for authentication workflows
    environment.systemPackages = with pkgs; [
      cfg.package
      openjdk11 # CRITICAL: OpenJDK 11 required for microsoft-identity-broker
      microsoft-edge # Required for Intune authentication workflows
      microsoft-identity-broker
    ];

    # PAM configuration for Intune authentication
    security.pam.services.intune = {
      text = ''
        auth required ${cfg.package}/lib/security/pam_intune.so
        account required ${cfg.package}/lib/security/pam_intune.so
      '';
    };

    users.users.microsoft-identity-broker = {
      group = "microsoft-identity-broker";
      isSystemUser = true;
    };
    users.groups.microsoft-identity-broker = {};

    systemd.packages = [
      pkgs.microsoft-identity-broker
      pkgs.intune-portal
    ];

    # systemd.tmpfiles.packages = [pkgs.intune-portal];
    services.dbus.packages = [pkgs.microsoft-identity-broker];

    systemd.services.intune-daemon = {
      description = "Intune daemon";
      requires = ["intune-daemon.socket"]; # Socket dependency
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/intune-daemon";
        ExecReload = "/bin/kill -HUP $MAINPID";
        StateDirectory = "intune";
        StateDirectoryMode = "0700";
      };
    };

    systemd.sockets.intune-daemon = {
      description = "Intune daemon socket";
      listenStream = "/run/intune/daemon.socket";
      socketConfig = {
        SocketMode = "0660";
      };
      wantedBy = ["sockets.target"];
    };

    systemd.user.services.intune-agent = {
      description = "Intune Agent";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cfg.package}/bin/intune-agent";
        StateDirectory = "intune";
        Slice = "background.slice";
      };
    };
    systemd.user.timers.intune-agent = {
      description = "Intune Agent scheduler";
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      wantedBy = ["graphical-session.target"];

      timerConfig = {
        AccuracySec = "2m";
        OnStartupSec = "5m";
        OnUnitActiveSec = "1h";
        RandomizedDelaySec = "10m";
      };
    };

    # Validation assertions
    assertions = [
      {
        assertion = cfg.enable -> (builtins.elem pkgs.microsoft-edge config.environment.systemPackages);
        message = ''
          features.intune.enable requires Microsoft Edge browser for authentication.
          The module automatically installs it via environment.systemPackages.
        '';
      }
    ];

    # Warnings for known issues
    warnings =
      lib.optionals cfg.enable [
        ''
          Microsoft Intune Portal officially supports GNOME desktop environment.
          If you encounter issues with other desktop environments, consider testing
          with GNOME or enabling XWayland compatibility for your compositor.
        ''
      ]
      ++ lib.optionals (cfg.enable && !cfg.autoStart) [
        ''
          Intune Portal auto-start is disabled. You will need to manually launch
          intune-portal from the application menu after system boot.
        ''
      ];
  };

  meta = {
    maintainers = with lib.maintainers; [];
  };
}
