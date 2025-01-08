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
        type = types.lazyAttrsOf types.deferredModule;
        default = { };
        apply = mapAttrs (k: v: {
          _file = "${toString moduleLocation}#nixosModules.${k}";
          # Note: this neglects to represent potential differences due to input
          #       overrides or flake-parts extendModules. However, the cost for this
          #       is too high or plain infeasible respectively. We choose to implement
          #       deduplication and disabledModules regardless, because not doing
          #       so poses a more direct problem.
          key = "${toString moduleLocation}#nixosModules.${k}";
          imports = [ v ];
        });
        description = ''
          NixOS modules.

          You may use this for reusable pieces of configuration, service modules, etc.
        '';
      };
    };
  };
}
