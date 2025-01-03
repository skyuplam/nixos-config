{
  programs.nixvim = {
    colorschemes.catppuccin.settings.integrations = {
      blink_cmp = true;
    };

    plugins = {
      blink-cmp = {
        enable = true;
        settings = {
          sources = {
            default = [
              "lsp"
              "path"
              "luasnip"
              "buffer"
              "copilot"
            ];
            providers = {
              copilot = {
                name = "copilot";
                module = "blink-cmp-copilot";
                score_offset = 100;
                async = true;
                transform_items = {
                  __raw = ''
                    function(_, items)
                      local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
                      local kind_idx = #CompletionItemKind + 1
                      CompletionItemKind[kind_idx] = "Copilot"
                      for _, item in ipairs(items) do
                        item.kind = kind_idx
                      end
                      return items
                    end
                  '';
                };
              };
            };
          };
          keymap = {
            preset = "enter";
          };
          completion.list.selection = "manual";
          appearance = {
            kind_icons = {
              Copilot = "";
              Text = "󰉿";
              Method = "󰊕";
              Function = "󰊕";
              Constructor = "󰒓";

              Field = "󰜢";
              Variable = "󰆦";
              Property = "󰖷";

              Class = "󱡠";
              Interface = "󱡠";
              Struct = "󱡠";
              Module = "󰅩";

              Unit = "󰪚";
              Value = "󰦨";
              Enum = "󰦨";
              EnumMember = "󰦨";

              Keyword = "󰻾";
              Constant = "󰏿";

              Snippet = "󱄽";
              Color = "󰏘";
              File = "󰈔";
              Reference = "󰬲";
              Folder = "󰉋";
              Event = "󱐋";
              Operator = "󰪚";
              TypeParameter = "󰬛";
            };
          };
        };
      };

      copilot-lua = {
        enable = true;
      };

      blink-cmp-copilot = {
        enable = true;
      };
    };
  };
}
