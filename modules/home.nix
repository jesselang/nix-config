{
  pkgs,
  user,
  homeDir,
}: {
  home = {
    username = user;
    homeDirectory = homeDir;
    stateVersion = "25.05";

    packages = with pkgs; [
    ];

    file = {
    };
  };
}
