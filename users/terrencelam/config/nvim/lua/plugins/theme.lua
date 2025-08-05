return {
  'catppuccin/nvim',
  name = 'catppuccin',
  opts = {
    transparent_background = true,
    float = {
      transparent = true, -- enable transparent floating windows
      solid = true, -- use solid styling for floating windows, see |winborder|
    },
    default_integrations = false,
    integrations = {
      telescope = {
        enabled = true,
        -- style = "nvchad"
      },
      gitsigns = true,
      nvimtree = false,
      blink_cmp = true,
      treesitter = true,
      diffview = true,
      snacks = {
        enabled = true,
        indent_scope_color = '', -- catppuccin color (eg. `lavender`) Default: text
      },
      mini = {
        enabled = true,
        indentscope_color = '',
      },
    },
    custom_highlights = function(C)
      local transparent_background = require('catppuccin').options.transparent_background
      local bg_highlight = transparent_background and 'NONE' or C.base

      local inactive_bg = transparent_background and 'NONE' or C.mantle
      return {
        MiniStatuslineDevinfo = { fg = C.subtext1, bg = C.surface1 },
        MiniStatuslineFileinfo = { fg = C.subtext1, bg = bg_highlight },
        MiniStatuslineFilename = { fg = C.text, bg = bg_highlight },
        MiniStatuslineInactive = { fg = C.blue, bg = inactive_bg },
        MiniStatuslineModeCommand = { fg = C.base, bg = C.peach, style = { 'bold' } },
        MiniStatuslineModeInsert = { fg = C.base, bg = C.green, style = { 'bold' } },
        MiniStatuslineModeNormal = { fg = C.mantle, bg = C.blue, style = { 'bold' } },
        MiniStatuslineModeOther = { fg = C.base, bg = C.teal, style = { 'bold' } },
        MiniStatuslineModeReplace = { fg = C.base, bg = C.red, style = { 'bold' } },
        MiniStatuslineModeVisual = { fg = C.base, bg = C.mauve, style = { 'bold' } },

        MiniTablineCurrent = { fg = C.text, bg = bg_highlight, sp = C.red, style = { 'bold', 'italic', 'underline' } },
        MiniTablineFill = { bg = bg_highlight },
        MiniTablineHidden = { fg = C.text, bg = inactive_bg },
        MiniTablineModifiedCurrent = { fg = C.red, bg = C.none, style = { 'bold', 'italic' } },
        MiniTablineModifiedHidden = { fg = C.red, bg = C.none },
        MiniTablineModifiedVisible = { fg = C.red, bg = C.none },
        MiniTablineTabpagesection = { fg = C.surface1, bg = bg_highlight },
        MiniTablineVisible = { bg = C.none },
      }
    end,
  },
  config = function(lazy, opts)
    require('catppuccin').setup(opts)
    -- load the colorscheme here
    vim.cmd([[colorscheme catppuccin]])
  end,
  priority = 1000,
}
