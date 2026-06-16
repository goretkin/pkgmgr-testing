{
  description = "Package manager ecosystem testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.eco-npm = pkgs.mkShell {
          packages = [ pkgs.nodejs_22 pkgs.overmind ];
        };

        devShells.default = self.devShells.${system}.eco-npm;
      }
    );
}
