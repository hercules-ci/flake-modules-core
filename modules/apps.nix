{ config, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkOption
    optionalAttrs
    types
    ;
  inherit (flake-parts-lib)
    mkSubmoduleOptions
    mkPerSystemOption
    mkIfNonEmptySet
    ;

  programType = lib.types.coercedTo derivationType getExe lib.types.str;

  derivationType = lib.types.package // {
    check = lib.isDerivation;
  };

  getExe = x:
    "${lib.getBin x}/bin/${x.meta.mainProgram or (throw ''Package ${x.name or ""} does not have meta.mainProgram set, so I don't know how to find the main executable. You can set meta.mainProgram, or pass the full path to executable, e.g. program = "''${pkg}/bin/foo"'')}";

  getBin = x:
    if !x?outputSpecified || !x.outputSpecified
    then x.bin or x.out or x
    else x;

  appType = lib.types.submodule {
    options = {
      type = mkOption {
        type = lib.types.enum [ "app" ];
        default = "app";
        description = ''
          A type tag for <literal>apps</literal> consumers.
        '';
      };
      program = mkOption {
        type = programType;
        description = ''
          A path to an executable or a derivation with <literal>meta.mainProgram</literal>.
        '';
      };
    };
  };
in
{
  options = {
    flake = mkSubmoduleOptions {
      apps = mkOption {
        type = types.nullOr (types.lazyAttrsOf (types.lazyAttrsOf appType));
        default = null;
        description = ''
          Programs runnable with nix run <literal>.#&lt;name></literal>.
        '';
        example = lib.literalExpression or lib.literalExample ''
          {
            x86_64-linux.default.program = "''${config.packages.hello}/bin/hello";
          }
        '';
      };
    };

    perSystem = mkPerSystemOption
      ({ config, system, ... }: {
        options = {
          apps = mkOption {
            type = types.lazyAttrsOf appType;
            description = ''
              Programs runnable with nix run <literal>.#&lt;name></literal>.
            '';
            example = lib.literalExpression or lib.literalExample ''
              {
                default.program = "''${config.packages.hello}/bin/hello";
              }
            '';
          };
        };
      });

  };
  config = {
    flake.apps =
      mkIfNonEmptySet
        (mapAttrs
          (k: v: v.apps)
          (filterAttrs
            (k: v: v ? apps)
            config.allSystems
          ));

    perInput = system: flake:
      optionalAttrs (flake?apps.${system}) {
        apps = flake.apps.${system};
      };

  };
}
