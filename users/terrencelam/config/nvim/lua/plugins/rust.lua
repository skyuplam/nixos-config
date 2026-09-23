return {
  {
    'mrcjkb/rustaceanvim',
    version = '^9', -- Recommended
    lazy = false, -- This plugin is already lazy
    config = function(lazy, opts)
      vim.g.rustaceanvim = {
        ---@type rustaceanvim.tools.Opts
        tools = {},
        ---@type rustaceanvim.lsp.ClientOpts
        server = {
          default_settings = {
            -- rust-analyzer language server configuration
            ['rust-analyzer'] = {
              -- diagnostics = {
              --   disabled = { 'unlinked-file' },
              -- },
            },
          },
        },
        ---@type rustaceanvim.dap.Opts
        dap = {},
      }
    end,
  },
}
