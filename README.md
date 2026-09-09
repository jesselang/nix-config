# Nix Config

Declarative configuration of workstation environments using [Nix][nix].

This is a **library flake** — it is not a standalone system config. It exports
`lib.mkDarwin` to be consumed by a separate, private host configuration repo.
Darwin configurations include System Settings and [Homebrew][homebrew] packages
managed by [nix-homebrew][nix-homebrew]. User environments are managed by
[home-manager][home-manager].

## Goals

- Support Linux and Darwin
- Use existing [dotfiles][dotfiles] repo
- Identities (such as host and user names) remain private

## Architecture

Host configurations live in a private `nix-hosts` repo that takes this flake
as an input. This keeps system-specific details (hostnames, usernames) out of
the public repo while the shared configuration is open.

See [docs/architecture.md](docs/architecture.md) for details. An example
`nix-hosts` flake is provided in
[`example-nix-hosts-flake.nix`](example-nix-hosts-flake.nix).

## Usage

Add this flake as an input and call `lib.mkDarwin` from your host flake:

```nix
inputs.nix-config.url = "github:jesselang/nix-config";

# ...

nix-config.lib.mkDarwin {
  inherit hostRev;
  platform = flake-utils.lib.system.aarch64-darwin;
  host = "my-host";
  user = "my-user";
}
```

See [docs/mkDarwin.md](docs/mkDarwin.md) for the full parameter reference and
what gets configured.

## Dev Shells

```sh
nix develop .#<name>
```

| Shell | Packages |
|---|---|
| `default` / `lint` | alejandra, statix, deadnix |
| `aws` | awscli2, aws-sso-cli |
| `kube` | kubectl, kubelogin-oidc, k9s |

## Helper Apps

These are available via `nix run` and installed into `PATH` after a rebuild.
Both must be run from the `nix-hosts` directory.

| App | Description |
|---|---|
| `darwin-rebuild` | `darwin-rebuild switch` against the current flake |
| `darwin-local` | Same, but with local `nix-config` and `dotfiles` path overrides |

See [docs/local-dev.md](docs/local-dev.md) for the local iteration workflow.

## Linting and Formatting

Format all Nix files:

```sh
nix fmt
```

Run all checks (formatting, statix, deadnix):

```sh
nix flake check
```

## Reference Data

The `data/` directory contains snapshots captured during migration (Homebrew
package lists, macOS defaults before/after, pmset output). These are not
active configuration.

[nix]: https://nixos.org
[homebrew]: https://brew.sh
[nix-homebrew]: https://github.com/zhaofengli/nix-homebrew
[home-manager]: https://github.com/nix-community/home-manager
[dotfiles]: https://github.com/jesselang/dotfiles
