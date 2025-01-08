{ flake-parts-lib, inputs, ... }@topLevel:
{
  imports = [
    inputs.flake-parts.flakeModules.flakeModules

    # For `topLevel.config.flake.flakeModules.customHello`
    ./custom-hello.nix
  ];

  flake.flakeModules.dev = {
    imports = [
      # For `perSystem.config.packages.hello
      topLevel.config.flake.flakeModules.customHello
    ];

    config.customHello.enableUserStdenv = true;

    options.perSystem = flake-parts-lib.mkPerSystemOption ({ pkgs, ... }@perSystem: {
      devShells.default = pkgs.mkShell {
        buildInputs = [ perSystem.config.packages.hello ];
        shellHook = ''
          hello
        '';
      };
    });
  };
}
