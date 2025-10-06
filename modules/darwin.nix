{
  self,
  darwin,
  nix-homebrew,
  homebrew-core,
  homebrew-cask,
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
      nix-homebrew.darwinModules.nix-homebrew
      {
        nix-homebrew = {
          inherit user;

          enable = true;

          taps = {
            "homebrew/homebrew-core" = homebrew-core;
            "homebrew/homebrew-cask" = homebrew-cask;
          };

          mutableTaps = false;
        };
      }

      ({
        config,
        pkgs,
        ...
      }: {
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

        system = {
          defaults = {
            dock.autohide = true;

            CustomUserPreferences = {
              "com.apple.HIToolbox" = import ./darwin-defaults-hitoolbox.nix;

              # show keyboard layout at login
              "com.apple.loginwindow".showInputMenu = true;
            };

            NSGlobalDomain = {
              KeyRepeat = 2;
              InitialKeyRepeat = 30;
              ApplePressAndHoldEnabled = false;

              # use keyboard hardware controls, use Fn for function keys
              "com.apple.keyboard.fnState" = false;

              # disable "smart" edits, thankyouverymuch
              NSAutomaticSpellingCorrectionEnabled = false;
              NSAutomaticCapitalizationEnabled = false;
              NSAutomaticQuoteSubstitutionEnabled = false;
              NSAutomaticDashSubstitutionEnabled = false;
              NSAutomaticPeriodSubstitutionEnabled = false;
            };
          };

          keyboard = {
            enableKeyMapping = true;
            remapCapsLockToEscape = true;
          };

          # emulate "Prevent automatic sleeping on power adapter when the
          # display is off" in system settings
          activationScripts.pmsetACOnly.text = ''
            # never sleep when on charger
            /usr/bin/pmset -c sleep 0
            /usr/bin/pmset -c displaysleep 15

            # allow sleep when on battery
            /usr/bin/pmset -b sleep 10
            /usr/bin/pmset -b displaysleep 5
          '';
        };

        homebrew = {
          enable = true;

          onActivation = {
            autoUpdate = true;
            upgrade = true;
            cleanup = "zap";
          };

          # use declarative taps from nix-homebrew
          taps = builtins.attrNames config.nix-homebrew.taps;

          brews = [];

          casks = [
            "drawio"
            "hammerspoon"
            "elgato-control-center"
            "elgato-stream-deck"
            "keepassx"
            "logitune"
            "logseq"
            "wacom-tablet"
          ];
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

              ({
                pkgs,
                lib,
                ...
              }: {
                # darwin-specific nix packages
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
