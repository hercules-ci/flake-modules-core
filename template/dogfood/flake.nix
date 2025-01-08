{
  description = "Description for the project";

  inputs = {
    nixpkgs_24_05.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { flake-parts, self, nixpkgs, ... }@inputs:
    flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      (topLevel: {
        imports = [
          flake-parts.flakeModules.partitions
          ./modules/dev.nix
        ];

        systems = [ "x86_64-linux" "aarch64-darwin" ];

        partitionedAttrs.devShells = "dogfood";
        partitionedAttrs.packages = "dogfood";
        partitions.dogfood = {
          module = topLevel.config.flake.flakeModules.dev;
        };
      });
}
