{
  description = "nix host configurations";

  inputs = {
    nix-config.url = "github:jesselang/nix-config";
    flake-utils.follows = "nix-config/flake-utils";

    dotfiles = {
      url = "github:jesselang/dotfiles";
      flake = false;
    };

    nix-config.inputs.dotfiles.follows = "dotfiles";
  };

  outputs = {
    self,
    nix-config,
    flake-utils,
    ...
  }: let
    hostRev = self.rev or self.dirtyRev or "unknown";

    hostname = {
      my-host = "my-host";
    };

    username = {
      my-user = "my-user";
    };

    inherit (nix-config.lib) mkDarwin;
  in
    flake-utils.lib.eachDefaultSystem (system: {
      checks = nix-config.checks.${system};
      devShells = nix-config.devShells.${system};
      formatter = nix-config.formatter.${system};
    })
    // {
      darwinConfigurations.${hostname.my-host} = mkDarwin {
        inherit hostRev;
        platform = flake-utils.lib.system.aarch64-darwin;
        host = hostname.my-host;
        user = username.my-user;
        extraModules = []; # add per-host private modules here if needed
      };
    };
}
