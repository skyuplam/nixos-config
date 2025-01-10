{lib, ...}: {
  programs.nixvim = {
    plugins.yazi = {
      enable = true;
      settings = {
        open_for_directories = true;
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
        "<C-e>" = {
          action = "<cmd>Yazi<CR>";
          desc = "File explorer";
        };
        "<C-S-E>" = {
          action = "<cmd>Yazi cwd<CR>";
          desc = "File explorer (cwd)";
        };
      };
  };
}
