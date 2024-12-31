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
            markdown = ["prettier" "biome"];
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
        };
      };
    };
  };
}
