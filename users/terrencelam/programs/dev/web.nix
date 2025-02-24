{
  pkgs,
  lib,
  ...
}: let
  nodejs = pkgs.nodejs_18;
  yarn = pkgs.yarn.override {inherit nodejs;};
  prettier = {
    __raw = ''
      function(bufnr)
        if require("conform").get_formatter_info("prettier", bufnr).available then
          return { "prettier" }
        else
          return { "biome" }
        end
      end
    '';
  };
in {
  home = {
    packages = with pkgs; [
      nodejs
      yarn
      pnpm
      biome # toolchain for the web
      nodePackages.typescript-language-server
      nodePackages.yaml-language-server
      vscode-langservers-extracted
    ];
  };

  programs = {
    nixvim = {
      plugins = {
        lsp.servers = {
          nil_ls = {
            enable = true;
            settings.formatting.command = [
              (lib.getExe pkgs.alejandra)
            ];
          };
          cssls = {
            enable = true;
          };
          # Disable until eslint is dropped
          biome.enable = true;
          eslint = {
            enable = false;

            settings = {
              nodePath = {
                __raw = ''
                  vim.fn.getcwd() .. '/.yarn/sdks'
                '';
              };
              packageManager = "yarn";
              codeActionOnSave = {
                enable = true;
                mode = "all";
              };
            };
          };
          ts_ls = {
            enable = true;
          };
        };
        conform-nvim = {
          settings = {
            formatters_by_ft = {
              javascript = prettier;
              typescript = prettier;
              javascriptreact = prettier;
              typescriptreact = prettier;
              json = prettier;
              jsonc = prettier;
            };
          };
        };
      };
    };
  };
}
