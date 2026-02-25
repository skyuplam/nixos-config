---@param bufnr integer
---@param ... string
---@return string
local function first(bufnr, ...)
  local conform = require('conform')
  for i = 1, select('#', ...) do
    local formatter = select(i, ...)
    if conform.get_formatter_info(formatter, bufnr).available then
      return formatter
    end
  end
  return select(1, ...)
end

return {
  'stevearc/conform.nvim',
  lazy = true,
  cmd = 'ConformInfo',
  event = { 'BufWritePre' },
  keys = {
    {
      -- Customize or remove this keymap to your liking
      '<leader>fm',
      function()
        require('conform').format({ async = true }, function(err)
          -- Leave visual mode after range format
          -- https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md#leave-visual-mode-after-range-format
          if not err then
            local mode = vim.api.nvim_get_mode().mode
            if vim.startswith(string.lower(mode), 'v') then
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
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
      timeout_ms = 3000,
      async = false, -- not recommended to change
      quiet = false, -- not recommended to change
      lsp_format = 'fallback', -- not recommended to change
    },
    format_on_save = function(bufnr)
      -- Disable autoformat on certain filetypes
      local ignore_filetypes = {}
      if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
        return
      end
      -- Disable with a global or buffer-local variable
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      -- Disable autoformat for files in a certain path
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if bufname:match('/node_modules/') then
        return
      end

      return {
        -- These options will be passed to conform.format()
        timeout_ms = 500,
        lsp_format = 'fallback',
      }
    end,
    formatters_by_ft = {
      openscad = { lsp_format = 'prefer' },
      lua = { 'stylua' },
      -- You can customize some of the format options for the filetype (:help conform.format)
      rust = { 'rustfmt', lsp_format = 'fallback' },
      nix = { 'alejandra' },
      json = { 'prettier', lsp_format = 'fallback' },
      jsonc = { 'prettier', lsp_format = 'fallback' },
      markdown = { 'prettier', 'injected' },
      yaml = { 'prettier' },
      glsl = { lsp_format = 'fallback' },
      wgsl = { 'wgslfmt', lsp_format = 'fallback' },
      gitcommit = { 'commitmsgfmt', lsp_format = 'fallback' },
      -- Conform will run the first available formatter
      javascript = function(bufnr)
        return { first(bufnr, 'prettier', 'biome'), 'injected' }
      end,
      javascriptreact = function(bufnr)
        return { first(bufnr, 'prettier', 'biome'), 'injected' }
      end,
      typescript = function(bufnr)
        return { first(bufnr, 'prettier', 'biome'), 'injected' }
      end,
      typescriptreact = function(bufnr)
        return { first(bufnr, 'prettier', 'biome'), 'injected' }
      end,
    },
    formatters = {
      injected = {
        options = {
          ignore_errors = true,
          -- Map of treesitter language to filetype
          lang_to_ft = {
            bash = 'sh',
          },
          -- Map of treesitter language to file extension
          -- A temporary filename with this extension will be generated during formatting
          -- because some formatters care about the filename.
          lang_to_ext = {
            bash = 'sh',
            c_sharp = 'cs',
            elixir = 'exs',
            javascript = 'js',
            javascriptreact = 'jsx',
            latex = 'tex',
            markdown = 'md',
            python = 'py',
            ruby = 'rb',
            rust = 'rs',
            teal = 'tl',
            typescript = 'ts',
            typescriptreact = 'tsx',
          },
          lang_to_formatters = {},
        },
      },
      wgslfmt = {
        command = 'wgslfmt',
      },
      commitmsgfmt = {
        command = 'commitmsgfmt',
      },
      prettier = {
        command = function(self, bufnr)
          local util = require('conform.util')
          local fs = require('conform.fs')
          local cmd = util.find_executable({ '.yarn/sdks/prettier/bin/prettier.cjs' }, 'prettier')(self, bufnr)
          if cmd ~= '' then
            return cmd
          end
          -- return type of util.from_node_modules is fun(self: conform.FormatterConfig, ctx: conform.Context): string
          ---@diagnostic disable-next-line
          return util.from_node_modules(fs.is_windows and 'prettier.cmd' or 'prettier')(self, bufnr)
        end,
      },
    },
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    -- Format command
    vim.api.nvim_create_user_command('Format', function(args)
      local range = nil
      if args.count ~= -1 then
        local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
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
