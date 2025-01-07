{ lib, moduleLocation, ... }:
let
  inherit (lib)
    mapAttrs
    mkOption
    types
    ;
  inherit (lib.strings)
    escapeNixIdentifier
    ;

  addInfo = class: moduleName:
    if class == "generic"
    then module: module
    else
      module:
      # TODO: set key?
      {
        _class = class;
        _file = "${toString moduleLocation}#modules.${escapeNixIdentifier class}.${escapeNixIdentifier moduleName}";
        imports = [ module ];
      };
in
{
  options = {
    flake.modules = mkOption {
      type = types.lazyAttrsOf (types.lazyAttrsOf types.deferredModule);
      description = ''
        Groups of modules published by the flake.

        The outer attributes declare the [`class`](https://nixos.org/manual/nixpkgs/stable/#module-system-lib-evalModules-param-class) of the modules within it.
        The special attribute `generic` does not declare a class, allowing its modules to be used in any module class.
      '';
      example = lib.literalExpression ''
        {
          # NixOS configurations are modules with class "nixos"
          nixos = {
            # You can define a module right here:
            noBoot = { config, ... }: {
              boot.loader.enable = false;
            };
            # Or you may refer to it by file
            autoDeploy = ./nixos/auto-deploy.nix;
            # Or maybe you need both
            projectIcarus = { config, pkgs, ... }: {
              imports = [ ./nixos/project-icarus.nix ];
              services.project-icarus.package =
                withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }:
                  config.packages.default
                );
            };
          };
          # Flake-parts modules
          # If you're not just publishing a module, but also using it locally,
          # create a let binding to declare it before calling `mkFlake` so you can
          # use it in both places.
          flake = {
            foo = someModule;
          };
          # Modules that can be loaded anywhere
          generic = {
            my-pkgs = { _module.args.my-pkgs = …; };
          };
        }
      '';
      apply = mapAttrs (k: mapAttrs (addInfo k));
    };
  };
  config = {
    # Copy over to old nixosModules and hmModules attributes
    flake = {
      nixosModules = lib.optional (lib.hasAttr "nixos" lib.flake.modules) lib.flake.modules.nixos;
      hmModules = lib.optional (lib.hasAttr "homeManager" lib.flake.modules) lib.flake.modules.homeManager;
    };
  };
}
