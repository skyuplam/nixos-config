{lib, ...}: {
  programs.nixvim = {
    plugins.telescope = {
      enable = true;

      extensions = {
        frecency = {
          enable = true;
          settings = {
            auto_validate = true;
            db_root = {
              __raw = ''
                vim.fn.stdpath("data") .. "/nvim"
              '';
            };
            db_safe_mode = true;
            db_validate_threshold = 10;
            ignore_patterns = [
              "*.git/*"
              "*/tmp/*"
              "term://*"
            ];
          };
        };
        fzf-native = {
          enable = true;
          settings = {
            fuzzy = true;
            override_generic_sorter = true; # override the generic sorter
            override_file_sorter = true; # override the file sorter
            case_moe = "smart_case"; # or 'ignore_case' or 'respect_case'
          };
        };
        live-grep-args = {
          enable = true;
          settings = {
            auto_quoting = true;
            mappings = {
              i = {
                "<C-k>" = {
                  __raw = ''
                    require("telescope-live-grep-args.actions").quote_prompt()
                  '';
                };
                "<C-i>" = {
                  __raw = ''
                    require("telescope-live-grep-args.actions").quote_prompt({ postfix = " --iglob " })
                  '';
                };
                # freeze the current list a start a fuzzy search in the frozen list
                "<C-space>" = {
                  __raw = ''
                    require("telescope.actions").to_fuzzy_refine
                  '';
                };
              };
            };
          };
        };
        manix.enable = true;
        media-files.enable = true;
        ui-select.enable = true;
        undo.enable = true;
      };

      settings.defaults = {
        file_ignore_patterns = [
          "^.git/"
          "^.mypy_cache/"
          "^__pycache__/"
          "^output/"
          "^data/"
          "%.ipynb"
        ];
        set_env.COLORTERM = "truecolor";
        layout_strategy = "flex";
        layout_config = {
          height = 0.95;
          width = 0.95;
          flex = {
            flip_columns = 220;
            flip_lines = 20;
          };
          horizontal = {preview_width = 0.5;};
          vertical = {preview_height = 0.7;};
        };
      };
    };

    keymaps =
      lib.mapAttrsToList (key: mapping: {
        mode = "n";
        inherit key;
        action =
          mapping.action;
        options.desc = mapping.desc;
      }) {
        "<leader><leader>" = {
          action = "<cmd>Telescope resume<CR>";
          desc = "Resume Telescope";
        };
        "<leader>ff" = {
          action = "<cmd>Telescope find_files<CR>";
          desc = "Find files";
        };
        "<leader>fo" = {
          action = "<cmd>Telescope oldfiles<CR>";
          desc = "Find old files";
        };
        "<leader>fb" = {
          action = "<cmd>Telescope buffers<CR>";
          desc = "Buffers";
        };
        "<leader>fc" = {
          action = "<cmd>Telescope command_history<CR>";
          desc = "Command history";
        };
        "<leader>fq" = {
          action = "<cmd>Telescope quickfix<CR>";
          desc = "Quickfix list";
        };
        "<leader>fj" = {
          action = "<cmd>Telescope jumplist<CR>";
          desc = "Jump list";
        };
        "<leader>fd" = {
          action = "<cmd>Telescope git_status<CR>";
          desc = "Git status";
        };
        "<leader>fg" = {
          action = "<cmd>Telescope live_grep_args<CR>";
          desc = "Grep files";
        };
        "<leader>fG" = {
          action = "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args({ search_dirs = { '%:p:h' } })<CR>";
          desc = "Grep files from current directory";
        };
        "<leader>fw" = {
          action = "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor()<CR>";
          desc = "Grep with word under cursor";
        };
        "<leader>fW" = {
          action = "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_under_cursor_current_buffer()<CR>";
          desc = "Grep with word under cursor for the current buffer";
        };
        "<leader>fr" = {
          action = "<cmd>Telescope registers<CR>";
          desc = "Registers";
        };
        "<leader>fz" = {
          action = "<cmd>Telescope spell_suggest<CR>";
          desc = "Spell suggest";
        };
        "<leader>ft" = {
          action = "<cmd>Telescope filetypes<CR>";
          desc = "File types";
        };
        "<leader>fs" = {
          action = "<cmd>Telescope current_buffer_fuzzy_find<CR>";
          desc = "File current buffer";
        };
        "<leader>gd" = {
          action = "<cmd>Telescope lsp_definitions<CR>";
          desc = "List LSP definitions";
        };
        "<leader>gD" = {
          action = "<cmd>Telescope lsp_references<CR>";
          desc = "List LSP references";
        };
        "<leader>gt" = {
          action = "<cmd>Telescope lsp_type_definitions<CR>";
          desc = "List LSP Type definitions";
        };
        "<leader>gi" = {
          action = "<cmd>Telescope lsp_implementations<CR>";
          desc = "List LSP implementations";
        };
        "<leader>gc" = {
          action = "<cmd>Telescope lsp_incoming_calls<CR>";
          desc = "List LSP incoming calls";
        };
        "<leader>gC" = {
          action = "<cmd>Telescope lsp_outgoing_calls<CR>";
          desc = "List LSP outgoing calls";
        };
        "<leader>gl" = {
          action = "<cmd>Telescope diagnostics<CR>";
          desc = "List Disagnostics";
        };
        "<leader>gL" = {
          action = "<cmd>Telescope diagnostics bufnr=0<CR>";
          desc = "List Disagnostics for current buffer";
        };
        "<leader>go" = {
          action = "<cmd>Telescope aerial<CR>";
          desc = "Outline Symbols";
        };
      }
      ++ lib.mapAttrsToList (key: mapping: {
        mode = "v";
        inherit key;
        action =
          mapping.action;
        options.desc = mapping.desc;
      }) {
        "<leader>fw" = {
          action = "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_visual_selection()<CR>";
          desc = "Grep with selection";
        };
        "<leader>fW" = {
          action = "<cmd>lua require('telescope-live-grep-args.shortcuts').grep_word_visual_selection_current_buffer()<CR>";
          desc = "Grep with selection for the current buffer";
        };
      };
  };
}
