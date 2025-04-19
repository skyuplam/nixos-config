return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      -- Customize or remove this keymap to your liking
      '<leader>f',
      function()
        require('conform').format({ async = true }, function(err)
          -- Leave visual mode after range format
          -- https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md#leave-visual-mode-after-range-format
          if not err then
            local mode = vim.api.nvim_get_mode().mode
            if vim.startswith(string.lower(mode), 'v') then
              vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes('<Esc>', true, false, true),
                'n',
                true
              )
            end
          end
        end)
      end,
      mode = '',
      desc = 'Format buffer',
    },
  },
  opts = {
    ignore_error = false,
    -- Set default options
    default_format_opts = {
      lsp_format = 'fallback',
    },
    format_on_save = {
      -- These options will be passed to conform.format()
      timeout_ms = 500,
      lsp_format = 'fallback',
    },
    formatters_by_ft = {
      lua = { 'stylua' },
      -- Conform will run multiple formatters sequentially
      python = { 'isort', 'black' },
      -- You can customize some of the format options for the filetype (:help conform.format)
      rust = { 'rustfmt', lsp_format = 'fallback' },
      -- Conform will run the first available formatter
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
      -- Use the "*" filetype to run formatters on all filetypes.
      -- Use the "_" filetype to run formatters on filetypes that don't
      -- have other formatters configured.
      -- ['_'] = { 'trim_whitespace' },
    },
    -- Map of treesitter language to filetype
    lang_to_ft = {
      bash = 'sh',
    },
    -- Map of treesitter language to file extension
    -- A temporary file name with this extension will be generated during formatting
    -- because some formatters care about the filename.
    lang_to_ext = {
      bash = 'sh',
      c = 'c',
      javascript = 'js',
      javascriptreact = 'jsx',
      lua = 'lua',
      markdown = 'md',
      nix = 'nix',
      python = 'py',
      rust = 'rs',
      typescript = 'ts',
      typescriptreact = 'tsx',
      zig = 'zig',
    },
    formatters = {
      prettier = {
        command = function(self, bufnr)
          local util = require('conform.util')
          local fs = require('conform.fs')
          local cmd = util.find_executable(
            { '.yarn/sdks/prettier/bin/prettier.cjs' },
            ''
          )(self, bufnr)
          if cmd ~= '' then
            return cmd
          end
          -- return type of util.from_node_modules is fun(self: conform.FormatterConfig, ctx: conform.Context): string
          ---@diagnostic disable-next-line
          return util.from_node_modules(
            fs.is_windows and 'prettier.cmd' or 'prettier'
          )(self, bufnr)
        end,
      },
      shfmt = {
        prepend_args = { '-i', '2' },
      },
    },
  },
  init = function()
    vim.opt.formatexpr = "v:lua.require'lazyvim.util'.format.formatexpr()"
    -- Format command
    vim.api.nvim_create_user_command('Format', function(args)
      local range = nil
      if args.count ~= -1 then
        local end_line =
          vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
        range = {
          start = { args.line1, 0 },
          ['end'] = { args.line2, end_line:len() },
        }
      end
      require('conform').format({
        async = true,
        lsp_format = 'fallback',
        range = range,
      })
    end, { range = true })
  end,
}
