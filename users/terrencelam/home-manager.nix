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
  inherit (pkgs.stdenv) isDarwin isLinux;

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = pkgs.writeShellScriptBin "manpager" (
    if isDarwin
    then ''
      sh -c 'col -bx | bat -l man -p'
    ''
    else ''
      exec cat "$@" | col -bx | bat --language man --style plain --pager "$PAGER"
    ''
  );
in {
  xdg = {
    enable = true;
    userDirs = {
      enable = isLinux && !isWSL;
      createDirectories = true;
    };
    configFile = {
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
      skhd = {
        enable = isDarwin;
        source = builtins.path {
          name = "skhd-config";
          path = ./config/skhd;
        };
      };
      yabai = {
        enable = isDarwin;
        source = builtins.path {
          name = "yabai-config";
          path = ./config/yabai;
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
      fuzzel = {
        enable = true;
        source = builtins.path {
          name = "fuzzel-config";
          path = ./config/fuzzel;
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
        enable = true;
        source = builtins.path {
          name = "wezterm-config";
          path = ./config/wezterm;
        };
      };
      swaylock = {
        enable = true;
        source = builtins.path {
          name = "swaylock-config";
          path = ./config/swaylock;
        };
      };
    };
  };

  home = {
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
      EDITOR = "nvim";
      PAGER = "less -FirSwX";
      MANPAGER = "${manpager}/bin/manpager";
      SQLITE_CLIB_PATH = "${pkgs.sqlite.out}/lib/libsqlite3.${
        if isDarwin
        then "dylib"
        else "so"
      }";
      CODEIUM_PATH = "${pkgs.codeium-lsp}/bin/codeium-lsp";
    };

    file.".inputrc".source = builtins.path {
      name = "inputrc-config";
      path = ./config/inputrc;
    };

    # activation = {
    #   linkNeovimConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    #     #!/bin/bash
    #
    #     stow_config() {
    #       if [ "$#" -lt 1 ]
    #       then
    #         echo "stow_config requires at least 1 argument"
    #         exit 1
    #       fi
    #
    #       local CONFIG_HOME=~/.config
    #       local TARGET=$CONFIG_HOME/$1
    #
    #       echo "linking $1 config to $TARGET"
    #       # Ensure the folder is there
    #       mkdir -p $TARGET
    #       # Perform unrestricted find all the symbolic links in the foler to execute rm
    #       ${pkgs.fd}/bin/fd -u -t l . $TARGET -x rm
    #       ${pkgs.stow}/bin/stow -d ${dotfilesPath} -t $TARGET -S $1
    #     }
    #
    #     stow_config "nvim"
    #     stow_config "eww"
    #     stow_config "hypr"
    #   '';
    # };

    packages =
      [
        pkgs.aspell
        pkgs.bat
        pkgs.bottom # fancy version of `top` with ASCII graphs
        pkgs.browsh # in terminal browser
        pkgs.coreutils
        pkgs.codespell
        pkgs.curl
        pkgs.chafa
        pkgs.du-dust # fancy version of `du`
        pkgs.fd # fancy version of `find`
        (pkgs.nerdfonts.override {fonts = ["JetBrainsMono" "Noto"];})
        pkgs.libiconv
        pkgs.gnupg
        pkgs.go
        pkgs.nb
        pkgs.lsd
        pkgs.luajitPackages.luarocks
        pkgs.lnav
        pkgs.ripgrep # better version of `grep`
        pkgs.rsync
        pkgs.sd
        pkgs.sqlite
        pkgs.stow
        pkgs.tig
        pkgs.tmux
        pkgs.tree-sitter
        pkgs.units
        pkgs.wget
        pkgs.wasm-pack
        pkgs.yarn
        pkgs.mpv-unwrapped
        pkgs.yt-dlp
        pkgs.nmap
        pkgs.presenterm
        # https://github.com/mitchellh/zig-overlay
        # latest nightly release
        pkgs.zigpkgs.master
        pkgs.zls
        pkgs.qemu
        pkgs.sops
        pkgs.age
        pkgs.mkpasswd

        # Dev stuff
        pkgs.jq
        pkgs.nodePackages.typescript-language-server
        pkgs.nodePackages.yaml-language-server
        pkgs.nodePackages.vim-language-server
        pkgs.nodePackages.prettier
        pkgs.nodePackages.write-good
        pkgs.vscode-langservers-extracted
        pkgs.lua-language-server
        pkgs.efm-langserver
        pkgs.rustup
        pkgs.marksman
        pkgs.gitlint
        pkgs.stylua
        pkgs.selene
        pkgs.dotenv-linter
        pkgs.statix
        pkgs.deadnix
        pkgs.alejandra
        pkgs.typos
        pkgs.dprint
        pkgs.languagetool-rust
        pkgs.nil
        pkgs.shellcheck
        pkgs.gnumake
        pkgs.gcc
        pkgs.codeium-lsp
      ]
      ++ (lib.optionals (isLinux && !isWSL) [
        pkgs.wlogout
        pkgs.grim
        pkgs.swayidle
        pkgs.wl-clipboard
        pkgs.eww-wayland
      ]);
  };

  fonts.fontconfig.enable = true;

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs = {
    bash = {
      enable = true;
    };
    zsh = {
      enable = true;
      enableAutosuggestions = true;
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
      initExtraBeforeCompInit = builtins.readFile (builtins.path {
        name = "zsh-init-completions";
        path = ./config/init.zsh;
      });
      initExtra = builtins.readFile (builtins.path {
        name = "zsh-config";
        path = ./config/config.zsh;
      });
      envExtra =
        ''
          export MANROFFOPT="-c"
          # Git Review Env var
          export REVIEW_BASE=main
        ''
        + (
          if isDarwin
          then ''
            export HOMEBREW_NO_ANALYTICS=1
            # Homebrew
            export PATH="$PATH:/opt/homebrew/bin"
          ''
          else ""
        );
      shellAliases = {
        ls = "lsd";
        ll = "ls -l";
        lt = "ls --tree";
      };
    };

    bat = {
      enable = true;
    };

    git = {
      enable = true;
      delta.enable = true;
    };

    neovim = {
      enable = true;
      package = pkgs.neovim-nightly;

      withPython3 = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    password-store = {
      enable = true;
      package = pkgs.pass;
      settings = {PASSWORD_STORE_DIR = "$HOME/.password-store";};
    };

    zellij = {
      enable = true;
    };

    zoxide.enable = true;

    yazi = {
      enable = true;
      enableZshIntegration = true;
    };

    fuzzel = {
      enable = isLinux && !isWSL;
    };

    foot = {
      enable = isLinux && !isWSL;
    };

    wezterm = {
      enable = true;
      enableZshIntegration = true;
    };

    swaylock = {
      enable = isLinux && !isWSL;
    };

    # Starship Prompt
    # https://rycee.gitlab.io/home-manager/options.html#opt-programs.starship.enable
    starship = {
      enable = true;
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
        # Long hexidecimal key format
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
      hashKnownHosts = true;
      extraConfig = ''
        # Host keys the client accepts - order here is honored by OpenSSH
        HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa,ecdsa-sha2-nistp521-cert-v01@openssh.com,ecdsa-sha2-nistp384-cert-v01@openssh.com,ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp521,ecdsa-sha2-nistp384,ecdsa-sha2-nistp256

        KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
        MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      '';
      includes = ["./.config"];
    };

    # GUI
    firefox = {
      enable = isLinux && !isWSL;
      package = pkgs.firefox-nightly-bin;
    };

    wpaperd = {
      enable = isLinux && !isWSL;
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
        terminal = "wezterm";
        startup = [
          {command = "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK";}
        ];
      };
    };

    hyprland = {
      enable = isLinux && !isWSL;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      settings = {
        source = "./hypr.conf";
      };
      systemd.enable = false;
    };
  };

  services = {
    gpg-agent = {
      enable = isLinux;
      pinentryFlavor = "tty";
    };

    udiskie = {
      enable = isLinux && !isWSL;
    };

    dunst = {
      enable = isLinux && !isWSL;
    };

    wlsunset = {
      enable = isLinux && !isWSL;
      latitude = "59.8";
      longitude = "10.8";
    };
  };
}
