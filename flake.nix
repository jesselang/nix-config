{
  description = "nix configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    darwin.url = "github:nix-darwin/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    darwin,
    home-manager,
    ...
  }: let
    mkDarwin = import ./modules/darwin.nix {inherit self darwin home-manager;};
  in
    # provide flake formatters, checks, and dev shells to consumers.
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        lint = import ./lint.nix {
          inherit pkgs;
          src = ./.;
        };
      in {
        inherit (lint) formatter checks;

        devShells = {
          default = lint.devShell;

          lint = lint.devShell;
        };
      }
    )
    // {
      lib.mkDarwin = mkDarwin;
    };
}
