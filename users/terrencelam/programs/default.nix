{ inputs, ... }: {
  imports = [
    ./dev
    ./neovim
  ];

  programs = {
      bash = {
        enable = true;
      };
  };
}
