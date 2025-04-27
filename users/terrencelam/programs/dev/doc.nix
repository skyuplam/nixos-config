{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      harper # Language LSP
      marksman # Markdown language server
    ];
  };
}
