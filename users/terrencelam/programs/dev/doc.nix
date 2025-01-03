{
  pkgs,
  lib,
  ...
}: {
  programs = {
    nixvim = {
      colorschemes.catppuccin.settings.integrations = {
        markdown = true;
      };

      plugins = {
        render-markdown = {
          enable = true;
        };
        lsp.servers = {
          marksman = {
            enable = true;
            settings.formatting.command = [
              (lib.getExe pkgs.marksman)
            ];
          };

          harper_ls = {
            enable = true;

            settings = {
              "harper-ls" = {
                userDictPath = {__raw = ''vim.fn.stdpath("config") .. "/spell/en.utf-8.add"'';};
                linters = {
                  # Too manay noise
                  sentence_capitalization = false;
                  wrong_quotes = true;
                  linking_verbs = true;
                };
                codeActions = {
                  forceStable = true;
                };
              };
            };
          };
        };

        hmts.enable = true;

        conform-nvim = {
          settings = {
            formatters_by_ft = {
              markdown = ["prettier"];
            };
          };
        };
      };
    };
  };
}
