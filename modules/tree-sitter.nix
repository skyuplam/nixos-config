{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.nvim-treesitter-parsers;

  parserSet = pkgs.vimPlugins.nvim-treesitter-parsers;

  normalUsers =
    lib.filterAttrs
    (_name: user: (user.isNormalUser or false) && (user.home or "") != "")
    config.users.users;

  parserPackages =
    map
    (parserName: {
      name = parserName;
      package =
        if builtins.hasAttr parserName parserSet
        then builtins.getAttr parserName parserSet
        else throw "Unknown nvim-treesitter parser: ${parserName}";
    })
    cfg.parsers;

  linkParserForUser = userName: user: parser: let
    group = user.group or "users";
    parserName = parser.name;
    parserPkg = parser.package;
  in ''
    home=${lib.escapeShellArg user.home}
    owner=${lib.escapeShellArg userName}
    group=${lib.escapeShellArg group}
    parser_name=${lib.escapeShellArg parserName}

    # NixOS activation cannot know a user's runtime XDG_CONFIG_HOME.
    # Use the XDG default based on the declared NixOS user home.
    xdg_config_home="$home/.config"
    nvim_config="$xdg_config_home/nvim"

    if [ -d "$home" ]; then
      install -d -o "$owner" -g "$group" \
        "$nvim_config/parser"

      # Nixpkgs tree-sitter grammars install the compiled parser as:
      #   $out/parser
      # Neovim expects:
      #   runtimepath/parser/<language>.so
      if [ -f "${parserPkg}/parser/${parserName}.so" ]; then
        ln -sfnT "${parserPkg}/parser/${parserName}.so" "$nvim_config/parser/${parserName}.so"
        chown -h "$owner:$group" "$nvim_config/parser/${parserName}.so"
      else
        echo "warning: ${parserPkg}/parser not found"
      fi
    fi
  '';

  linkAllParsersForUser = userName: user:
    lib.concatMapStringsSep "\n"
    (parser: linkParserForUser userName user parser)
    parserPackages;
in {
  options.programs.nvim-treesitter-parsers = {
    enable = lib.mkEnableOption "linking Nix-provided nvim-treesitter parsers into user Neovim config directories";

    parsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [
        "python"
        "rust"
      ];
      description = ''
        Parser names from pkgs.vimPlugins.nvim-treesitter-parsers to link into
        each normal user's ~/.config/nvim/parser.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.linkNvimTreesitterParsers.text =
      lib.concatStringsSep "\n"
      (lib.mapAttrsToList linkAllParsersForUser normalUsers);
  };
}
