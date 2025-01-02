{lib, ...}: {
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
    keymaps =
      lib.mapAttrsToList (key: mapping: {
        mode = "n";
        inherit key;
        action =
          mapping.action;
        options = mapping.options or {};
      }) {
        "<leader>gs" = {
          action.__raw = ''
            function()
              local Terminal  = require('toggleterm.terminal').Terminal
              local tig = Terminal:new({ cmd = "tig status", direction = 'float' })

              tig:toggle()
            end
          '';
          options.desc = "Git status";
        };
        "]c" = {
          action.__raw = ''
            function()
              if vim.wo.diff then
                vim.cmd.normal({']c', bang = true})
              else
                require("gitsigns").nav_hunk('next')
              end
            end
          '';
          options.desc = "Next Hunk";
        };
        "[c" = {
          action.__raw = ''
            function()
              if vim.wo.diff then
                vim.cmd.normal({'[c', bang = true})
              else
                require("gitsigns").nav_hunk('prev')
              end
            end
          '';
          options.desc = "Prev Hunk";
        };
        "<leader>hs" = {
          action.__raw = ''
            function()
              require("gitsigns").stage_hunk()
            end
          '';
          options.desc = "Stage Hunk";
        };
        "<leader>hr" = {
          action.__raw = ''
            function()
              require("gitsigns").reset_hunk()
            end
          '';
          options.desc = "Reset Hunk";
        };
        "<leader>hS" = {
          action.__raw = ''
            function()
              require("gitsigns").stage_buffer()
            end
          '';
          options.desc = "Stage Buffer";
        };
        "<leader>hu" = {
          action.__raw = ''
            function()
              require("gitsigns").undo_stage_hunk()
            end
          '';
          options.desc = "Undo Stage Hunk";
        };
        "<leader>hR" = {
          action.__raw = ''
            function()
              require("gitsigns").reset_buffer()
            end
          '';
          options.desc = "Reset Buffer";
        };
        "<leader>hp" = {
          action.__raw = ''
            function()
              require("gitsigns").preview_hunk()
            end
          '';
          options.desc = "Preview Hunk";
        };
        "<leader>hb" = {
          action.__raw = ''
            function()
              require("gitsigns").blame_line({full=true})
            end
          '';
          options.desc = "Blame Line";
        };
        "<leader>hd" = {
          action.__raw = ''
            function()
              require("gitsigns").diffthis()
            end
          '';
          options.desc = "Diff This";
        };
        "<leader>hD" = {
          action.__raw = ''
            function()
              require("gitsigns").diffthis('~')
            end
          '';
          options.desc = "Diff This~";
        };
      }
      ++ lib.mapAttrsToList (key: mapping: {
        mode = "v";
        inherit key;
        action =
          mapping.action;
        options = mapping.options or {};
      }) {
        "<leader>hs" = {
          action.__raw = ''
            function()
              require("gitsigns").stage_hunk({vim.fn.line('.'), vim.fn.line('v')})
            end
          '';
          options.desc = "Stage Hunk";
        };
        "<leader>hr" = {
          action.__raw = ''
            function()
              require("gitsigns").reset_hunk({vim.fn.line('.'), vim.fn.line('v')})
            end
          '';
          options.desc = "Reset Hunk";
        };
      };
  };
}
