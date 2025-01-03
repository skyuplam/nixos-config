{
  imports = [
    ./telescope.nix
    ./lsp.nix
    ./cmp.nix
    ./yazi.nix
    ./git.nix
    ./format.nix
    ./treesitter.nix
    ./fold.nix
  ];

  programs.nixvim = {
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = true;
        dim_inactive = {enabled = false;};
        integrations = {
          aerial = true;
          notify = true;
          which_key = false;
        };
        custom_highlights = {
          __raw = ''
            function(C)
              local transparent_background = require("catppuccin").options.transparent_background
              local bg_highlight = transparent_background and "NONE" or C.base

              local inactive_bg = transparent_background and "NONE" or C.mantle
              return {
                MiniStatuslineDevinfo = { fg = C.subtext1, bg = C.surface1 },
                MiniStatuslineFileinfo = { fg = C.subtext1, bg = bg_highlight },
                MiniStatuslineFilename = { fg = C.text, bg = bg_highlight },
                MiniStatuslineInactive = { fg = C.blue, bg = inactive_bg },
                MiniStatuslineModeCommand = { fg = C.base, bg = C.peach, style = { "bold" } },
                MiniStatuslineModeInsert = { fg = C.base, bg = C.green, style = { "bold" } },
                MiniStatuslineModeNormal = { fg = C.mantle, bg = C.blue, style = { "bold" } },
                MiniStatuslineModeOther = { fg = C.base, bg = C.teal, style = { "bold" } },
                MiniStatuslineModeReplace = { fg = C.base, bg = C.red, style = { "bold" } },
                MiniStatuslineModeVisual = { fg = C.base, bg = C.mauve, style = { "bold" } },

                MiniTablineCurrent = { fg = C.text, bg = bg_highlight, sp = C.red, style = { "bold", "italic", "underline" } },
                MiniTablineFill = { bg = bg_highlight },
                MiniTablineHidden = { fg = C.text, bg = inactive_bg },
                MiniTablineModifiedCurrent = { fg = C.red, bg = C.none, style = { "bold", "italic" } },
                MiniTablineModifiedHidden = { fg = C.red, bg = C.none },
                MiniTablineModifiedVisible = { fg = C.red, bg = C.none },
                MiniTablineTabpagesection = { fg = C.surface1, bg = bg_highlight },
                MiniTablineVisible = { bg = C.none },
              }
            end
          '';
        };
      };
    };

    plugins = {
      spectre = {
        enable = true;
        settings = {
          default = {
            replace = {
              cmd = "oxi";
            };
          };
        };
      };
      notify = {
        enable = true;
        backgroundColour = "#000000";
      };
      mini = {
        enable = true;
        mockDevIcons = true;
        modules = {
          ai = {};
          comment = {};
          surround = {};
          icons = {};
          tabline = {};
          indentscope = {
            draw = {
              delay = 0;
              animation = {
                __raw = ''
                  require('mini.indentscope').gen_animation.none()
                '';
              };
            };
          };
          statusline = {};
        };
      };

      aerial = {
        enable = true;
      };

      which-key = {
        enable = true;
      };

      smartcolumn = {
        enable = true;
      };
    };
  };
}
