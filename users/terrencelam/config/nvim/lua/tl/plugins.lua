-- vim: set foldmethod=marker foldlevel=0 nomodeline:
-- This file can be loaded by calling `lua require('plugins')` from your init.vim
-- ============================================================================
--  Plugins {{{
-- ============================================================================
return require('lazy').setup({
  {
    'tpope/vim-dispatch',
    lazy = true,
    cmd = { 'Dispatch', 'Make', 'Focus', 'Start' },
  },
  { 'sheerun/vim-polyglot' },
  { 'elkowar/yuck.vim' },
  {
    'nvim-treesitter/nvim-treesitter',
    build = function()
      local ts_update = require('nvim-treesitter.install').update({
        with_sync = true,
      })
      ts_update()
    end,
    config = function()
      require('tl.treesitter').setup()
    end,
    dependencies = {
      { 'nvim-treesitter/nvim-treesitter-refactor' },
      { 'nvim-treesitter/nvim-treesitter-textobjects' },
      { 'nvim-treesitter/nvim-treesitter-context' },
    },
  },
  { 'folke/tokyonight.nvim', lazy = false, priority = 1000, opts = {} },
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    event = 'BufReadPost',
    opts = {},

    init = function()
      -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
      vim.keymap.set('n', 'zR', function()
        require('ufo').openAllFolds()
      end)
      vim.keymap.set('n', 'zM', function()
        require('ufo').closeAllFolds()
      end)
    end,
    config = function()
      require('ufo').setup()
    end,
  },
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {},
  },
  { 'vim-jp/syntax-vim-ex' },
  {
    'm-demare/hlargs.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
  },

  { 'kevinhwang91/nvim-bqf' },

  { 'Shougo/vimproc.vim', build = ':silent! !make' },
  { 'vim-scripts/vis' },
  { 'editorconfig/editorconfig-vim' },

  { 'mbbill/undotree' },

  { 'tpope/vim-rhubarb' },

  -- Neovim setup for init.lua and plugin development with full signature help,
  -- docs and completion for the nvim lua API
  { 'folke/neodev.nvim' },
  {
    'ThePrimeagen/refactoring.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('refactoring').setup()

      local map = require('tl.common').map
      -- Extract block supports only normal mode
      map({ 'n', 'x' }, '<leader>rr', function()
        require('refactoring').select_refactor()
      end)
    end,
  },

  { 'godlygeek/tabular' },

  { 'kamykn/spelunker.vim' },

  -- Marks
  -- Quickfix
  { 'Olical/vim-enmasse', cmd = 'EnMasse' },

  { 'tpope/vim-repeat' },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      {
        'nvim-telescope/telescope-frecency.nvim',
        dependencies = { 'tami5/sqlite.lua' },
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-telescope/telescope-live-grep-args.nvim' },
      {
        'nvim-telescope/telescope-smart-history.nvim',
        dependencies = { 'tami5/sqlite.lua' },
      },
      {
        'nvim-telescope/telescope-media-files.nvim',
        dependencies = {
          'nvim-lua/plenary.nvim',
          'nvim-lua/popup.nvim',
        },
      },
    },
    config = function()
      require('tl.telescope').setup()
    end,
  },
  { 'ryanoasis/vim-devicons' },

  {
    dir = '~/dev/vim-redact-pass',
    event = 'VimEnter /private$TMPDIR/pass.?*/?*.txt,/dev/shm/pass.?*/?*.txt',
  },

  -- Clipboard manager
  {
    'AckslD/nvim-neoclip.lua',
    dependencies = {
      { 'nvim-telescope/telescope.nvim' },
    },
    config = function()
      require('neoclip').setup()
    end,
  },

  { 'junegunn/vim-slash' },
  { 'junegunn/gv.vim' },
  { 'junegunn/vim-peekaboo' },
  { 'junegunn/vim-easy-align' },

  { 'vim-scripts/utl.vim' },
  { 'majutsushi/tagbar' },
  { 'tpope/vim-speeddating' },
  { 'chrisbra/NrrwRgn' },
  { 'mattn/calendar-vim' },
  { 'inkarkat/vim-SyntaxRange' },

  {
    'gen740/SmoothCursor.nvim',
    config = function()
      require('smoothcursor').setup({
        disable_float_win = true,
        priority = 100,
        autostart = true,
        threshold = 1,
        speed = 30,
        type = 'default',
        intervals = 50,
        fancy = {
          enable = true,
          head = { cursor = '', texthl = 'SmoothCursor' },
          body = {
            { cursor = '●', texthl = 'SmoothCursorBody' },
            { cursor = '●', texthl = 'SmoothCursorBody' },
            { cursor = '•', texthl = 'SmoothCursorBody' },
            { cursor = '•', texthl = 'SmoothCursorBody' },
            { cursor = '∙', texthl = 'SmoothCursorBody' },
            { cursor = '∙', texthl = 'SmoothCursorBody' },
          },
        },
      })

      local autocmd = vim.api.nvim_create_autocmd
      local augroup = vim.api.nvim_create_augroup('CursorModeChangeGroup', {})

      vim.api.nvim_clear_autocmds({ group = augroup })
      autocmd({ 'ModeChanged' }, {
        group = augroup,
        callback = function()
          local current_mode = vim.fn.mode()
          if current_mode == 'n' then
            vim.api.nvim_set_hl(0, 'SmoothCursor', { fg = '#8aa872' })
            vim.api.nvim_set_hl(0, 'SmoothCursorBody', { fg = '#8aa872' })
            vim.fn.sign_define('smoothcursor', { text = '' })
          elseif current_mode == 'v' then
            vim.api.nvim_set_hl(0, 'SmoothCursor', { fg = '#bf616a' })
            vim.api.nvim_set_hl(0, 'SmoothCursorBody', { fg = '#bf616a' })
            vim.fn.sign_define('smoothcursor', { text = '' })
          elseif current_mode == 'V' then
            vim.api.nvim_set_hl(0, 'SmoothCursor', { fg = '#bf616a' })
            vim.api.nvim_set_hl(0, 'SmoothCursorBody', { fg = '#bf616a' })
            vim.fn.sign_define('smoothcursor', { text = '' })
          elseif current_mode == '' then
            vim.api.nvim_set_hl(0, 'SmoothCursor', { fg = '#bf616a' })
            vim.api.nvim_set_hl(0, 'SmoothCursorBody', { fg = '#bf616a' })
            vim.fn.sign_define('smoothcursor', { text = '' })
          elseif current_mode == 'i' then
            vim.api.nvim_set_hl(0, 'SmoothCursor', { fg = '#668aab' })
            vim.api.nvim_set_hl(0, 'SmoothCursorBoby', { fg = '#668aab' })
            vim.fn.sign_define('smoothcursor', { text = '' })
          end
        end,
      })
    end,
  },

  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup({})
      require('mini.align').setup({})
      require('mini.surround').setup({})
      require('mini.bufremove').setup({})
      require('mini.cursorword').setup({})
      require('mini.indentscope').setup({
        draw = {
          delay = 0,
          animation = require('mini.indentscope').gen_animation.none(),
        },
      })
      require('mini.misc').setup({ make_global = { 'zoom' } })
      require('tl.common').map(
        'n',
        '<leader>zz',
        zoom,
        { desc = 'Toggle zoom current buffer' }
      )
    end,
  },

  {
    'nvim-pack/nvim-spectre',
    cmd = 'Spectre',
    opts = { open_cmd = 'noswapfile vnew' },
    keys = {
      {
        '<leader>sr',
        function()
          require('spectre').open()
        end,
        desc = 'Replace in files (Spectre)',
      },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },

  -- Color tool
  {
    'norcalli/nvim-colorizer.lua',
    config = function()
      require('colorizer').setup({ 'css', 'html', 'typescript' })
    end,
  },

  -- Snippets
  {
    'saadparwaiz1/cmp_luasnip',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        config = function()
          require('luasnip.loaders.from_vscode').lazy_load()
        end,
        dependencies = { 'rafamadriz/friendly-snippets' },
        build = 'make install_jsregexp',
      },
      {
        'numToStr/Comment.nvim',
        opts = {},
      },
    },
  },

  {
    'rcarriga/nvim-notify',
    config = function()
      local notify = require('notify')
      notify.setup()
      vim.notify = notify
    end,
  },

  -- {
  --   'Exafunction/codeium.nvim',
  --   cmd = 'Codeium',
  --   build = ':Codeium Auth',
  --   dependencies = {
  --     'nvim-lua/plenary.nvim',
  --     'hrsh7th/nvim-cmp',
  --   },
  --   config = function()
  --     require('codeium').setup({
  --       tools = {
  --         language_server = vim.fn.expand('$CODEIUM_PATH'),
  --       },
  --     })
  --   end,
  -- },

  {
    'nvim-neorg/neorg',
    build = ':Neorg sync-parsers',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-neorg/neorg-telescope',
    },
    config = function()
      require('neorg').setup({
        load = {
          ['core.esupports.metagen'] = {
            config = { type = 'auto', update_date = true },
          },
          ['core.defaults'] = {}, -- Loads default behaviour
          ['core.concealer'] = {}, -- Adds pretty icons to your documents
          ['core.completion'] = { config = { engine = 'nvim-cmp' } }, -- Adds pretty icons to your documents
          ['core.ui.calendar'] = {}, -- Adds pretty icons to your documents
          ['core.dirman'] = { -- Manages Neorg workspaces
            config = {
              workspaces = {
                notes = '~/notes/home',
              },
              default_workspace = 'notes',
            },
          },
          ['core.journal'] = {
            config = { strategy = 'flat', workspace = 'notes' },
          }, -- Adds pretty icons to your documents
          ['core.integrations.telescope'] = {},
          ['core.keybinds'] = {
            config = {
              hook = function(keybinds)
                -- Map all the below keybinds only when the "norg" mode is active
                keybinds.map_event_to_mode('norg', {
                  n = { -- Bind keys in normal mode
                    {
                      '<C-s>',
                      'core.integrations.telescope.find_linkable',
                      opts = { desc = 'Find Linkable' },
                    },
                  },
                  i = { -- Bind in insert mode
                    {
                      '<C-l>',
                      'core.integrations.telescope.insert_link',
                      opts = { desc = 'Insert Link' },
                    },
                  },
                }, {
                  silent = true,
                  noremap = true,
                })
              end,
            },
          },
        },
      })
      local map = require('tl.common').map
      map(
        'n',
        '<leader>nn',
        ':Neorg workspace notes<cr>',
        { desc = 'Neorg notes' }
      )
      -- temp workaround for ft issue
      vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
        pattern = { '*.norg' },
        callback = function()
          vim.opt.ft = 'norg'
        end,
      })
    end,
  },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    config = function()
      require('tl.lsp')
    end,
    dependencies = {
      { 'lbrayner/vim-rzip' }, -- https://yarnpkg.com/getting-started/editor-sdks#supporting-go-to-definition-et-al
      { 'mrcjkb/rustaceanvim', version = '^3', ft = 'rust' },
      { 'ray-x/lsp_signature.nvim' },
      { 'folke/lsp-colors.nvim' },
      { 'b0o/schemastore.nvim' },
      { 'p00f/clangd_extensions.nvim' },
      {
        'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
        config = function()
          require('lsp_lines').setup()
          local map = require('tl.common').map
          map(
            'n',
            '<Leader>ll',
            require('lsp_lines').toggle,
            { desc = 'Toggle lsp_lines' }
          )
        end,
      },
      {
        'VidocqH/lsp-lens.nvim',
        config = function()
          require('lsp-lens').setup({})
        end,
      },
      {
        'smjonas/inc-rename.nvim',
        config = function()
          require('inc_rename').setup()
        end,
      },
      {
        'j-hui/fidget.nvim',
        config = function()
          require('fidget').setup()
        end,
        tag = 'legacy',
      },
      {
        'folke/trouble.nvim',
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function()
          require('trouble').setup({})
        end,
      },
      {
        'simrat39/symbols-outline.nvim',
        keys = {
          { '<leader>cs', '<cmd>SymbolsOutline<cr>', desc = 'Symbols Outline' },
        },
        cmd = 'SymbolsOutline',
        opts = {},
      },
    },
  },

  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        -- Customize or remove this keymap to your liking
        '<leader>lf',
        function()
          require('conform').format({ async = true, lsp_fallback = true })
        end,
        mode = '',
        desc = 'Format buffer',
      },
    },
    opts = function()
      local is_pnp = vim.fn.findfile('.pnp.cjs', '.;') ~= ''

      local prettier = require('conform.formatters.prettier')
      if is_pnp then
        local yarn_bin = vim.fn.system('yarn bin prettier'):gsub('%s+', '')
        prettier.command = 'node'
        prettier.prepend_args = { yarn_bin }
      end
      return {
        formatters_by_ft = {
          -- https://github.com/JohnnyMorganz/StyLua
          lua = { 'stylua' },
          -- https://github.com/ziglang/zig
          zig = { 'zigfmt' },
          nix = { 'alejandra' },
          javascript = { { 'prettier', 'biome' } },
          typescript = { { 'prettier', 'biome' } },
          javascriptreact = { { 'prettier', 'biome' } },
          typescriptreact = { { 'prettier', 'biome' } },
          json = { { 'prettier', 'biome' } },
          jsonc = { { 'prettier', 'biome' } },
          markdown = { { 'prettier', 'biome' } },
          c = { 'clang-format' },
          cpp = { 'clang-format' },
          rust = { 'rustfmt' },
          -- Use the "*" filetype to run formatters on all filetypes.
          ['*'] = { 'codespell' },
          -- Use the "_" filetype to run formatters on filetypes that don't
          -- have other formatters configured.
          ['_'] = { 'trim_whitespace' },
        },
        formatters = {
          rustfmt = {
            prepend_args = { '--edition=2021' },
          },
          prettier = prettier,
        },
        format_on_save = {
          -- These options will be passed to conform.format()
          timeout_ms = 500,
          lsp_fallback = true,
        },
        -- Map of treesitter language to file extension
        -- A temporary file name with this extension will be generated during formatting
        -- because some formatters care about the filename.
        lang_to_ext = {
          bash = 'sh',
          javascript = 'js',
          julia = 'jl',
          latex = 'tex',
          markdown = 'md',
          python = 'py',
          rust = 'rs',
          typescript = 'ts',
        },
      }
    end,
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
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
          lsp_fallback = true,
          range = range,
        })
      end, { range = true })
    end,
  },

  -- https://github.com/LazyVim/LazyVim/blob/a50f92f7550fb6e9f21c0852e6cb190e6fcd50f5/lua/lazyvim/plugins/linting.lua#L5
  {
    'mfussenegger/nvim-lint',
    opts = {
      events = { 'BufWritePost', 'BufReadPost', 'InsertLeave' },
      linters_by_ft = {
        sh = { 'shellcheck' },
        nix = { 'statix' },
        c = { 'clang_check' },
        cpp = { 'clang_check' },
        -- Use the "*" filetype to run linters on all filetypes.
        -- ['*'] = { 'global linter' },
        -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
        -- ['_'] = { 'fallback linter' },
      },
      linters = {
        -- -- Example of using selene only when a selene.toml file is present
        selene = {
          -- `condition` is another LazyVim extension that allows you to
          -- dynamically enable/disable linters based on the context.
          condition = function(ctx)
            return vim.fs.find(
              { 'selene.toml' },
              { path = ctx.filename, upward = true }
            )[1]
          end,
        },
      },
    },
    config = function(_, opts)
      local lint = require('lint')
      local M = {}

      for name, linter in pairs(opts.linters) do
        if type(linter) == 'table' and type(lint.linters[name]) == 'table' then
          lint.linters[name] =
            vim.tbl_deep_extend('force', lint.linters[name], linter)
        else
          lint.linters[name] = linter
        end
      end

      lint.linters_by_ft = opts.linters_by_ft

      function M.debounce(ms, fn)
        local timer = vim.loop.new_timer()
        return function(...)
          local argv = { ... }
          timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
          end)
        end
      end

      function M.lint()
        -- Use nvim-lint's logic first:
        -- * checks if linters exist for the full filetype first
        -- * otherwise will split filetype by "." and add all those linters
        -- * this differs from conform.nvim which only uses the first filetype that has a formatter
        local names = lint._resolve_linter_by_ft(vim.bo.filetype)

        -- Add fallback linters.
        if #names == 0 then
          vim.list_extend(names, lint.linters_by_ft['_'] or {})
        end

        -- Add global linters.
        vim.list_extend(names, lint.linters_by_ft['*'] or {})

        -- Filter out linters that don't exist or don't match the condition.
        local ctx = { filename = vim.api.nvim_buf_get_name(0) }
        ctx.dirname = vim.fn.fnamemodify(ctx.filename, ':h')
        names = vim.tbl_filter(function(name)
          local linter = lint.linters[name]
          if not linter then
            vim.notify('Linter not found: ' .. name, { title = 'nvim-lint' })
          end
          return linter
            and not (
              type(linter) == 'table'
              and linter.condition
              and not linter.condition(ctx)
            )
        end, names)

        -- Run linters.
        if #names > 0 then
          lint.try_lint(names)
        end
      end

      vim.api.nvim_create_autocmd(opts.events, {
        group = vim.api.nvim_create_augroup('nvim-lint', { clear = true }),
        callback = M.debounce(100, M.lint),
      })
    end,
  },

  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    build = ':Copilot auth',
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
  },

  {
    'hrsh7th/nvim-cmp',
    version = false,
    event = 'InsertEnter',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lsp-document-symbol',
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'petertriho/cmp-git',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'hrsh7th/cmp-nvim-lua',
      'andersevenrud/cmp-tmux',
      'ray-x/cmp-treesitter',
      'onsails/lspkind-nvim',
      'dmitmel/cmp-cmdline-history',
      'f3fora/cmp-spell',
      'lukas-reineke/cmp-rg',
      -- copilot cmp source
      {
        'zbirenbaum/copilot-cmp',
        dependencies = 'copilot.lua',
      },
    },
  },

  {
    {
      'lewis6991/gitsigns.nvim',
      config = function()
        require('gitsigns').setup({
          signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
          numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
          linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
          _threaded_diff = true, -- Run diffs on a separate thread
          _extmark_signs = true, -- Use extmarks for placing signs
          word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
          watch_gitdir = { interval = 1000, follow_files = true },
          attach_to_untracked = true,

          on_attach = function(bufnr)
            local gs = package.loaded.gitsigns

            local map = require('tl.common').map

            -- Navigation
            map('n', ']c', function()
              if vim.wo.diff then
                return ']c'
              end
              vim.schedule(function()
                gs.next_hunk()
              end)
              return '<Ignore>'
            end, {
              expr = true,
              buffer = bufnr,
              desc = 'Git next hunk',
            })

            map('n', '[c', function()
              if vim.wo.diff then
                return '[c'
              end
              vim.schedule(function()
                gs.prev_hunk()
              end)
              return '<Ignore>'
            end, {
              expr = true,
              buffer = bufnr,
              desc = 'Git prev hunk',
            })

            -- Actions
            map(
              { 'n', 'v' },
              '<leader>hs',
              ':Gitsigns stage_hunk<CR>',
              { buffer = bufnr, desc = 'Git stage hunk' }
            )
            map(
              { 'n', 'v' },
              '<leader>hr',
              ':Gitsigns reset_hunk<CR>',
              { buffer = bufnr, desc = 'Git reset hunk' }
            )
            map(
              'n',
              '<leader>hS',
              gs.stage_buffer,
              { buffer = bufnr, desc = 'Git stage buffer' }
            )
            map(
              'n',
              '<leader>hu',
              gs.undo_stage_hunk,
              { buffer = bufnr, desc = 'Git undo stage hunk' }
            )
            map(
              'n',
              '<leader>hR',
              gs.reset_buffer,
              { buffer = bufnr, desc = 'Git reset buffer' }
            )
            map(
              'n',
              '<leader>hp',
              gs.preview_hunk,
              { buffer = bufnr, desc = 'Git preview hunk' }
            )
            map('n', '<leader>hb', function()
              gs.blame_line({ full = true })
            end, { buffer = bufnr, desc = 'Git blame line full' })
            map('n', '<leader>tb', gs.toggle_current_line_blame, {
              buffer = bufnr,
              desc = 'Git toggle current line blame',
            })
            map('n', '<leader>hd', gs.diffthis, {
              buffer = bufnr,
              desc = 'Git diffthis against the index',
            })
            map('n', '<leader>hD', function()
              gs.diffthis('~')
            end, {
              buffer = bufnr,
              desc = 'Git diffthis against the last commit',
            })
            map(
              'n',
              '<leader>td',
              gs.toggle_deleted,
              { buffer = bufnr, desc = 'Git toggle show deleted' }
            )

            -- Text object
            map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
          end,
          current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
          current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
            ignore_whitespace = false,
          },
          current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
          sign_priority = 6,
          update_debounce = 100,
          status_formatter = nil, -- Use default
          max_file_length = 40000,
          preview_config = {
            -- Options passed to nvim_open_win
            border = tl.style.current.border,
          },
          yadm = { enable = false },
        })
      end,
      dependencies = { 'nvim-lua/plenary.nvim' },
    },
    { 'sindrets/diffview.nvim', dependencies = 'nvim-lua/plenary.nvim' },
  },

  -- Terminal filemanager
  {
    'Rolv-Apneseth/tfm.nvim',
    opts = {
      -- TFM to use
      -- Possible choices: "ranger" | "nnn" | "lf" | "vifm" | "yazi" (default)
      file_manager = 'yazi',
      -- Replace netrw entirely
      -- Default: false
      replace_netrw = true,
      -- Enable creation of commands
      -- Default: false
      -- Commands:
      --   Tfm: selected file(s) will be opened in the current window
      --   TfmSplit: selected file(s) will be opened in a horizontal split
      --   TfmVsplit: selected file(s) will be opened in a vertical split
      --   TfmTabedit: selected file(s) will be opened in a new tab page
      enable_cmds = false,
      -- Custom keybindings only applied within the TFM buffer
      -- Default: {}
      keybindings = {},
      -- Customise UI. The below options are the default
      ui = {
        border = 'rounded',
        height = 1,
        width = 1,
        x = 0.5,
        y = 0.5,
      },
    },
    config = function()
      local map = require('tl.common').map
      local tfm = require('tfm')
      -- Set keymap so you can open the default terminal file manager (yazi)
      map('n', '<C-e>', function()
        tfm.open(vim.fn.expand('%:p:h'))
      end, {
        noremap = true,
        desc = 'Open Yazi follow current buffer',
      })
    end,
  },

  {
    'akinsho/toggleterm.nvim',
    version = '*',
    config = function()
      require('tl.term').setup()
    end,
  },

  -- Build a statusline
  {
    'rebelot/heirline.nvim',
    config = function()
      require('tl.statusline').setup()
    end,
    dependencies = {
      'SmiteshP/nvim-navic',
      'lewis6991/gitsigns.nvim',
      'nvim-tree/nvim-web-devicons',
      'folke/tokyonight.nvim',
    },
  },
  {
    'allaman/kustomize.nvim',
    requires = 'nvim-lua/plenary.nvim',
    ft = 'yaml',
    config = true,
  },
  {
    'AckslD/nvim-FeMaco.lua',
    config = function()
      require('femaco').setup()
    end,
  },
  {
    'toppair/peek.nvim',
    event = { 'VeryLazy' },
    build = 'deno task --quiet build:fast',
    config = function()
      require('peek').setup()
      -- refer to `configuration to change defaults`
      vim.api.nvim_create_user_command('PeekOpen', require('peek').open, {})
      vim.api.nvim_create_user_command('PeekClose', require('peek').close, {})
    end,
  },
})
---}}}
