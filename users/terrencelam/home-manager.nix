{
  isWSL,
  inputs,
  ...
}: {
  config,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin isLinux;
in {
  imports = [
    ./programs
  ];

  xdg = {
    enable = true;
    userDirs = {
      enable = isLinux && !isWSL;
      createDirectories = true;
    };
    # manage $XDG_CONFIG_HOME/mimeapps.list
    # xdg search all desktop entries from $XDG_DATA_DIRS, check it by command:
    #  echo $XDG_DATA_DIRS
    # the system-level desktop entries can be list by command:
    #   ls -l /run/current-system/sw/share/applications/
    # the user-level desktop entries can be list by command(user ryan):
    #  ls /etc/profiles/per-user/terrencelam/share/applications/
    mimeApps = {
      enable = isLinux && !isWSL;
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
    configFile =
      {
        git = {
          enable = true;
          source = builtins.path {
            name = "git-config";
            path = ./config/git;
          };
        };
        tig = {
          enable = true;
          source = builtins.path {
            name = "tig-config";
            path = ./config/tig;
          };
        };
        zellij = {
          enable = true;
          source = builtins.path {
            name = "zellij-config";
            path = ./config/zellij;
          };
        };
        tridactyl = {
          enable = true;
          source = builtins.path {
            name = "tridactyl-config";
            path = ./config/tridactyl;
          };
        };
        foot = {
          enable = isLinux && !isWSL;
          source = builtins.path {
            name = "foot-config";
            path = ./config/foot;
          };
        };
        wezterm = {
          enable = isDarwin;
          source = builtins.path {
            name = "wezterm-config";
            path = ./config/wezterm;
          };
        };
        ghostty = {
          enable = true;
          source = builtins.path {
            name = "ghostty-config";
            path = ./config/ghostty;
          };
        };
        swaylock = {
          enable = true;
          source = builtins.path {
            name = "swaylock-config";
            path = ./config/swaylock;
          };
        };
        mpv = {
          enable = true;
          source = builtins.path {
            name = "mpv";
            path = ./config/mpv;
          };
        };
      }
      // lib.optionalAttrs isDarwin {
        skhd = {
          enable = true;
          source = builtins.path {
            name = "skhd-config";
            path = ./config/skhd;
          };
        };
      }
      // lib.optionalAttrs (isLinux && !isWSL) {
        # Workaround for Existing mimeapps.list file issue
        "mimeapps.list".force = true;
      };
  };

  home =
    {
      # This value determines the Home Manager release that your configuration is compatible with. This
      # helps avoid breakage when a new Home Manager release introduces backwards incompatible changes.
      #
      # You can update Home Manager without changing this value. See the Home Manager release notes for
      # a list of state version changes in each release.
      stateVersion = "23.11";

      sessionVariables = {
        LANG = "en_US.UTF-8";
        LC_CTYPE = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
        PAGER = "less -FirSwX";
        VISUAL = "$EDITOR";
        GIT_EDITOR = "$EDITOR";
        MANPAGER = "$EDITOR +Man!";
        SQLITE_CLIB_PATH = "${pkgs.sqlite.out}/lib/libsqlite3.${
          if isDarwin
          then "dylib"
          else "so"
        }";
        COPILOT_PATH = "${pkgs.copilot-language-server}/bin/copilot-language-server";
        # Failed to build target aarch64-darwin
        VSCODE_LLDB_PATH =
          if isDarwin
          then ""
          else "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/";
      };

      file =
        {
          ".inputrc".source = builtins.path {
            name = "inputrc-config";
            path = ./config/inputrc;
          };
          "biome.json".text = builtins.toJSON {
            formatter = {
              enabled = true;
              indentStyle = "space";
            };
          };
        }
        // lib.optionalAttrs (isLinux && !isWSL) {
          ".mozilla/native-messaging-hosts/tridactyl.json".source = "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";
          ".mozilla/native-messaging-hosts/passff.json".source = "${pkgs.passff-host}/lib/mozilla/native-messaging-hosts/passff.json";
          ".mozilla/native-messaging-hosts/ff2mpv.json".source = "${pkgs.ff2mpv}/lib/mozilla/native-messaging-hosts/ff2mpv.json";
        }
        // lib.optionalAttrs isDarwin {
          "Library/Application Support/Firefox/NativeMessagingHosts/tridactyl.json".source = "${pkgs.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";
          "Library/Application Support/Firefox/NativeMessagingHosts/passff.json".source = "${pkgs.passff-host}/lib/mozilla/native-messaging-hosts/passff.json";
          "Library/Application Support/Firefox/NativeMessagingHosts/ff2mpv.json".source = "${pkgs.ff2mpv}/lib/mozilla/native-messaging-hosts/ff2mpv.json";
        };

      packages =
        [
          pkgs.aspell
          pkgs.bottom # fancy version of `top` with ASCII graphs
          pkgs.browsh # in terminal browser
          pkgs.coreutils
          pkgs.codespell
          pkgs.curl
          pkgs.chafa
          pkgs.dust # fancy version of `du`
          pkgs.fd # fancy version of `find`
          pkgs.unzip

          # Fonts
          pkgs.nerd-fonts.noto
          pkgs.nerd-fonts.jetbrains-mono
          pkgs.noto-fonts
          pkgs.noto-fonts-cjk-sans
          pkgs.noto-fonts-color-emoji

          pkgs.libiconv
          pkgs.go
          pkgs.nb
          pkgs.luajitPackages.luarocks
          pkgs.lnav
          pkgs.ripgrep # better version of `grep`
          pkgs.rsync
          pkgs.sd
          pkgs.sqlite
          pkgs.stow
          pkgs.tig
          pkgs.tree-sitter
          pkgs.units
          pkgs.wget
          pkgs.wasm-pack
          pkgs.nmap
          pkgs.presenterm
          # # https://github.com/mitchellh/zig-overlay
          # # latest nightly release
          # pkgs.zigpkgs.master
          # pkgs.zls
          pkgs.qemu
          pkgs.sops
          pkgs.age
          pkgs.mkpasswd
          pkgs.socat
          pkgs.ldns
          pkgs.qmk
          pkgs.imagemagick
          pkgs.libsecret
          pkgs.localsend
          pkgs.slides # TUI Present tool
          pkgs.localsend
          pkgs.libargon2

          # CAD
          # pkgs.openscad-unstable # Clipper2 doesn't support macOS
          # pkgs.openscad-lsp

          # Dev stuff
          pkgs.jq
          # pkgs.nodePackages.write-good
          # pkgs.efm-langserver
          pkgs.gitlint
          # pkgs.selene
          pkgs.dotenv-linter
          # pkgs.deadnix
          # pkgs.typos
          # pkgs.dprint
          # pkgs.languagetool-rust
          # pkgs.shellcheck
          pkgs.gnumake
          pkgs.gcc
          # pkgs.wgsl-analyzer
          # pkgs.unzip
          pkgs.python3
          pkgs.deno
        ]
        ++ (lib.optionals (isLinux && !isWSL) [
          pkgs.eww
          pkgs.foliate
          pkgs.freecad
          pkgs.mesa-demos
          pkgs.grim
          pkgs.libnotify
          pkgs.libsForQt5.qt5.qtwayland
          pkgs.libusb1
          pkgs.libva-utils
          pkgs.qt6.qtwayland
          pkgs.slurp
          pkgs.sound-theme-freedesktop
          pkgs.swayidle
          pkgs.testdisk # data recovery
          pkgs.usbutils
          pkgs.wl-clipboard
          pkgs.wl-screenrec
          pkgs.xdg-utils
        ])
        ++ (lib.optionals isDarwin) [
          pkgs.iina # media player
        ];
    }
    // lib.optionalAttrs (isLinux && !isWSL) {
      pointerCursor = {
        gtk.enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Original-Classic";
        size = 24;
      };
    };

  gtk = {
    enable = isLinux && !isWSL;

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

  programs =
    {
      zsh = {
        enable = false;
        autosuggestion = {
          enable = true;
        };
        defaultKeymap = "emacs";
        syntaxHighlighting = {
          enable = true;
          highlighters = ["main" "brackets"];
        };
        historySubstringSearch = {
          enable = true;
          searchUpKey = ["^[[A" "^P"];
          searchDownKey = ["^[[B" "^N"];
        };
        enableCompletion = true;
        initContent = lib.mkMerge [
          (lib.mkOrder 550 (builtins.readFile (builtins.path {
            name = "zsh-init-completions";
            path = ./config/init.zsh;
          })))
          (lib.mkOrder 1000 (builtins.readFile (builtins.path {
            name = "zsh-config";
            path = ./config/config.zsh;
          })))
        ];
        envExtra =
          ''
            export MANROFFOPT="-c"
            # Git Review Env var
            export REVIEW_BASE=main
            export GPG_TTY="$(tty)"
          ''
          + (
            if isDarwin
            then ''
              export HOMEBREW_NO_ANALYTICS=1
              # Homebrew
              export PATH="$PATH:/opt/homebrew/bin"
              export LIBRARY_PATH=$LIBRARY_PATH:${pkgs.libiconv}/lib
              export LDFLAGS="-L${pkgs.libiconv}/lib"
            ''
            else ""
          );
        shellAliases = {
          ls = "lsd";
          ll = "ls -l";
          lt = "ls --tree";
        };
      };

      fish = {
        enable = true;
        generateCompletions = true;
        shellInit =
          ''
          ''
          + (
            if isDarwin
            then ''
              set -gx HOMEBREW_NO_ANALYTICS 1
              # Setup brew
              eval "$(/opt/homebrew/bin/brew shellenv)"
            ''
            else ""
          );
      };

      lsd = {
        enable = true;
        enableFishIntegration = true;
      };

      bat = {
        enable = true;
        config = {
          pager = "less -FR";
          theme = "catppuccin-macchiato";
        };
        themes = {
          # https://raw.githubusercontent.com/catppuccin/bat/main/Catppuccin-Macchiato.tmTheme
          catppuccin-macchiato = {
            src = pkgs.fetchFromGitHub {
              owner = "catppuccin";
              repo = "bat";
              rev = "main";
              sha256 = "6fWoCH90IGumAMc4buLRWL0N61op+AuMNN9CAR9/OdI=";
            };
            file = "themes/Catppuccin Macchiato.tmTheme";
          };
        };
      };
      git = {
        enable = true;
      };
      delta = {
        enable = true;
        enableGitIntegration = true;
      };
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      fzf = {
        enable = true;
        enableFishIntegration = true;
      };
      password-store = {
        enable = true;
        package = pkgs.pass;
        settings = {PASSWORD_STORE_DIR = "$HOME/.password-store";};
      };
      zellij = {
        enable = true;
        enableBashIntegration = false;
        enableFishIntegration = false;
      };
      zoxide.enable = true;
      yazi = {
        enable = true;
        enableFishIntegration = true;
      };
      wezterm = {
        enable = isDarwin;
      };
      ghostty = {
        enable = isLinux && !isWSL;
        enableFishIntegration = true;
        installBatSyntax = true;
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

      mpv = {
        enable = true;
        package = pkgs.mpv;
      };

      yt-dlp = {
        enable = true;
      };

      # Starship Prompt
      # https://rycee.gitlab.io/home-manager/options.html#opt-programs.starship.enable
      starship = {
        enable = true;
        enableFishIntegration = true;
        settings = {
          command_timeout = 1000;
          directory.fish_style_pwd_dir_length = 1; # turn on fish directory truncation
          directory.truncation_length = 2; # number of directories not to truncate
          gcloud.disabled = true; # annoying to always have on
          hostname.style = "bold green"; # don't like the default
          memory_usage.disabled = true; # because it includes cached memory it's reported as full a lot
          username.style_user = "bold blue"; # don't like the default
        };
      };

      gpg = {
        enable = true;
        settings = {
          # https://github.com/drduh/config/blob/master/gpg.conf
          # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html
          # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Esoteric-Options.html
          # 'gpg --version' to get capabilities
          # Use AES256, 192, or 128 as cipher
          personal-cipher-preferences = "AES256 AES192 AES";
          # Use SHA512, 384, or 256 as digest
          personal-digest-preferences = "SHA512 SHA384 SHA256";
          # Use ZLIB, BZIP2, ZIP, or no compression
          personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
          # Default preferences for new keys
          default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
          # SHA512 as digest to sign keys
          cert-digest-algo = "SHA512";
          # SHA512 as digest for symmetric ops
          s2k-digest-algo = "SHA512";
          # AES256 as cipher for symmetric ops
          s2k-cipher-algo = "AES256";
          # UTF-8 support for compatibility
          charset = "utf-8";
          # Show Unix timestamps
          fixed-list-mode = true;
          # No comments in signature
          no-comments = true;
          # No version in output
          no-emit-version = true;
          # Disable banner
          no-greeting = true;
          # Long hexadecimal key format
          keyid-format = "0xlong";
          # Display UID validity
          list-options = "show-uid-validity";
          verify-options = "show-uid-validity";
          # Display all keys and their fingerprints
          with-fingerprint = true;
          # Display key origins and updates
          #with-key-origin
          # Cross-certify subkeys are present and valid
          require-cross-certification = true;
          # Disable caching of passphrase for symmetrical ops
          no-symkey-cache = true;
          # Enable smartcard
          use-agent = true;
          # Disable recipient key ID in messages
          throw-keyids = true;
          # Default/trusted key ID to use (helpful with throw-keyids)
          default-key = "0xD400A663D09CB107";
          trusted-key = "0xD400A663D09CB107";
          # Group recipient keys (preferred ID last)
          #group keygroup = 0xFF00000000000001 0xFF00000000000002 0xFF3E7D88647EBCDB
          # Keyserver URL
          #keyserver hkps://keys.openpgp.org
          #keyserver hkps://keyserver.ubuntu.com:443
          #keyserver hkps://hkps.pool.sks-keyservers.net
          #keyserver hkps://pgp.ocf.berkeley.edu
          # Proxy to use for keyservers
          #keyserver-options http-proxy=http://127.0.0.1:8118
          #keyserver-options http-proxy=socks5-hostname://127.0.0.1:9050
          # Verbose output
          #verbose
          # Show expired subkeys
          #list-options = "show-unusable-subkeys";
        };
      };

      ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks."*".hashKnownHosts = true;
        extraConfig = ''
          # Host keys the client accepts - order here is honored by OpenSSH
          HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa,ecdsa-sha2-nistp521-cert-v01@openssh.com,ecdsa-sha2-nistp384-cert-v01@openssh.com,ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp521,ecdsa-sha2-nistp384,ecdsa-sha2-nistp256

          KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
          MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
          Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
        '';
        includes = ["./.config"];
      };
    }
    // lib.optionalAttrs (isLinux && !isWSL) {
      imv = {
        enable = isLinux && !isWSL;
      };
      wlogout = {
        enable = true;
        layout = [
          {
            label = "lock";
            action = "~/.config/hypr/sway-lock.sh";
            text = "Lock";
            keybind = "l";
          }
          {
            label = "hibernate";
            action = "systemctl hibernate";
            text = "Hibernate";
            keybind = "h";
          }
          {
            label = "logout";
            action = "loginctl terminate-user $USER";
            text = "Logout";
            keybind = "e";
          }
          {
            label = "shutdown";
            action = "systemctl poweroff";
            text = "Shutdown";
            keybind = "s";
          }
          {
            label = "suspend";
            action = "systemctl suspend";
            text = "Suspend";
            keybind = "u";
          }
          {
            label = "reboot";
            action = "systemctl reboot";
            text = "Reboot";
            keybind = "r";
          }
        ];
      };
      foot = {
        enable = true;
        server.enable = isLinux && !isWSL;
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
            path = ./config/user.js;
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
          # "--enable-features=Vulkan"
          # "--enable-unsafe-webgpu"
        ];
      };
      # launcher
      anyrun = {
        # package = inputs.anyrun.packages.${pkgs.system}.default;
        enable = isLinux && !isWSL;
        config = {
          x = {fraction = 0.5;};
          y = {fraction = 0.02;};
          width = {fraction = 0.3;};
          hideIcons = false;
          ignoreExclusiveZones = false;
          layer = "overlay";
          hidePluginInfo = true;
          closeOnClick = true;
          showResultsImmediately = false;
          maxEntries = 10;

          plugins = [
            "${pkgs.anyrun}/lib/libapplications.so"
            "${pkgs.anyrun}/lib/librink.so"
            "${pkgs.anyrun}/lib/libshell.so"
            "${pkgs.anyrun}/lib/libtranslate.so"
            "${pkgs.anyrun}/lib/libdictionary.so"
            "${pkgs.anyrun}/lib/libwebsearch.so"
          ];
        };
        extraConfigFiles = {
          "applications.ron".text = ''
            Config(
              // Also show the Desktop Actions defined in the desktop files, e.g. "New Window" from LibreWolf
              desktop_actions: true,
              max_entries: 10,
              // The terminal used for running terminal based desktop entries, if left as `None` a static list of terminals is used
              // to determine what terminal to use.
              terminal: Some(Terminal(command: "ghostty", args: "-e {}")),
            )
          '';
          "websearch.ron".text = ''
            Config(
              prefix: "?",
              // Options: Google, Ecosia, Bing, DuckDuckGo, Custom
              //
              // Custom engines can be defined as such:
              // Custom(
              //   name: "Searx",
              //   url: "searx.be/?q={}",
              // )
              //
              // NOTE: `{}` is replaced by the search query and `https://` is automatically added in front.
              engines: [Google]
            )
          '';
          "dictionary.ron".text = ''
            Config(
              prefix: ":def",
              max_entries: 5,
            )
          '';
        };
        # custom css for anyrun, based on catppuccin-mocha
        extraCss = ''
          @define-color bg-col  rgba(30, 30, 46, 0.7);
          @define-color bg-col-light rgba(150, 220, 235, 0.7);
          @define-color border-col rgba(30, 30, 46, 0.7);
          @define-color selected-col rgba(150, 205, 251, 0.7);
          @define-color fg-col #D9E0EE;
          @define-color fg-col2 #F28FAD;

          * {
            font-family: "JetBrainsMono Nerd Font";
            font-size: 1.3rem;
          }

          window {
            background: transparent;
          }

          .plugin,
          .main {
            border: 3px solid @border-col;
            color: @fg-col;
            background-color: @bg-col;
          }
          /* anyrun's input window - Text */
          .entry {
            color: @fg-col;
            background-color: @bg-col;
          }

          /* anyrun's output matches entries - Base */
          .match {
            color: @fg-col;
            background: @bg-col;
          }

          /* anyrun's selected entry - Red */
          .match:selected {
            color: @fg-col2;
            background: @selected-col;
          }

          .matches {
            padding: 3px;
            border-radius: 16px;
          }

          .entry, .plugin:hover {
            border-radius: 16px;
          }

          box.main {
            background: rgba(30, 30, 46, 0.7);
            border: 1px solid @border-col;
            border-radius: 15px;
            padding: 5px;
          }

          @keyframes fade {
            0% {
              opacity: 0;
            }

            100% {
              opacity: 1;
            }
          }
        '';
      };
    };

  wayland.windowManager = {
    sway = {
      # Disable sway as https://github.com/swaywm/sway/issues/6581
      enable = false;
      extraOptions = ["--unsupported-gpu"];
      wrapperFeatures.gtk = true;
      config = {
        modifier = "Mod4";
        terminal = "foot";
        startup = [
          {command = "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK";}
        ];
      };
    };

    hyprland = {
      enable = isLinux && !isWSL;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      settings = {
        source = "./hypr.conf";
      };
      systemd.enable = false;
      xwayland.enable = false;
    };
  };

  services = {
    gpg-agent = {
      enable = isLinux;
      defaultCacheTtl = 1800;
      pinentry.package = pkgs.pinentry-curses;
      enableScDaemon = true;
      enableFishIntegration = true;
      enableSshSupport = true;
      enableExtraSocket = true;
    };

    udiskie = {
      enable = isLinux && !isWSL;
    };

    mako = {
      enable = isLinux && !isWSL;
    };

    wlsunset = {
      enable = isLinux && !isWSL;
      latitude = "59.8";
      longitude = "10.8";
    };
    # wallpaper
    wpaperd = {
      enable = isLinux && !isWSL;
      settings = {
        default = {
          path = "~/Pictures/Wallpapers/";
          duration = "30m";
        };
      };
    };
  };
}
