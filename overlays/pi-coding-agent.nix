# Temporary overlay for https://github.com/NixOS/nixpkgs/pull/556088.
# Remove this after pi-coding-agent 0.84.3 reaches the pinned Nixpkgs revision.
final: prev: {
  pi-coding-agent = prev.pi-coding-agent.overrideAttrs (finalAttrs: _previousAttrs: {
    version = "0.84.3";

    src = final.fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      tag = "v${finalAttrs.version}";
      hash = "sha256-fC9pKgP2qD61ae5d7iOqP8anl88J1N1Bq8X8+aAjA2A=";
    };

    npmDepsHash = "sha256-cDx28+c4bwtQpiy5+BCvZhZezoZb4WRqfZj2eoEeMbw=";

    # buildNpmPackage calculated npmDeps before overrideAttrs was applied.
    # Recalculate it using the overridden source and dependency hash.
    npmDeps = final.fetchNpmDeps {
      src = finalAttrs.src;
      hash = finalAttrs.npmDepsHash;
    };

    modelData = final.fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${finalAttrs.version}.tgz";
      hash = "sha256-nECvL0OVD46U57vNDBs1SPAAly2gDE+5wNBSnU19VDE=";
    };

    # Re-declare this so it references the overridden modelData derivation.
    preConfigure = ''
      mkdir -p packages/ai/src/providers/data
      tar --extract --gzip --file=${finalAttrs.modelData} \
        --directory=packages/ai/src/providers/data \
        --strip-components=4 \
        package/dist/providers/data
    '';
  });
}
