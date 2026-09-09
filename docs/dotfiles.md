# Dotfiles Integration

`lib/dotfiles-homefile.nix` provides helpers for generating `home.file` entries
from a dotfiles flake input. The main function scans the dotfiles repo at
evaluation time and builds the attribute set that home-manager uses to link
files into `$HOME`.

## Functions

### `mkHomeFilesFromDotfiles`

```nix
dotlib.mkHomeFilesFromDotfiles {
  dotfiles     # the dotfiles flake input (flake = false)
  expandDirs   # list of directory names to expand individually (default: [])
  excludeTop   # list of top-level names to skip entirely
  excludeMatch # list of regex patterns; paths matching any are skipped
}
```

Returns an attribute set suitable for `home.file`.

**Default values:**

```nix
defaultExcludeTop   = [ ".git" ".gitignore" ".github" ]
defaultExcludeMatch = [ "^[^/.][^/]*$" ]  # top-level items not starting with "."
```

The default `excludeMatch` pattern means any top-level file or directory that
does not begin with `.` is excluded unless it is in `expandDirs`. This keeps
non-dotfile content (e.g. `README.md`, `scripts/`) out of `$HOME`.

### `mkHomeFilesFor`

```nix
dotlib.mkHomeFilesFor dotfiles {
  ".example" = { from = "other-dir/.example"; };
  ".another" = {};  # target path = source path
}
```

Explicit per-file entries. `from` overrides the source path within the
dotfiles repo; if omitted, the target name is used as the source path.

### `dotFor` / `dotDirFor`

```nix
dotlib.dotFor    dotfiles "path/in/dotfiles"   # single file
dotlib.dotDirFor dotfiles "path/in/dotfiles"   # directory, recursive = true
```

Convenience helpers for one-off entries.

## How `mkHomeFilesFromDotfiles` Works

1. Reads the top-level directory listing of the dotfiles repo.
2. Removes any names in `excludeTop`.
3. For each remaining entry:

   | Entry type | In `expandDirs`? | Behavior |
   |---|---|---|
   | Directory | Yes | Recursively lists all files; applies `excludeMatch` to each relative path; creates one entry per file |
   | Directory | No | Applies `excludeMatch` to the directory name; creates a single `recursive = true` entry |
   | File or symlink | — | Applies `excludeMatch` to the name; creates a single file entry |

Entries for which the path matches any `excludeMatch` pattern are dropped.

## Usage in `home.nix`

```nix
dotlib.mkHomeFilesFromDotfiles {
  inherit dotfiles;
  expandDirs = [ ".local" ];
  excludeTop = pkgs.lib.unique (
    dotlib.defaultExcludeTop ++ [ ".termux" ]
  );
  excludeMatch = pkgs.lib.unique (
    dotlib.defaultExcludeMatch
    ++ [ "^\\.local/share/dotfiles/emulators.*$" ]
  );
}
```

- **`.local` is expanded** rather than symlinked wholesale. This lets
  home-manager manage individual files inside `.local/` without clobbering
  the entire directory.
- **`.termux` is excluded** at the top level — it is not applicable on macOS
  or Linux desktop.
- **Emulator data** under `.local/share/dotfiles/emulators/` is excluded;
  those paths are too large or platform-specific to link.

## Combining with Explicit Overrides

`mkHomeFilesFromDotfiles` returns an attrset, so it can be merged with
additional entries using `//`:

```nix
home.file =
  dotlib.mkHomeFilesFromDotfiles { ... }
  // dotlib.mkHomeFilesFor dotfiles {
    ".special" = { from = "other/.special"; };
  };
```

The commented-out block in `home.nix` shows where to add overrides if needed.
