{pkgs, ...}: {
  programs.nixvim = {
    plugins = {
      treesitter = {
        enable = true;

        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          c
          cmake
          comment
          commonlisp
          corn
          cpp
          css
          csv
          cuda
          diff
          dockerfile
          fennel
          git_config
          git_rebase
          gitattributes
          gitcommit
          gitignore
          glsl
          go
          gomod
          gpg
          hjson
          html
          http
          ini
          javascript
          jq
          jsdoc
          json
          json5
          llvm
          lua
          luadoc
          luap
          make
          markdown
          markdown_inline
          ninja
          nix
          norg
          passwd
          proto
          python
          regex
          rst
          rust
          scss
          ssh_config
          terraform
          toml
          tsx
          typescript
          vim
          vimdoc
          wgsl
          yaml
          yuck
          zig
        ];
        settings = {
          highlight = {
            enable = true;
          };
          indent = {enable = true;};
          matchup = {
            enable = true;
            disable = ["javascript"];
          };
          incremental_selection = {
            enable = true;
          };
        };
      };

      treesitter-context = {
        enable = true;

        settings = {
          enable = true;
        };
      };

      treesitter-textobjects = {
        enable = true;
        lspInterop.enable = true;
        move = {
          enable = true;
          setJumps = true;
        };
        select = {
          enable = true;
        };
      };
    };
  };
}
