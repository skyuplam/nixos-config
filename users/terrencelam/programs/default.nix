{
  imports = [
    ./dev
  ];

  programs = {
    bash = {
      enable = true;
    };
    neovim = {
      enable = true;
      defaultEditor = true;
    };
  };
}
