{pkgs}: let
  pkgSet = {
    aws = with pkgs; [
      awscli2
      aws-sso-cli
    ];

    kube = with pkgs; [
      kubectl
      kubelogin-oidc
      k9s
    ];
  };
in {
  aws = pkgs.mkShell {
    packages = pkgSet.aws;
  };

  kube = pkgs.mkShell {
    packages = pkgSet.kube;
  };
}
