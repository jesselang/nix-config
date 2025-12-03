{
  description = "nix configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    darwin.url = "github:nix-darwin/nix-darwin";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";

    # homebrew taps
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    darwin,
    nix-homebrew,
    home-manager,
    homebrew-core,
    homebrew-cask,
    dotfiles,
    ...
  }: let
    mkDarwin = import ./modules/darwin.nix {
      inherit self darwin nix-homebrew homebrew-core homebrew-cask home-manager dotfiles;
    };
  in
    # provide flake formatters, checks, and dev shells to consumers.
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {inherit system;};
        lint = import ./lint.nix {
          inherit pkgs;
          src = ./.;
        };
        shells = import ./shells.nix {inherit pkgs;};
      in {
        inherit (lint) formatter checks;

        devShells =
          shells
          // {
            default = lint.devShell;

            lint = lint.devShell;
          };
      }
    )
    // {
      lib.mkDarwin = mkDarwin;
    };
}
