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
  inherit (pkgs.stdenv) isLinux;
in {
  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
    };
    mimeApps = {
      enable = true;
      defaultApplications = let
        browser = ["firefox.desktop"];
        editor = ["nvim.desktop"];
        pdfViewer = ["org.pwmt.zathura.desktop"];
        videoPlayer = ["mpv.desktop"];
        imageViewer = ["imv.desktop"];
      in {
        "application/json" = browser;
        "application/pdf" = pdfViewer;

        "text/html" = browser;
        "text/xml" = browser;
        "text/plain" = editor;
        "application/xml" = browser;
        "application/xhtml+xml" = browser;
        "application/xhtml_xml" = browser;
        "application/rdf+xml" = browser;
        "application/rss+xml" = browser;
        "application/x-extension-htm" = browser;
        "application/x-extension-html" = browser;
        "application/x-extension-shtml" = browser;
        "application/x-extension-xht" = browser;
        "application/x-extension-xhtml" = browser;
        "application/x-wine-extension-ini" = editor;

        # define default applications for some url schemes.
        "x-scheme-handler/about" = browser; # open `about:` url with `browser`
        "x-scheme-handler/ftp" = browser; # open `ftp:` url with `browser`
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;

        "audio/*" = videoPlayer;
        "video/*" = videoPlayer;
        "image/*" = imageViewer;
        "image/gif" = imageViewer;
        "image/jpeg" = imageViewer;
        "image/png" = imageViewer;
        "image/webp" = imageViewer;
      };
    };
    configFile = {
      foot = {
        enable = isLinux && !isWSL;
        source = builtins.path {
          name = "foot-config";
          path = ../config/foot;
        };
      };
      ghostty = {
        enable = true;
        source = builtins.path {
          name = "ghostty-config";
          path = ../config/ghostty;
        };
      };
      swaylock = {
        enable = true;
        source = builtins.path {
          name = "swaylock-config";
          path = ../config/swaylock;
        };
      };
      niri = {
        enable = true;
        source = builtins.path {
          name = "niri";
          path = ../config/niri;
        };
      };
      # Workaround for Existing mimeapps.list file issue
      "mimeapps.list".force = true;
    };
  };

  home = {
    sessionVariables = {
      # hint Electron apps to use Wayland:
      NIXOS_OZONE_WL = "1";
      WEBKIT_DISABLE_DMABUF_RENDERER = "1";
    };

    packages = [
      pkgs.foliate
      pkgs.mesa-demos
      pkgs.grim
      pkgs.libnotify
      pkgs.libsForQt5.qt5.qtwayland
      pkgs.libusb1
      pkgs.libva-utils
      pkgs.qt6.qtwayland
      pkgs.slurp
      pkgs.sound-theme-freedesktop
      pkgs.testdisk # data recovery
      pkgs.usbutils
      pkgs.wl-clipboard
      pkgs.wl-screenrec
      pkgs.xdg-utils
      pkgs.pinentry-curses # terminal-based Pinentry
      pkgs.btop-rocm # btop with AMDGPU
    ];

    pointerCursor = {
      gtk.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Classic";
      size = 24;
    };
  };

  gtk = {
    enable = !isWSL;

    font = {
      name = "Noto Sans";
      package = pkgs.noto-fonts;
      size = 11;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      name = "Catppuccin-Mocha-Compact-Sky-Dark";
      # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/data/themes/catppuccin-gtk/default.nix
      package = pkgs.catppuccin-gtk.override {
        accents = ["sky"];
        size = "compact";
        tweaks = ["rimless" "black"];
        variant = "mocha";
      };
    };
  };

  fonts.fontconfig.enable = true;

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs = {
    fish.functions.screenrec = {
      description = "Screen Recording";
      body = ''
        set -l VIDEO "$HOME/Videos/recordings/$(date +"%Y-%m-%d_%I-%M-%S").mp4"
        ${pkgs.wl-screenrec}/bin/wl-screenrec -g $(${pkgs.slurp}/bin/slurp) -f "$VIDEO"
      '';
    };
    ghostty = {
      enable = !isWSL;
      enableFishIntegration = true;
      installBatSyntax = true;
      installVimSyntax = true;
      systemd = {
        enable = true;
      };
    };
    zathura = {
      enable = true;
      options = {
        adjust-open = "width";
        incremental-search = false;
        statusbar-home-tilde = true;
        selection-clipboard = "clipboard";
        scroll-step = 50;
      };
      extraConfig = ''
        # Theme from https://github.com/catppuccin/zathura/raw/main/src/catppuccin-mocha
        set default-fg                "#CDD6F4"
        set default-bg 			          "#1E1E2E"

        set completion-bg		          "#313244"
        set completion-fg		          "#CDD6F4"
        set completion-highlight-bg	  "#575268"
        set completion-highlight-fg	  "#CDD6F4"
        set completion-group-bg		    "#313244"
        set completion-group-fg		    "#89B4FA"

        set statusbar-fg		          "#CDD6F4"
        set statusbar-bg		          "#313244"

        set notification-bg		        "#313244"
        set notification-fg		        "#CDD6F4"
        set notification-error-bg	    "#313244"
        set notification-error-fg	    "#F38BA8"
        set notification-warning-bg	  "#313244"
        set notification-warning-fg	  "#FAE3B0"

        set inputbar-fg			          "#CDD6F4"
        set inputbar-bg 		          "#313244"

        set recolor-lightcolor		    "#1E1E2E"
        set recolor-darkcolor		      "#CDD6F4"

        set index-fg			            "#CDD6F4"
        set index-bg			            "#1E1E2E"
        set index-active-fg		        "#CDD6F4"
        set index-active-bg		        "#313244"

        set render-loading-bg		      "#1E1E2E"
        set render-loading-fg		      "#CDD6F4"

        set highlight-color		        "#575268"
        set highlight-fg              "#F5C2E7"
        set highlight-active-color	  "#F5C2E7"
      '';
    };

    imv = {
      enable = isLinux && !isWSL;
    };
    foot = {
      enable = true;
      server.enable = true;
    };
    swaylock = {
      enable = true;
    };
    firefox = {
      enable = true;
      profiles.terrencelam = {
        isDefault = true;
        settings = {
          "extensions.pocket.enabled" = false;
          "browser.crashReports.unsubmittedCheck.enabled" = false;
        };
        extraConfig = builtins.readFile (builtins.path {
          name = "userjs";
          path = ../config/user.js;
        });
      };
    };
    google-chrome = {
      enable = true;
      commandLineArgs = [
        # make it use GTK_IM_MODULE if it runs with Gtk4, so fcitx5 can work with it.
        # (only supported by chromium/chrome at this time, not electron)
        "--gtk-version=4"
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
        # make it use text-input-v1, which works for kwin 5.27 and weston
        "--enable-wayland-ime"
        # WebGPU support
        # https://github.com/gpuweb/gpuweb/wiki/Implementation-Status#chromium-chrome-edge-etc
        "--use-angle=vulkan"
        "--enable-features=Vulkan,VulkanFromANGLE"
        # "--enable-unsafe-webgpu"
      ];
    };
  };

  services = {
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      pinentry.package = pkgs.pinentry-gnome3;
      enableScDaemon = true;
      enableFishIntegration = true;
      enableSshSupport = true;
      enableExtraSocket = true;
    };

    udiskie = {
      enable = true;
    };

    mako = {
      enable = true;
    };

    wlsunset = {
      enable = true;
      latitude = "59.8";
      longitude = "10.8";
    };
    # wallpaper
    wpaperd = {
      enable = true;
      settings = {
        default = {
          path = "~/Pictures/Wallpapers/";
          duration = "30m";
        };
      };
    };
  };
}
