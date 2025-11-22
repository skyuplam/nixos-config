return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  config = function(lazy, opts)
    local telescope = require('telescope')
    local lga_actions = require('telescope-live-grep-args.actions')
    local lga_shortcuts = require('telescope-live-grep-args.shortcuts')
    local open_with_trouble = require('trouble.sources.telescope').open

    telescope.setup({
      defaults = {
        mappings = {
          i = {
            ['c-t'] = open_with_trouble,
          },
          n = {
            ['c-t'] = open_with_trouble,
          },
        },
        layout_strategy = 'flex',
        layout_config = {
          height = 0.95,
          width = 0.95,
          flex = {
            flip_columns = 220,
            flip_lines = 20,
          },
          horizontal = { preview_width = 0.5 },
          vertical = { preview_height = 0.7 },
        },
      },
      extensions = {
        live_grep_args = {
          auto_quoting = true, -- enable/disable auto-quoting
          -- define mappings, e.g.
          mappings = { -- extend mappings
            i = {
              ['<C-k>'] = lga_actions.quote_prompt(),
              ['<C-i>'] = lga_actions.quote_prompt({ postfix = ' --iglob ' }),
              -- freeze the current list and start a fuzzy search in the frozen list
              ['<C-space>'] = lga_actions.to_fuzzy_refine,
            },
          },
          -- ... also accepts theme settings, for example:
          -- theme = "dropdown", -- use dropdown theme
          -- theme = { }, -- use own theme spec
          -- layout_config = { mirror=true }, -- mirror preview pane
        },
        ['zf-native'] = {
          -- options for sorting file-like items
          file = {
            -- override default telescope file sorter
            enable = true,

            -- highlight matching text in results
            highlight_results = true,

            -- enable zf filename match priority
            match_filename = true,

            -- optional function to define a sort order when the query is empty
            initial_sort = nil,

            -- set to false to enable case sensitive matching
            smart_case = true,
          },

          -- options for sorting all other items
          generic = {
            -- override default telescope generic item sorter
            enable = true,

            -- highlight matching text in results
            highlight_results = true,

            -- disable zf filename match priority
            match_filename = false,

            -- optional function to define a sort order when the query is empty
            initial_sort = nil,

            -- set to false to enable case sensitive matching
            smart_case = true,
          },
        },
      },
    })

    telescope.load_extension('zf-native')
    telescope.load_extension('live_grep_args')
    telescope.load_extension('frecency')

    -- Workaround for telescope border issue
    -- https://github.com/nvim-telescope/telescope.nvim/issues/3436#issuecomment-2756267300
    vim.api.nvim_create_autocmd('User', {
      pattern = 'TelescopeFindPre',
      callback = function()
        vim.opt_local.winborder = 'none'
        vim.api.nvim_create_autocmd('WinLeave', {
          once = true,
          callback = function()
            vim.opt_local.winborder = 'rounded'
          end,
        })
      end,
    })
    -- stylua: ignore start
    vim.keymap.set('n', '<leader><leader>', '<cmd>Telescope resume<CR>', { desc = 'Resume Telescope' })
    vim.keymap.set('n', '<leader>fG', function() telescope.extensions.live_grep_args.live_grep_args({ search_dirs = { '%:p:h' } }) end, { desc = 'Grep files from current directory' })
    vim.keymap.set('n', '<leader>fW', lga_shortcuts.grep_word_under_cursor_current_buffer, { desc = 'Grep with word under cursor for the current buffer' })
    vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>', { desc = 'Buffers' })
    vim.keymap.set('n', '<leader>fc', '<cmd>Telescope command_history<CR>', { desc = 'Command history' })
    vim.keymap.set('n', '<leader>fd', '<cmd>Telescope git_status<CR>', { desc = 'Git status' })
    -- vim.keymap.set('n', '<leader>ff', function() telescope.extensions.frecency.frecency({ workspace = 'CWD', sorter = require('telescope.config').values.file_sorter() }) end, { desc = 'Find files (frecency)' })
    vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep_args<CR>', { desc = 'Grep files' })
    vim.keymap.set('n', '<leader>fj', '<cmd>Telescope jumplist<CR>', { desc = 'Jump list' })
    vim.keymap.set('n', '<leader>fo', '<cmd>Telescope oldfiles<CR>', { desc = 'Find old files' })
    vim.keymap.set('n', '<leader>fq', '<cmd>Telescope quickfix<CR>', { desc = 'Quickfix list' })
    vim.keymap.set('n', '<leader>fr', '<cmd>Telescope registers<CR>', { desc = 'Registers' })
    vim.keymap.set('n', '<leader>fs', '<cmd>Telescope current_buffer_fuzzy_find<CR>', { desc = 'File current buffer' })
    vim.keymap.set('n', '<leader>ft', '<cmd>Telescope filetypes<CR>', { desc = 'File types' })
    vim.keymap.set('n', '<leader>fw', lga_shortcuts.grep_word_under_cursor, { desc = 'Grep with word under cursor' })
    vim.keymap.set('n', '<leader>fz', '<cmd>Telescope spell_suggest<CR>', { desc = 'Spell suggest' })
    vim.keymap.set('n', '<leader>gC', '<cmd>Telescope lsp_outgoing_calls<CR>', { desc = 'List LSP outgoing calls' })
    vim.keymap.set('n', '<leader>gD', '<cmd>Telescope lsp_references<CR>', { desc = 'List LSP references' })
    vim.keymap.set('n', '<leader>gL', '<cmd>Telescope diagnostics bufnr=0<CR>', { desc = 'List Disagnostics for current buffer' })
    vim.keymap.set('n', '<leader>gc', '<cmd>Telescope lsp_incoming_calls<CR>', { desc = 'List LSP incoming calls' })
    vim.keymap.set('n', '<leader>gd', '<cmd>Telescope lsp_definitions<CR>', { desc = 'List LSP definitions' })
    vim.keymap.set('n', '<leader>gi', '<cmd>Telescope lsp_implementations<CR>', { desc = 'List LSP implementations' })
    vim.keymap.set('n', '<leader>gl', '<cmd>Telescope diagnostics<CR>', { desc = 'List Disagnostics' })
    vim.keymap.set('n', '<leader>go', '<cmd>Telescope aerial<CR>', { desc = 'Outline Symbols' })
    vim.keymap.set('n', '<leader>gt', '<cmd>Telescope lsp_type_definitions<CR>', { desc = 'List LSP Type definitions' })
    vim.keymap.set('v', "<leader>fG", lga_shortcuts.grep_word_visual_selection_current_buffer, { desc = "Grep with selection for the current buffer" })
    vim.keymap.set('v', "<leader>fg", lga_shortcuts.grep_visual_selection, { desc = "Grep with selection" })
    -- stylua: ignore end
  end,
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'natecraddock/telescope-zf-native.nvim' },
    {
      'nvim-telescope/telescope-frecency.nvim',
      -- install the latest stable version
      version = '*',
    },
    { 'nvim-telescope/telescope-live-grep-args.nvim', version = '^1.0.0' },
  },
}
