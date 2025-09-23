{
  pkgs,
  src ? ./.,
}: {
  formatter = pkgs.writeShellApplication {
    name = "fmt-nix";
    runtimeInputs = [pkgs.alejandra];
    text = ''exec alejandra --quiet .'';
  };

  checks = {
    formatting =
      pkgs.runCommand "alejandra-check"
      {
        nativeBuildInputs = [pkgs.alejandra];
        inherit src;
      }
      ''
        set -eu
        alejandra --check "$src"
        mkdir -p "$out"; : > "$out/result"
      '';

    statix =
      pkgs.runCommand "statix-check"
      {
        nativeBuildInputs = [pkgs.statix];
        inherit src;
      }
      ''
        set -eu
        statix check "$src"
        mkdir -p "$out"; : > "$out/result"
      '';

    deadnix =
      pkgs.runCommand "deadnix-check"
      {
        nativeBuildInputs = [pkgs.deadnix];
        inherit src;
      }
      ''
        set -eu
        deadnix --fail "$src"
        mkdir -p "$out"; : > "$out/result"
      '';
  };

  devShell = pkgs.mkShell {
    packages = [
      pkgs.alejandra
      pkgs.statix
      pkgs.deadnix
    ];
  };
}
