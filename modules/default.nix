# Central Module Registry
# This file coordinates all module imports and prevents conflicts
{
  config,
  lib,
  ...
}:
with lib; {
  imports = [
    # Service modules (specific services)
    ./services/default.nix # Service configurations
  ];

  # Module validation and conflict detection
  config = {
    warnings =
      optional (config.nixpkgs.config.allowUnfree or false && config.nixpkgs.config.allowInsecure or false)
      "Both allowUnfree and allowInsecure are globally enabled. Consider using targeted package permissions instead."
      ++ optional (builtins.length (attrNames (filterAttrs (_n: v: v.enable or false && hasAttr "mkForce" (attrNames v)) config.services)) > 0)
      "Some services are using mkForce. This may indicate configuration conflicts.";
  };

  # Global module options that can be used by all modules
  options = {
    infrastructure = {
      hostType = mkOption {
        type = types.enum ["workstation" "server" "laptop" "minimal"];
        default = "workstation";
        description = lib.mdDoc ''
          Type of host configuration. This affects which modules are loaded
          and how they're configured.
        '';
      };

      hostClass = mkOption {
        type = types.enum ["development" "production" "testing"];
        default = "development";
        description = lib.mdDoc ''
          Host class affects security, performance, and feature settings.
        '';
      };
    };

    features = {
      minimal = mkEnableOption "minimal feature set";

      validation = {
        enable = mkEnableOption "strict configuration validation" // {default = true;};
        warningsAsErrors = mkEnableOption "treat warnings as errors";
      };
    };
  };
}
