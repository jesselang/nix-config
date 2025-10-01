{
  self,
  darwin,
  home-manager,
  dotfiles,
}: {
  hostRev,
  platform,
  host,
  user,
  extraModules ? [],
}:
darwin.lib.darwinSystem {
  modules =
    [
      ({pkgs, ...}: {
        nix.settings.experimental-features = ["nix-command" "flakes"];

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
          home =
            if pkgs.stdenv.isDarwin
            then "/Users/${user}"
            else "/home/${user}";
          shell = pkgs.zsh;
        };

        programs.zsh.enable = true;

        system.defaults = {
          dock.autohide = true;
        };

        # system packages are linked into "/Applications/Nix Apps/" and
        # available to spotlight, etc.
        environment.systemPackages = with pkgs; [
          stats
        ];
      })

      home-manager.darwinModules.home-manager
      ({
        config,
        pkgs,
        ...
      }: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user} = {...}: {
            imports = [
              (import ./home.nix {
                inherit pkgs user dotfiles;
                homeDir = config.users.users.${user}.home;
              })

              # darwin-specific nix packages
              ({ pkgs, lib, ... }: {
                home.packages = lib.mkAfter (with pkgs; [
                  reattach-to-user-namespace
                ]);
              })

              (let
                unknown = "unknown";
                json = pkgs.formats.json {};
              in {
                xdg.dataFile."nix-config/meta.json".source = json.generate "meta.json" {
                  inherit hostRev;
                  nixConfigRev = self.rev or self.dirtyRev or unknown;
                  nixVersion = pkgs.nix.version;
                  nixDarwinRev = darwin.rev or darwin.dirtyRev or unknown;
                  dotfilesRev = dotfiles.rev or dotfiles.dirtyRev or unknown;
                };
              })
            ];
          };
        };
      })
    ]
    ++ extraModules;
}
