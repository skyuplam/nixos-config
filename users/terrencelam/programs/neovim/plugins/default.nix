{
  imports = [
    ./telescope.nix
    ./lsp.nix
    ./cmp.nix
    ./yazi.nix
    ./git.nix
    ./format.nix
    ./treesitter.nix
    ./fold.nix
  ];

  programs.nixvim = {
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = true;
        dim_inactive = {enabled = false;};
      };
    };

    plugins = {
      spectre = {
        enable = true;
        settings = {
          default = {
            replace = {
              cmd = "oxi";
            };
          };
        };
      };
      notify = {
        enable = true;
        backgroundColour = "#000000";
      };
      mini = {
        enable = true;
        mockDevIcons = true;
        modules = {
          ai = {};
          comment = {};
          surround = {};
          icons = {};
          tabline = {};
          indentscope = {
            draw = {
              delay = 0;
              animation = {
                __raw = ''
                  require('mini.indentscope').gen_animation.none()
                '';
              };
            };
          };
          statusline = {};
        };
      };

      aerial = {
        enable = true;
      };

      which-key = {
        enable = true;
      };

      smartcolumn = {
        enable = true;
      };
    };
  };
}
