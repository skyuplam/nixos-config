return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      completions = {
        lsp = { enabled = true },
        blink = { enabled = true },
      },
      code = {
        --- transparent background
        disable_background = true,
        highlight_border = false,
      },
    },
  },
}
