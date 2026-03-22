{
  name,
  inputs,
  isWSL,
  ...
}: {
  imports = [
    (
      import ./common.nix {
        inherit inputs;
        inherit isWSL;
      }
    )
    (import ./${name}.nix {
      inherit inputs;
      inherit isWSL;
    })
  ];
}
