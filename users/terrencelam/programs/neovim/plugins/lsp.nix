{lib, ...}: {
  programs.nixvim = {
    plugins = {
      lsp-lines = {
        enable = true;
      };
      inc-rename = {
        enable = true;
      };
      fidget = {
        enable = true;
      };

      lsp-signature = {
        enable = true;
      };

      trouble = {
        enable = true;
      };

      lsp = {
        enable = true;

        inlayHints = true;

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
            K = "hover";
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
