{
  programs.nixvim = {
    plugins = {
      conform-nvim = {
        enable = true;

        settings = {
          formatters_by_ft = {
            # -- https://github.com/JohnnyMorganz/StyLua
            lua = ["stylua"];
            # -- https://github.com/ziglang/zig
            zig = ["zigfmt"];
            c = ["clang-format"];
            cpp = ["clang-format"];
            rust = ["rustfmt"];
            # -- Use the "*" filetype to run formatters on all filetypes.
            "*" = ["codespell"];
            # -- Use the "_" filetype to run formatters on filetypes that don't
            # -- have other formatters configured.
            "_" = ["trim_whitespace"];
          };

          format_on_save = {
            timeout_ms = 500;
            lsp_format = "fallback";
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
}
