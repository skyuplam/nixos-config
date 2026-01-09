{
  pkgs,
  lib,
  inputs,
  ...
}: {
  nix = {
    # use unstable nix so we can access flakes
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    registry.nixpkgs.flake = inputs.nixpkgs;
    # Optimise the Nix store automatically
    # https://nixos.wiki/wiki/Storage_optimization#Optimising_the_store
    optimise = {automatic = true;};
    # Do garbage collection weekly to keep disk usage low
    gc = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 7d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  boot = {
    # Be careful updating this.
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Set your timezone.
  time.timeZone = "Europe/Oslo";
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [libva libva-vdpau-driver libvdpau-va-gl mesa];
    };
  };

  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
  };

  # To set up Sway using Home Manager, first you must enable Polkit in your nix configuration
  security = {
    rtkit.enable = true;
    polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (
            subject.isInGroup("users")
              && (
                action.id == "org.freedesktop.login1.reboot" ||
                action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
                action.id == "org.freedesktop.login1.power-off" ||
                action.id == "org.freedesktop.login1.power-off-multiple-sessions"
              )
            )
          {
            return polkit.Result.YES;
          }
        })
      '';
    };
    pam = {
      # Inferior performance
      # https://nixos.wiki/wiki/Sway#Inferior_performance_compared_to_other_distributions
      loginLimits = [
        {
          domain = "@users";
          item = "rtprio";
          type = "-";
          value = 1;
        }
        # Set soft' and a 'hard' limit for number of files a process may have opened at a time
        # To avoid "Too many open file" error
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "65536";
        }
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = "1048576";
        }
      ];
      services = {
        swaylock = {};
        greetd.enableGnomeKeyring = true;
      };
    };
  };
  xdg = {
    portal = {
      enable = true;
      # gtk portal needed to make gtk apps happy
      extraPortals = [pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk];
      config = {
        common = {
          default = ["gtk"];
          # except for the secret portal, which is handled by gnome-keyring
          "org.freedesktop.impl.portal.Secret" = [
            "gnome-keyring"
          ];
        };
        sway = {
          default = ["wlr" "gtk"];
        };
        hyprland = {
          default = ["hyprland" "gtk"];
        };
      };
    };
  };
  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
        fcitx5-chinese-addons
      ];
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  # ];

  environment.pathsToLink = ["/share/fish"];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        StreamLocalBindUnlink = true;
        PermitRootLogin = "no";
      };
    };

    dbus = {
      enable = true;
      packages = [pkgs.gcr];
    };
    gnome.gnome-keyring.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
          user = "terrencelam";
        };
      };
    };
  };

  # Fix Systemd message & tuigreet issue https://github.com/apognu/tuigreet/issues/68
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal"; # Without this errors will spam on screen
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
