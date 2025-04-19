{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      stylua # Lua formatter
      lua-language-server
    ];
  };
}
