# mkDarwin Reference

`lib.mkDarwin` builds a complete nix-darwin system configuration. It composes
nix-homebrew, home-manager, system defaults, and dotfiles into a single
`darwinSystem` call.

## Parameters

```nix
nix-config.lib.mkDarwin {
  hostRev      # string
  platform     # string (nixpkgs system)
  host         # string (hostname)
  user         # string (username)
  extraModules # list of nix-darwin modules (default: [])
}
```

| Parameter | Type | Description |
|---|---|---|
| `hostRev` | string | Git revision of the calling flake. Use `self.rev or self.dirtyRev or "unknown"`. Recorded in `meta.json`. |
| `platform` | string | Nixpkgs system string, e.g. `flake-utils.lib.system.aarch64-darwin`. |
| `host` | string | Hostname. Set as `networking.hostName`, `localHostName`, and `computerName`. |
| `user` | string | Username. Used for the user account, home-manager, and nix-homebrew. |
| `extraModules` | list | Additional nix-darwin modules appended after the base modules. Use this for per-host configuration in `nix-hosts`. |

## What Gets Configured

### Nix

- `nix-command` and `flakes` experimental features enabled.
- `system.configurationRevision` set from `self.rev` or `self.dirtyRev`.

### Network

- `networking.hostName`, `networking.localHostName`, and
  `networking.computerName` all set to `host`.

### User Account

- `users.users.<user>.home` set to `/Users/<user>` on Darwin.
- `users.users.<user>.shell` set to `pkgs.zsh`.
- `programs.zsh.enable = true`.

### System Defaults

**Dock**
- Auto-hide enabled.
- Positioned on the right.

**Finder**
- Desktop icons disabled (`CreateDesktop = false`).

**Keyboard**
- CapsLock remapped to Escape.
- Key repeat rate: 2 (fast); initial delay: 30.
- Press-and-hold disabled (allows key repeat).
- Function key hardware controls used; Fn key required for F1–F12.

**Input Sources** (via `com.apple.HIToolbox`)
- Dvorak as primary layout.
- U.S. as secondary layout.

**Clock** (menu bar)
- Format: `EEE MMM d  HH:mm` — e.g. `Tue Sep 9  14:30`.
- Day of week and date shown; seconds not shown.

**NSGlobalDomain**
- 24-hour time.
- US customary units (inches, Fahrenheit).
- Dark mode, no automatic switching.
- Autocorrect, auto-capitalization, smart quotes, smart dashes, and
  auto-period all disabled.

**Login window**
- Keyboard layout shown at login.

### Power Management

Applied via activation script (`pmset`):

| Setting | AC | Battery |
|---|---|---|
| System sleep | Never | 10 min |
| Display sleep | 15 min | 5 min |

### Homebrew

Managed by nix-homebrew with declarative taps (no mutable taps). On each
activation: auto-update, upgrade, and `zap` cleanup (removes anything not
declared).

**Casks installed:**

- background-music
- claude
- claude-code
- drawio
- elgato-control-center
- elgato-stream-deck
- hammerspoon
- keepassx
- logitune
- logseq
- wacom-tablet

### System Packages

- `stats` — available in `/Applications/Nix Apps/` and Spotlight.

### Home Manager

See `modules/home.nix` for user packages. Additionally:

- `reattach-to-user-namespace` installed on Darwin (for tmux clipboard).

**User packages:** gitFull, gnugrep, jq, tmux, tree, watch, uv, vim.

Dotfiles are linked via `lib/dotfiles-homefile.nix`. See
[dotfiles.md](dotfiles.md) for details.

### Revision Tracking

A `meta.json` file is written to `~/.local/share/nix-config/meta.json` on
each rebuild, recording the revisions of all flake inputs. See
[architecture.md](architecture.md) for the full schema.
