# smove

`smove` is a small native macOS app that recreates Spectacle-style window shortcuts.

It uses:

- Carbon global hotkeys for the keyboard shortcuts.
- macOS Accessibility APIs to move and resize the focused window.
- `~/Library/Application Support/smove/Shortcuts.json` for its active shortcut config.
- `~/Library/Application Support/Spectacle/Shortcuts.json` as the first-run import source.

## Build

```sh
make app
```

The app bundle is created at:

```sh
dist/smove.app
```

## Run

```sh
make run
```

On first launch, macOS will require Accessibility permission:

1. Open System Settings.
2. Go to Privacy & Security > Accessibility.
3. Enable `smove`.
4. Quit Spectacle before using `smove`, because Spectacle may already own the same global hotkeys.
5. Relaunch `smove` or choose `Reload Shortcuts` from the menu-bar item.

## Install

```sh
make install
```

This copies the app to `/Applications/smove.app`.

## Signing

The Makefile uses ad-hoc signing by default:

```sh
make install
```

For stable Accessibility permissions across local rebuilds, sign with your own Apple Development certificate:

```sh
make install SIGN_IDENTITY="Apple Development: Your Name (TEAMID)"
```

## Imported Spectacle Shortcuts

These match Spectacle-style shortcuts and can be overridden by editing `~/Library/Application Support/smove/Shortcuts.json`:

| Action | Shortcut |
| --- | --- |
| Left Half | `alt+cmd+left` |
| Right Half | `alt+cmd+right` |
| Top Half | `alt+cmd+up` |
| Bottom Half | `alt+cmd+down` |
| Fullscreen | `alt+cmd+f` |
| Center | `alt+cmd+c` |
| Next Display | `ctrl+alt+cmd+right` |
| Previous Display | `ctrl+alt+cmd+left` |
| Next Third | `ctrl+alt+right` |
| Previous Third | `ctrl+alt+left` |
| Upper Left | `ctrl+cmd+left` |
| Upper Right | `ctrl+cmd+right` |
| Lower Left | `ctrl+shift+cmd+left` |
| Lower Right | `ctrl+shift+cmd+right` |
| Make Larger | `ctrl+alt+shift+right` |
| Make Smaller | `ctrl+alt+shift+left` |
| Undo Last Move | `alt+cmd+z` |
| Redo Last Move | `alt+shift+cmd+z` |
