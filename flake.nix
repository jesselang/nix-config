{
  description = "nix configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    darwin.url = "github:nix-darwin/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }:
  let
    mkDarwin = { platform, host, user, extraModules ? [] }:
      darwin.lib.darwinSystem {
        modules = [
          ({ pkgs, ... }: {
            nix.settings.experimental-features = [ "nix-command" "flakes" ];

            system = {
                configurationRevision = self.rev or self.dirtyRev or null;
                stateVersion = 6;
                primaryUser = user;
            };

            nixpkgs.hostPlatform = platform;

            networking = {
                hostName = host;
                localHostName = host;
                computerName = host;
            };

            users.users.${user} = {
                home = if pkgs.stdenv.isDarwin then "/Users/${user}"
                       else "/home/${user}";
                shell = pkgs.zsh;
            };
            programs.zsh.enable = true;

            system.defaults = {
              dock.autohide = true;
            };
          })

          home-manager.darwinModules.home-manager
          ({ config, pkgs, ... }: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${user} = { ... }:
              import ./modules/home.nix {
                inherit pkgs user;

                homeDir = config.users.users.${user}.home;
              };
          })
        ] ++ extraModules;
      };
  in {
    lib.mkDarwin = mkDarwin;

    # example:
    # darwinConfigurations."my-host" = mkDarwin {
    #   platform = "aarch64-darwin";
    #   host = "my-host";
    #   user = "my-user";
    #   extraModules = [];
    # };
  };
}

