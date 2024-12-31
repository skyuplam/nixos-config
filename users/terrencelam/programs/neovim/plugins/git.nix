{
  programs.nixvim = {
    plugins = {
      gitsigns = {
        enable = true;
        settings = {
          signcolumn = true;
          current_line_blame = true;
          trouble = true;
          watch_gitdir = {
            enable = true;
            follow_files = true;
          };
        };
      };

      diffview = {
        enable = true;
        view = {
          mergeTool = {
            layout = "diff4_mixed";
          };
        };
      };

      toggleterm = {
        enable = true;
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>gs";
        action.__raw = ''
          function()
            local Terminal  = require('toggleterm.terminal').Terminal
            local tig = Terminal:new({ cmd = "tig status", direction = 'float' })

            tig:toggle()
          end
        '';
        options.desc = "Git status";
      }
    ];
  };
}
