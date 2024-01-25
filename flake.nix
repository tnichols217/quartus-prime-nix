{
  description = "Dev shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    source = {
      url = "https://downloads.intel.com/akdlm/software/acdsinst/20.1std.1/720/ib_tar/Quartus-lite-20.1.1.720-linux.tar";
      flake = false;
    }
  };

  outputs = { self, nixpkgs, flake-utils, gitignore }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        tarBall = source;
        version = "20.1.1.720";

      in with pkgs; {
        packages = rec {
          quartus-prime = pkgs.callPackage ./quartus.pkg.nix { inherit tarBall version; };
          default = quartus-prime;
        };
      })
}