{
  inputs,
  isWSL,
  ...
}: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin isLinux;
in {
  imports = [
    ../programs
  ];

  xdg = {
    enable = true;
    configFile = {
      git = {
        enable = true;
        source = builtins.path {
          name = "git-config";
          path = ../config/git;
        };
      };
      tig = {
        enable = true;
        source = builtins.path {
          name = "tig-config";
          path = ../config/tig;
        };
      };
      tridactyl = {
        enable = true;
        source = builtins.path {
          name = "tridactyl-config";
          path = ../config/tridactyl;
        };
      };
      ghostty = {
        enable = true;
        source = builtins.path {
          name = "ghostty-config";
          path = ../config/ghostty;
        };
      };
      mpv = {
        enable = true;
        source = builtins.path {
          name = "mpv";
          path = ../config/mpv;
        };
      };
    };
  };

  home = {
    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      PAGER = "less -FirSwX";
      # VISUAL = "$EDITOR";
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
      NKT_ROOT_DIR = "$HOME/docs";
    };

    file = {
      ".inputrc".source = builtins.path {
        name = "inputrc-config";
        path = ../config/inputrc;
      };
      "biome.json".text = builtins.toJSON {
        formatter = {
          enabled = true;
          indentStyle = "space";
        };
      };
    };

    packages = [
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
      pkgs.sqlite
      pkgs.stow
      pkgs.tig
      pkgs.tree-sitter
      pkgs.units
      pkgs.wget
      pkgs.wasm-pack
      pkgs.nmap
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
      pkgs.libqalculate

      # Dev stuff
      pkgs.jq
      pkgs.gitlint
      pkgs.dotenv-linter
      pkgs.gnumake
      pkgs.gcc
    ];
  };

  fonts.fontconfig.enable = true;

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs = {
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
        # https://github.com/catppuccin/bat/blob/main/themes/Catppuccin%20Mocha.tmTheme
        catppuccin-macchiato = {
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "bat";
            rev = "6810349b28055dce54076712fc05fc68da4b8ec0";
            hash = "sha256-lJapSgRVENTrbmpVyn+UQabC9fpV1G1e+CdlJ090uvg=";
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
    fzf = {
      enable = true;
      enableFishIntegration = true;
    };
    password-store = {
      enable = true;
      package = pkgs.pass;
      settings = {PASSWORD_STORE_DIR = "$HOME/.password-store";};
    };
    zoxide.enable = true;
    yazi = {
      enable = true;
      enableFishIntegration = true;
      shellWrapperName = "y";
    };
    ghostty = {
      enable = isLinux && !isWSL;
      enableFishIntegration = true;
      installBatSyntax = true;
      installVimSyntax = true;
      systemd = {
        enable = true;
      };
    };
    mpv = {
      enable = true;
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
      extraConfig =
        if isDarwin
        then inputs.nix-secrets.ssh.extraConfigCommon + inputs.nix-secrets.ssh.extraConfigDarwin
        else inputs.nix-secrets.ssh.extraConfigCommon + inputs.nix-secrets.ssh.extraConfigNixOS;
      includes = ["./.config"];
    };
  };
}
