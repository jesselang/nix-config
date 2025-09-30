{
  pkgs,
  user,
  homeDir,
  dotfiles,
}: let
  dotlib = import ../lib/dotfiles-homefile.nix {inherit (pkgs) lib;};
in {
  home = {
    username = user;
    homeDirectory = homeDir;
    stateVersion = "25.05";

    packages = with pkgs; [
      gitFull
      gnugrep
      jq
      tree
      unixtools.watch
      vim
    ];

    file = dotlib.mkHomeFilesFromDotfiles {
      inherit dotfiles;
      expandDirs = [".local"];
      excludeTop = pkgs.lib.unique (
        dotlib.defaultExcludeTop
        ++ [".termux"]
      );
      excludeMatch = pkgs.lib.unique (
        dotlib.defaultExcludeMatch
        ++ ["^\\.local/share/dotfiles/emulators.*$"]
      );
    };
    # explicit adds/overrides
    # // (dotlib.mkHomeFilesFor dotfiles {
    #    ".example" = { from = "other-dir/.example"; };
  };
}
