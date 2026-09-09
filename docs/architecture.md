# Architecture

## Two-Repo Model

Configuration is split across two repos:

| Repo | Visibility | Contents |
|---|---|---|
| `nix-config` (this repo) | Public | Shared library: `mkDarwin`, home-manager config, dotfiles lib, dev shells |
| `nix-hosts` | Private | Per-host `darwinConfigurations`, hostnames, usernames, per-host modules |

This keeps host and user identities private while the shared configuration
remains open. The `nix-hosts` flake takes `nix-config` as an input and calls
`lib.mkDarwin` for each machine.

## Input Graph

```
nix-hosts
├── nix-config           (this repo)
│   ├── nixpkgs
│   ├── flake-utils
│   ├── darwin           (nix-darwin)
│   ├── nix-homebrew
│   ├── home-manager
│   ├── homebrew-core    (flake = false)
│   ├── homebrew-cask    (flake = false)
│   └── dotfiles         (flake = false)  ← overridden by nix-hosts
└── dotfiles             (flake = false)  ← overrides nix-config/dotfiles
```

`nix-hosts` re-declares `dotfiles` and uses `follows` to override
`nix-config`'s copy, so both resolve to the same lock entry:

```nix
dotfiles = {
  url = "github:jesselang/dotfiles";
  flake = false;
};

nix-config.inputs.dotfiles.follows = "dotfiles";
```

This means updating dotfiles only requires locking it in one place
(`nix-hosts`), and both the host config and `nix-config` see the same revision.

## Revision Tracking

After every rebuild, a `meta.json` file is written to
`$XDG_DATA_HOME/nix-config/meta.json` (typically
`~/.local/share/nix-config/meta.json`). It records the git revisions of all
moving parts at build time:

```json
{
  "hostRev": "...",
  "nixConfigRev": "...",
  "nixVersion": "...",
  "nixDarwinRev": "...",
  "dotfilesRev": "..."
}
```

`hostRev` is passed explicitly by `nix-hosts` as `self.rev or self.dirtyRev or
"unknown"`. The others are resolved from flake inputs at evaluation time.

## What This Repo Exports

| Output | Description |
|---|---|
| `lib.mkDarwin` | Function to build a Darwin system configuration |
| `devShells.<system>.default` | Lint shell (alejandra, statix, deadnix) |
| `devShells.<system>.lint` | Same as default |
| `devShells.<system>.aws` | AWS tooling (awscli2, aws-sso-cli) |
| `devShells.<system>.kube` | Kubernetes tooling (kubectl, kubelogin-oidc, k9s) |
| `formatter.<system>` | alejandra |
| `checks.<system>.*` | Formatting, statix, deadnix checks |
| `apps.<system>.darwin-rebuild` | Helper: rebuild from nix-hosts |
| `apps.<system>.darwin-local` | Helper: rebuild with local path overrides |
| `packages.<system>.*` | Same helpers as derivations |
