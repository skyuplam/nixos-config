return {
  'saghen/blink.cmp',
  -- optional: provides snippets for the snippet source
  dependencies = {
    'mikavilpas/blink-ripgrep.nvim',
    'fang2hou/blink-copilot',
    {
      'zbirenbaum/copilot.lua',
      dependencies = {
        'copilotlsp-nvim/copilot-lsp',
        init = function()
          vim.g.copilot_nes_debounce = 500
        end,
      },
      cmd = 'Copilot',
      event = 'InsertEnter',
      opts = {
        suggestion = { enabled = false },
        panel = { enabled = false },
        nes = {
          enabled = true,
          keymap = {
            accept_and_goto = 'enter',
            accept = false,
            dismiss = '<Esc>',
          },
        },
        filetypes = {
          markdown = true,
          help = true,
        },
        server = {
          type = 'binary',
          custom_server_filepath = vim.env.COPILOT_PATH,
        },
        should_attach = function(_, bufname)
          if not vim.bo.buflisted then
            return false
          end
          if vim.bo.buftype ~= '' then
            return false
          end
          if string.match(bufname, 'env') then
            return false
          end
          if string.match(bufname, '^zipfile') then
            return false
          end

          return true
        end,
        server_opts_overrides = {
          settings = {
            advanced = {
              listCount = 10, -- #completions for panel
              inlineSuggestCount = 3, -- #completions for getCompletions
            },
            telemetry = {
              telemetryLevel = 'off',
            },
          },
        },
      },
    },
  },

  -- use a release tag to download pre-built binaries
  version = '1.*',
  -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  -- build = 'cargo build --release',
  -- If you use nix, you can build from source using latest nightly rust with:
  -- build = 'nix run .#build-plugin',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = { preset = 'enter' },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = 'mono',
    },

    signature = {
      enabled = true,
    },

    -- (Default) Only show the documentation popup when manually triggered
    completion = {
      documentation = { auto_show = true },
      ghost_text = { enabled = true },
      menu = {
        draw = {
          components = {
            -- Kind icon with mini.icon
            kind_icon = {
              text = function(ctx)
                local kind_icon, _, _ = require('mini.icons').get('lsp', ctx.kind)
                return kind_icon
              end,
              -- (optional) use highlights from mini.icons
              highlight = function(ctx)
                local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                return hl
              end,
            },
            kind = {
              -- (optional) use highlights from mini.icons
              highlight = function(ctx)
                local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                return hl
              end,
            },
          },
        },
      },
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = { 'lsp', 'path', 'buffer', 'ripgrep', 'copilot', 'cmdline', 'omni' },
      providers = {
        -- Buffer completion from all open buffers
        buffer = {
          opts = {
            -- or (recommended) filter to only "normal" buffers
            get_bufnrs = function()
              return vim.tbl_filter(function(bufnr)
                return vim.bo[bufnr].buftype == ''
              end, vim.api.nvim_list_bufs())
            end,
          },
        },
        copilot = {
          name = 'copilot',
          module = 'blink-copilot',
          score_offset = -100,
          async = true,
          max_items = 3,
        },
        ripgrep = {
          module = 'blink-ripgrep',
          name = 'Ripgrep',
          -- (optional) customize how the results are displayed. Many options
          -- are available - make sure your lua LSP is set up so you get
          -- autocompletion help
          transform_items = function(_, items)
            for _, item in ipairs(items) do
              -- example: append a description to easily distinguish rg results
              item.labelDetails = {
                description = '(rg)',
              }
            end
            return items
          end,
          max_items = 3,
          score_offset = -200,
          opts = {
            backend = {
              -- The backend to use for searching. Defaults to "ripgrep".
              -- Available options:
              -- - "ripgrep", always use ripgrep
              -- - "gitgrep", always use git grep
              -- - "gitgrep-or-ripgrep", use git grep if possible, otherwise
              --   use ripgrep. Uses the same options as the gitgrep backend
              use = 'gitgrep-or-ripgrep',
            },
          },
        },
      },
    },

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = {
      implementation = 'prefer_rust_with_warning',
      sorts = {
        -- 'exact',
        'score',
        'sort_text',
      },
    },
  },
  opts_extend = { 'sources.default' },
}
