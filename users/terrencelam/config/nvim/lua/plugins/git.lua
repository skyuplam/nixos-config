return {
  {
    'sindrets/diffview.nvim',
    opts = {
      view = {
        mergeTool = {
          layout = 'diff4_mixed',
        },
      },
    },
  },
  { 'lewis6991/gitsigns.nvim', opts = { current_line_blame = true } },
}
