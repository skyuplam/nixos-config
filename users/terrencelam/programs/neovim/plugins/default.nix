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
