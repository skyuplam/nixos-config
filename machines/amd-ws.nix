{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware/amd-ws.nix
    ./linux-shared.nix
    ./disko-config-ws.nix
  ];

  nixpkgs.config = {
    permittedInsecurePackages = [
      "mdatp"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      # Core dependencies
      libsecret
      seahorse

      # Web authentication dependencies
      webkitgtk_6_0
      glib-networking
      gsettings-desktop-schemas

      # Credential storage
      libgnome-keyring
      xwayland-satellite
      # TLS/SSL support
      gnutls
      openssl
    ];
    # Environment variables for WebKit
    sessionVariables = {
      # GIO_EXTRA_MODULES = "${pkgs.glib-networking}/lib/gio/modules";
      GST_PLUGIN_SYSTEM_PATH_1_0 = "${pkgs.glib-networking}/lib/gio/modules";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      WEBKIT_DISABLE_COMPOSITING_MODE = "1";
    };
  };

  # Microsoft Defender for Endpoint on NixOS
  services.mdatp = {
    enable = true;
    onboardingFile = "/etc/opt/microsoft/mdatp/_mdatp_onboard.json";
    managedSettings = {
      antivirusEngine = {
        enforcementLevel = "real_time";
      };
      cloudService = {
        enabled = true;
        automaticSampleSubmissionConsent = "none";
        automaticDefinitionUpdateEnabled = true;
      };
      networkProtection = {
        enforcementLevel = "block";
      };
    };
  };

  # Make sure systemd machine-id is available
  systemd.services.systemd-machine-id-setup = {
    enable = true;
  };

  programs.seahorse.enable = true;
  # Microsoft Intune Company Portal (custom package with version control)
  services.intune.enable = true;

  # Enable necessary authentication services
  services.gnome.gnome-keyring.enable = true;
  # Enable D-Bus (required for broker authentication)
  services.dbus.enable = true;
  # Enable secret service for credential storage
  security.pam.services.login.enableGnomeKeyring = true;
  # Ensure system-wide GIO modules
  services.gvfs.enable = true;
  # SSL/TLS certificates
  security.pki.certificateFiles = [
    "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
  ];
  # add licence for microsoft defender
  environment.etc = {
    "opt/microsoft/mdatp/_mdatp_onboard.json" = {
      source = inputs.nix-secrets.mdatpLicence.source;
      mode = "0600";
      user = "root";
      group = "root";
    };
  };

  services.upower = {
    enable = true;
  };

  boot = {
    # This is not a complete NixOS configuration and you need to reference
    # your normal configuration here.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    initrd.systemd.enable = true;
  };

  fonts = {
    # use fonts specified by user rather than default ones
    enableDefaultPackages = false;
    fontDir.enable = true;

    packages = with pkgs; [
      # icon fonts
      dejavu_fonts
      font-awesome
      material-design-icons
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      noto-fonts-color-emoji
      source-han-sans
      source-han-serif
      source-sans
      source-serif
    ];
    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig.defaultFonts = {
      serif = ["Source Han Serif TC" "Noto Color Emoji"];
      sansSerif = ["Source Han Sans TC" "Noto Color Emoji"];
      monospace = ["JetBrainsMono Nerd Font" "Noto Color Emoji"];
      emoji = ["Noto Color Emoji"];
    };
  };

  networking.hostName = "tlamws";
  networking.firewall = {
    allowedUDPPorts = [inputs.nix-secrets.networking.wireguard.wg0.listenPort];
    # NixOS firewall will block wg traffic because of rpfilter
    checkReversePath = "loose";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
