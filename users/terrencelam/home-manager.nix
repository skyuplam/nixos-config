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
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # For our MANPAGER env var
  # https://github.com/sharkdp/bat/issues/1145
  manpager = pkgs.writeShellScriptBin "manpager" (
    if isDarwin
    then ''
      sh -c 'col -bx | bat -l man -p'
    ''
    else ''
      cat "$1" | col -bx | bat --language man --style plain
    ''
  );
in {
  # This value determines the Home Manager release that your configuration is compatible with. This
  # helps avoid breakage when a new Home Manager release introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See the Home Manager release notes for
  # a list of state version changes in each release.
  home.stateVersion = "23.11";

  xdg.enable = true;

  #---------------------------------------------------------------------
  # Packages
  #---------------------------------------------------------------------

  # Packages I always want installed. Most packages I install using
  # per-project flakes sourced with direnv and nix-shell, so this is
  # not a huge list.
  home.packages = [
    pkgs.aspell
    pkgs.bat
    pkgs.bottom # fancy version of `top` with ASCII graphs
    pkgs.browsh # in terminal browser
    pkgs.coreutils
    pkgs.codespell
    pkgs.curl
    pkgs.chafa
    pkgs.wezterm
    pkgs.du-dust # fancy version of `du`
    pkgs.fd # fancy version of `find`
    (pkgs.nerdfonts.override {fonts = ["JetBrainsMono" "Noto"];})
    pkgs.libiconv
    pkgs.gitAndTools.delta
    pkgs.gnupg
    pkgs.go
    pkgs.nb
    pkgs.lsd
    pkgs.luajitPackages.luarocks
    pkgs.lnav
    pkgs.neovim-nightly
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
    pkgs.zellij
    pkgs.xplr
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
    pkgs.nixpkgs-fmt
    pkgs.languagetool-rust
    (pkgs.python3.withPackages (p: with p; [pip pynvim]))
  ];

  #---------------------------------------------------------------------
  # Env vars and dotfiles
  #---------------------------------------------------------------------

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
    MANPAGER = "${manpager}/bin/manpager";
  };

  home.file.".inputrc".source = ./inputrc;

  fonts.fontconfig.enable = true;

  #---------------------------------------------------------------------
  # Programs
  #---------------------------------------------------------------------

  programs.bash = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    # enableAutosuggestions = true;
    enableCompletion = false;
    completionInit = "";
    # enableSyntaxHighlighting = true;
    initExtraBeforeCompInit = "[ -f $HOME/.zsh/init.zsh ] && source $HOME/.zsh/init.zsh";
  };

  programs.bat = {
    enable = true;
    config = {
      style = "plain";
    };
  };

  programs.git = {
    enable = true;
  };

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-nightly;

    withPython3 = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.password-store = {
    enable = true;
    package = pkgs.pass;
    settings = {PASSWORD_STORE_DIR = "$HOME/.password-store";};
  };

  programs.zellij = {
    enable = true;
  };

  programs.zoxide.enable = true;

  # Starship Prompt
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.starship.enable
  programs.starship = {
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

  programs.gpg = {
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

  wayland.windowManager.sway = {
    enable = isLinux;
    config = rec {
      modifier = "Mod4";
      terminal = "wezterm";
      startup = [
        # Launch Firefox on start
        # {command = "firefox";}
      ];
    };
  };

  services.gpg-agent = {
    enable = isLinux;
    pinentryFlavor = "tty";
  };
}
