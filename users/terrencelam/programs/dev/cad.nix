{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      openscad-lsp
    ];
  };
}
