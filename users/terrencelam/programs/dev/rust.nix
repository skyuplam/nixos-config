{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      graphviz
      rustup
      wasm-bindgen-cli
      binaryen
    ];
  };
}
