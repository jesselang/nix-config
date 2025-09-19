{ pkgs, user, homeDir }:
{
  home.username = user;
  home.homeDirectory = homeDir;
  home.stateVersion = "25.05";

  home.packages = with pkgs; [

  ];
}
