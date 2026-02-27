{
  pkgs,
  flake-utils,
}: let
  darwin-local-drv = pkgs.writeShellApplication {
    name = "darwin-local";
    text = ''
      set -euo pipefail

      # Run from nix-hosts repo root
      # Assumes repos are in the same parent directory
      sudo darwin-rebuild switch \
        --refresh \
        --flake . \
        --override-input nix-config path:../nix-config \
        --override-input dotfiles   path:../dotfiles   \
        "$@"
    '';
    meta = {
      description = "Rebuild nix-darwin using local nix-config & dotfiles repos";
      maintainers = ["jesselang"];
      platforms = ["aarch64-darwin"];
    };
  };
in {
  darwin-local = flake-utils.lib.mkApp {
    drv = darwin-local-drv;
  };
}
