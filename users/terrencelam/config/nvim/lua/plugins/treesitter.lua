return {
  'nvim-treesitter/nvim-treesitter',
  version = false, -- last release is way too old and doesn't work on Windows
  build = ':TSUpdate',
  event = { 'VeryLazy' },
  lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
  cmd = { 'TSUpdateSync', 'TSUpdate', 'TSInstall' },
  config = function()
    local configs = require('nvim-treesitter.configs')

    configs.setup({
      ensure_installed = {
        'bash',
        'c',
        'cmake',
        'comment',
        'commonlisp',
        'corn',
        'cpp',
        'css',
        'csv',
        'cuda',
        'diff',
        'dockerfile',
        'elixir',
        'fennel',
        'git_config',
        'git_rebase',
        'gitattributes',
        'gitcommit',
        'gitignore',
        'glsl',
        'go',
        'gomod',
        'gpg',
        'heex',
        'hjson',
        'html',
        'html',
        'http',
        'ini',
        'javascript',
        'jq',
        'jsdoc',
        'json',
        'json5',
        'llvm',
        'lua',
        'luadoc',
        'luap',
        'make',
        'markdown',
        'markdown_inline',
        'ninja',
        'nix',
        'norg',
        'passwd',
        'proto',
        'python',
        'query',
        'regex',
        'rst',
        'rust',
        'scss',
        'ssh_config',
        'terraform',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'wgsl',
        'yaml',
        'yuck',
        'zig',
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<C-space>',
          node_incremental = '<C-space>',
          scope_incremental = false,
          node_decremental = '<bs>',
        },
      },
      textobjects = {
        move = {
          enable = true,
          goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer', [']a'] = '@parameter.inner' },
          goto_next_end = { [']F'] = '@function.outer', [']C'] = '@class.outer', [']A'] = '@parameter.inner' },
          goto_previous_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer', ['[a'] = '@parameter.inner' },
          goto_previous_end = { ['[F'] = '@function.outer', ['[C'] = '@class.outer', ['[A'] = '@parameter.inner' },
        },
      },
      sync_install = false,
      highlight = { enable = true },
      indent = { enable = true },
      matchup = { enable = true },
    })
  end,
  dependencies = {
    {
      'nvim-treesitter/nvim-treesitter-textobjects',
      event = 'VeryLazy',
      enabled = true,
      config = function()
        -- When in diff mode, we want to use the default
        -- vim text objects c & C instead of the treesitter ones.
        local move = require('nvim-treesitter.textobjects.move') ---@type table<string,fun(...)>
        local configs = require('nvim-treesitter.configs')
        for name, fn in pairs(move) do
          if name:find('goto') == 1 then
            move[name] = function(q, ...)
              if vim.wo.diff then
                local config = configs.get_module('textobjects.move')[name] ---@type table<string,string>
                for key, query in pairs(config or {}) do
                  if q == query and key:find('[%]%[][cC]') then
                    vim.cmd('normal! ' .. key)
                    return
                  end
                end
              end
              return fn(q, ...)
            end
          end
        end
      end,
    },
    {
      'windwp/nvim-ts-autotag',
      opts = {},
    },
    { 'andymass/vim-matchup' },
  },
}
