{lib, ...}: {
  programs.nixvim = {
    plugins = {
      nvim-ufo = {
        enable = true;
      };
      lsp.capabilities = ''
        capabilities.textDocument.foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true
        }
      '';
    };
    opts = {
      foldcolumn = "1"; # "0" is not bad
      foldlevel = 99; # Using `ufo` provider need a large value, feel free to decrease the value
      foldlevelstart = 99;
      foldenable = true;
      fillchars = ''eob: ,fold: ,foldopen:,foldsep: ,foldclose:'';
    };
    keymaps =
      lib.mapAttrsToList (key: mapping: {
        mode = "n";
        inherit key;
        action =
          mapping.action;
        options = mapping.options or {};
      }) {
        "zR" = {
          action = "<cmd>lua require('ufo').openAllFolds()<CR>";
          options.desc = "Open all folds";
        };
        "zM" = {
          action = "<cmd>lua require('ufo').closeAllFolds()<CR>";
          options.desc = "Close all folds";
        };
        "zr" = {
          action = "<cmd>lua require('ufo').openFoldsExceptKinds()<CR>";
          options.desc = "Open fold";
        };
        "zm" = {
          action = "<cmd>lua require('ufo').closeFoldsWith()<CR>";
          options.desc = "Close fold";
        };
        "K" = {
          action = {
            __raw = ''
              function()
                  local winid = require('ufo').peekFoldedLinesUnderCursor()
                  if not winid then
                      vim.lsp.buf.hover()
                  end
              end
            '';
          };
          options.desc = "Close fold";
        };
      };
  };
}
