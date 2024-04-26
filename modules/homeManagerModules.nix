{ self, lib, flake-parts-lib, moduleLocation, ... }:
let
  inherit (lib)
    mapAttrs
    mkOption
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      nixosModules = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        default = { };
        apply = mapAttrs (k: v: { _file = "${toString moduleLocation}#nixosModules.${k}"; imports = [ v ]; });
        description = ''
          home-manager modules.

          You may use this for reusable pieces of configuration, service modules, etc for [home-manager](https://github.com/nix-community/home-manager).
        '';
      };
    };
  };
}
