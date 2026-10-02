return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = {
      -- Parsers and queries are provisioned together from nixpkgs. Use the
      -- current branch so stale master queries cannot shadow those queries.
      { 'nvim-treesitter/nvim-treesitter', branch = 'main', lazy = false },
      'nvim-mini/mini.nvim',
    },
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
