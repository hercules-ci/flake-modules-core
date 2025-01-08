{ inputs, flake-parts-lib, lib, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
  ];

  flake.flakeModules.customHello = flakeModule:
    let
      cfg = flakeModule.config.customHello;
    in
    {
      options.customHello.enableUserStdenv = lib.mkEnableOption "stdenv from `flakeModules.customHello` user's nixpkgs";
      options.perSystem = flake-parts-lib.mkPerSystemOption ({ pkgs, system, ... }: {
        packages.hello =
          (inputs.nixpkgs_24_05.legacyPackages.${system}.hello.override {
            stdenv =
              if cfg.enableUserStdenv then
                pkgs.stdenv
              else
                inputs.nixpkgs_24_05.legacyPackages.${system}.stdenv;
          }).overrideAttrs (oldAttrs: {
            meta = oldAttrs.meta // {
              description = "A hello package from the `flakeModules.customHello` author's nixpkgs 24.05, built with stdenv from ${
              if cfg.enableUserStdenv then
                "the `flakeModules.customHello` user's nixpkgs"
              else
                "the `flakeModules.customHello` author's nixpkgs 24.05"
            }";
            };
          });
      });
    };
}
