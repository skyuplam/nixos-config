{lib, ...}: {
  programs.nixvim = {
    globals = {
      mapleader = ",";
      maplocalleader = ",";
    };

    keymaps =
      lib.mapAttrsToList (key: mapping: {
        mode = "n";
        inherit key;
        action =
          mapping.action;
        options = mapping.options or {};
      }) {
        "<leader>S" = {
          action = "<cmd>lua require('spectre').toggle()<CR>";
          options.desc = "Toggle Spectre";
        };
        "<leader>sw" = {
          action = "<cmd>lua require('spectre').open_visual({select_word=true})<CR>";
          options.desc = "Search current word";
        };
        "<leader>sp" = {
          action = "<cmd>lua require('spectre').open_file_search({select_word=true})<CR>";
          options.desc = "Search on current file";
        };
      }
      ++ lib.mapAttrsToList (key: mapping: {
        mode = "v";
        inherit key;
        action =
          mapping.action;
        options = mapping.options or {};
      }) {
        "<leader>sw" = {
          action = "<esc><cmd>lua require('spectre').open_visual()<CR>";
          options.desc = "Search current word";
        };
      };
  };
}
