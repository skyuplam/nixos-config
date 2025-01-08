{lib, ...}: {
  programs.nixvim = {
    colorschemes.catppuccin.settings.integrations = {
      fidget = true;
    };

    plugins = {
      lsp-lines = {
        enable = true;
      };
      inc-rename = {
        enable = true;
      };
      fidget = {
        enable = true;
        settings = {
          notification = {
            window = {
              winblend = 0;
            };
          };
        };
      };

      lsp-signature = {
        enable = true;
        settings = {
          bind = true;
          handler_opts = {
            border = "rounded";
          };
        };
      };

      trouble = {
        enable = true;
      };

      lsp = {
        enable = true;

        inlayHints = true;

        preConfig = builtins.readFile (builtins.path {
          name = "lsp.lua";
          path = ../config/lspPreConfig.lua;
        });
        keymaps = {
          silent = true;
          diagnostic = {
            # Navigate in diagnostics
            "<leader>k" = "goto_prev";
            "<leader>j" = "goto_next";
          };

          lspBuf = {
            gd = "definition";
            gD = "references";
            gt = "type_definition";
            gi = "implementation";
            "<leader>ca" = "code_action";
          };
        };
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
        "<leader>rn" = {
          action = {
            __raw = ''
              function()
                return ":IncRename " .. vim.fn.expand("<cword>")
              end
            '';
          };
          options = {
            desc = "Rename";
            expr = true;
          };
        };
      };
  };
}
