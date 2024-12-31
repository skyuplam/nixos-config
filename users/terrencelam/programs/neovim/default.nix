{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./plugins
    ./autoCmd.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
  };
}
