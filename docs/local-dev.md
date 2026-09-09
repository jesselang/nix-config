# Local Development

## Directory Layout

The helper scripts expect `nix-hosts`, `nix-config`, and `dotfiles` to be
siblings in the same parent directory:

```
~/some-parent/
  nix-hosts/     # private host configurations (where you run rebuilds)
  nix-config/    # this repo
  dotfiles/      # your dotfiles
```

Both helpers enforce that you are running from within `nix-hosts/`. They will
exit with an error if the directory name does not match.

## Normal Rebuild

When working from committed (or at least locked) inputs, use `darwin-rebuild`:

```sh
cd ~/some-parent/nix-hosts
darwin-rebuild
```

This runs:

```sh
sudo darwin-rebuild switch --flake .
```

## Local Iteration

When iterating on changes to `nix-config` or `dotfiles` before committing,
use `darwin-local` to override the flake inputs with local paths:

```sh
cd ~/some-parent/nix-hosts
darwin-local
```

This runs:

```sh
sudo darwin-rebuild switch \
  --refresh \
  --flake . \
  --override-input nix-config path:../nix-config \
  --override-input dotfiles   path:../dotfiles
```

`--refresh` forces re-evaluation even if Nix thinks nothing has changed.
`path:../` inputs bypass the lock file and read directly from the local
checkout, so uncommitted changes in `nix-config` or `dotfiles` are picked up
immediately.

`darwin-local` also checks that `../nix-config` and `../dotfiles` exist before
proceeding.

## Running the Helpers

After a rebuild the helpers are in `PATH`. Before the first rebuild, or when
testing changes to the helpers themselves, run them directly from this repo:

```sh
nix run github:jesselang/nix-config#darwin-rebuild
nix run github:jesselang/nix-config#darwin-local

# or from a local checkout:
nix run /path/to/nix-config#darwin-local
```

## Linting and Formatting

Run from within `nix-config/`:

```sh
# format all Nix files in-place
nix fmt

# run all checks (formatting, statix, deadnix)
nix flake check

# enter the lint shell to run tools directly
nix develop
alejandra --check .
statix check .
deadnix --fail .
```

## Checking a Specific System

To evaluate the Darwin configuration without rebuilding:

```sh
cd ~/some-parent/nix-hosts
nix eval .#darwinConfigurations.<hostname>.system
```
