{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      harper # Language LSP
      marksman # Markdown language server
      markdown-oxide # PKM Markdown Language Server
      commitmsgfmt
    ];
  };
}
