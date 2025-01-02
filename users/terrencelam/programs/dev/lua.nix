{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      stylua # Lua formatter
      lua-language-server
    ];
  };
  programs = {
    nixvim = {
      plugins = {
        lsp.servers = {
          lua_ls = {
            enable = true;
            settings = {
              Lua = {
                runtime = {
                  version = "LuaJIT";
                };
                completion = {callSnippet = "Replace";};
                telemetry = {enable = false;};
                workspace = {
                  checkThirdParty = false;
                  library = [
                    {
                      __raw = ''
                        vim.env.VIMRUNTIME
                      '';
                    }
                  ];
                };
              };
            };
          };
        };

        hmts.enable = true;

        conform-nvim = {
          settings = {
            formatters_by_ft = {
              lua = ["stylua"];
            };
          };
        };
      };
    };
  };
}
