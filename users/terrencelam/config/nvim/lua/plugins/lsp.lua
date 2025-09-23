local ts_ls_inlayHints = {
  includeInlayParameterNameHints = 'all',
  includeInlayParameterNameHintsWhenArgumentMatchesName = false,
  includeInlayFunctionParameterTypeHints = true,
  includeInlayVariableTypeHints = false,
  includeInlayPropertyDeclarationTypeHints = false,
  includeInlayFunctionLikeReturnTypeHints = false,
  includeInlayEnumMemberValueHints = false,
}

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    keys = {
      {
        '<leader>xx',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = 'Diagnostics (Trouble)',
      },
      {
        '<leader>xX',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = 'Buffer Diagnostics (Trouble)',
      },
      {
        '<leader>cs',
        '<cmd>Trouble symbols toggle focus=false<cr>',
        desc = 'Symbols (Trouble)',
      },
      {
        '<leader>cl',
        '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
        desc = 'LSP Definitions / references / ... (Trouble)',
      },
      {
        '<leader>xL',
        '<cmd>Trouble loclist toggle<cr>',
        desc = 'Location List (Trouble)',
      },
      {
        '<leader>xQ',
        '<cmd>Trouble qflist toggle<cr>',
        desc = 'Quickfix List (Trouble)',
      },
    },
  },
  opts = {
    ---@type vim.diagnostic.Opts
    diagnostics = {
      severity_sort = true,
      virtual_text = false,
      virtual_lines = { current_line = true },
    },
    -- Enable this to enable the builtin LSP inlay hints on Neovim >= 0.10.0
    -- Be aware that you also will need to properly configure your LSP server to
    -- provide the inlay hints.
    inlay_hints = {
      enabled = true,
      exclude = { 'vue' }, -- filetypes for which you don't want to enable inlay hints
    },
    -- Enable this to enable the builtin LSP code lenses on Neovim >= 0.10.0
    -- Be aware that you also will need to properly configure your LSP server to
    -- provide the code lenses.
    codelens = {
      enabled = true,
    },
    -- add any global capabilities here
    capabilities = {
      workspace = {
        fileOperations = {
          didRename = true,
          willRename = true,
        },
        -- Ensure that dynamicRegistration is enabled! This allows the LS to take into account actions like the
        -- Create Unresolved File code action, resolving completions for unindexed code blocks, ...
        didChangeWatchedFiles = {
          dynamicRegistration = true,
        },
      },
    },
    -- options for vim.lsp.buf.format
    -- `bufnr` and `filter` is handled by the LazyVim formatter,
    -- but can be also overridden when specified
    format = {
      formatting_options = nil,
      timeout_ms = nil,
    },
    -- LSP Server Settings
    ---@type lspconfig.options
    servers = {
      openscad_lsp = {},
      lua_ls = {
        -- mason = false, -- set to false if you don't want this server to be installed with mason
        -- Use this to add any additional keymaps
        -- for specific lsp servers
        -- ---@type LazyKeysSpec[]
        -- keys = {},
        on_init = function(client)
          if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if
              path ~= vim.fn.stdpath('config')
              and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
            then
              return
            end
          end

          client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
              -- Tell the language server which version of Lua you're using
              -- (most likely LuaJIT in the case of Neovim)
              version = 'LuaJIT',
            },
            -- Make the server aware of Neovim runtime files
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME,
                -- Depending on the usage, you might want to add additional paths here.
                -- "${3rd}/luv/library"
                -- "${3rd}/busted/library",
              },
              -- or pull in all of 'runtimepath'. NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
              -- library = vim.api.nvim_get_runtime_file("", true)
            },
          })
        end,
        settings = {
          Lua = {
            workspace = {
              checkThirdParty = false,
            },
            codeLens = {
              enable = true,
            },
            completion = {
              callSnippet = 'Replace',
            },
            doc = {
              privateName = { '^_' },
            },
            hint = {
              enable = true,
              setType = false,
              paramType = true,
              paramName = 'Disable',
              semicolon = 'Disable',
              arrayIndex = 'Disable',
            },
          },
        },
      },
      nil_ls = {},
      statix = {},
      ts_ls = {
        settings = {
          typescript = {
            inlayHints = vim.deepcopy(ts_ls_inlayHints),
          },
          javascript = {
            inlayHints = vim.deepcopy(ts_ls_inlayHints),
          },
        },
      },
      biome = {},
      cssls = {},
      html = {},
      jsonls = {},
      yamlls = {},
      marksman = {},
      markdown_oxide = {},
      harper_ls = {
        settings = {
          ['harper-ls'] = {
            userDictPath = vim.fn.stdpath('data') .. '/spell/en.utf-8.add',
            linters = {
              SentenceCapitalization = false,
              SpellCheck = false,
            },
          },
        },
      },
    },
  },
  config = function(_, opts)
    local lsp = require('utils.lsp')

    lsp.on_attach(require('keymaps.lsp').on_attach)
    lsp.setup()
    lsp.on_dynamic_capability(require('keymaps.lsp').on_attach)

    -- Inlay hints
    if opts.inlay_hints.enabled then
      lsp.on_supports_method('textDocument/inlayHint', function(_, buffer)
        if
          vim.api.nvim_buf_is_valid(buffer)
          and vim.bo[buffer].buftype == ''
          and not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[buffer].filetype)
        then
          vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
        end
      end)
    end
    -- Code lens
    if opts.codelens.enabled and vim.lsp.codelens then
      lsp.on_supports_method('textDocument/codeLens', function(_, buffer)
        vim.lsp.codelens.refresh()
        vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
          buffer = buffer,
          callback = vim.lsp.codelens.refresh,
        })
      end)
    end

    vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
    local servers = opts.servers
    local has_blink, blink = pcall(require, 'blink.cmp')
    local capabilities = vim.tbl_deep_extend(
      'force',
      {},
      vim.lsp.protocol.make_client_capabilities(),
      has_blink and blink.get_lsp_capabilities({}, false) or {},
      opts.capabilities or {}
    )

    local function setup(server)
      local server_opts = vim.tbl_deep_extend('force', {
        capabilities = vim.deepcopy(capabilities),
      }, servers[server] or {})
      if server_opts.enabled == false then
        return
      end

      vim.lsp.config(server, server_opts)
      vim.lsp.enable(server)
    end

    for server, server_opts in pairs(servers) do
      if server_opts then
        server_opts = server_opts == true and {} or server_opts
        if server_opts.enabled ~= false then
          setup(server)
        end
      end
    end
  end,
}
