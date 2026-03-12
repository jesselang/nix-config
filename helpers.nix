{pkgs}: let
  apps =
    pkgs.lib.mapAttrs (name: drv: {
      type = "app";
      program = "${drv}/bin/${name}";
      meta.description = helpers.${name}.description;
    })
    packages;

  packages = pkgs.lib.mapAttrs (name: cfg:
    pkgs.writeShellApplication {
      inherit name;
      inherit (cfg) text;

      runtimeInputs = cfg.runtimeInputs or [];
    })
  helpers;

  helpers = {
    darwin-rebuild = {
      description = "darwin-rebuild";
      text = ''
        [[ $(basename "$PWD") == nix-hosts ]] || {
            echo "error: not in nix-hosts directory" >&2;
            exit 1;
        }

        set -x
        sudo darwin-rebuild switch --flake . "$@"
      '';
    };
    darwin-local = {
      description = "darwin-rebuild (local iteration)";
      text = ''
        [[ $(basename "$PWD") == nix-hosts ]] || {
            echo "error: not in nix-hosts directory" >&2;
            exit 1;
        }

        [[ -d ../nix-config ]] || {
            echo "error: ../nix-config directory not found" >&2;
            exit 1;
        }

        [[ -d ../dotfiles ]] || {
            echo "error: ../dotfiles directory not found" >&2;
            exit 1;
        }

        set -x
        sudo darwin-rebuild switch \
          --refresh \
          --flake . \
          --override-input nix-config path:../nix-config \
          --override-input dotfiles   path:../dotfiles   \
          "$@"
      '';
    };
  };
in {
  inherit apps packages;
}
