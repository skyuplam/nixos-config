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
      biome # toolchain for the web
      nodePackages.typescript-language-server
      nodePackages.vim-language-server
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
          biome.enable = false;
          eslint = {
            enable = true;

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
            formatters = {
              prettier = {
                command = {
                  __raw = ''
                    function(self, bufnr)
                      local util = require("conform.util")
                      local fs = require("conform.fs")
                      local cmd = util.find_executable({ ".yarn/sdks/prettier/bin/prettier.cjs" }, "")(self, bufnr)
                      if cmd ~= "" then
                        return cmd
                      end
                      -- return type of util.from_node_modules is fun(self: conform.FormatterConfig, ctx: conform.Context): string
                      ---@diagnostic disable-next-line
                      return util.from_node_modules(fs.is_windows and "prettier.cmd" or "prettier")(self, bufnr)
                    end
                  '';
                };
              };
            };
          };
        };
      };
    };
  };
}
