{
  imports = [
    ./telescope.nix
    ./lsp.nix
    ./cmp.nix
    ./yazi.nix
    ./git.nix
    ./format.nix
    ./treesitter.nix
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
      mini = {
        enable = true;
        mockDevIcons = true;
        modules = {
          ai = {};
          comment = {};
          surround = {};
          icons = {};
          notify = {};
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
