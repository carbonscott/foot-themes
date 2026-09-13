# foot-themes

macOS Terminal.app color profiles, converted for the [foot](https://codeberg.org/dnkl/foot) terminal, plus `ftheme`: an fzf picker that recolors the current foot window on the fly.

Included themes: `conway-dark`, `conway-paper`, `conway-parchment`, `conway-sage`.

## Install

```bash
git clone https://github.com/carbonscott/foot-themes ~/codes/foot-themes
~/codes/foot-themes/install.sh
```

Requires `foot`, `fzf`, and `python3` (all present on a stock Omarchy install except possibly `fzf`). Re-running `install.sh` is safe; use it after pulling updates.

What it does:

| Step | Result |
|---|---|
| Convert `terminal/*.terminal` | `~/.config/foot/themes/<name>.ini` |
| Copy the switcher | `~/.local/share/foot-themes/ftheme.sh` |
| Add one `source` line | `~/.bash_local` if the carbonscott/rc repo is present, else `~/.bashrc` |

Uninstall with `./install.sh --uninstall`.

## Use

| Command | Effect |
|---|---|
| `ftheme` | fzf picker; moving the highlight previews live, Enter keeps, Esc reverts |
| `ftheme sage` | apply the first theme matching `sage` |
| `ftheme default` | reset to the colors the window launched with |
| `ftheme -n paper` | open a new foot window with that theme |
| `foot -c ~/.config/foot/themes/conway-sage.ini` | launch a window with a theme directly |

Only the current window changes. Each theme also exports the variables its macOS profile set (`BG_COLOR`, `TERM_THEME`); `ftheme` swaps them in the current shell, but already-running programs such as vim keep their old values.

## Adding a theme

Export a profile from Terminal.app (Settings → Profiles → ⋯ → Export), drop the `.terminal` file into `terminal/`, and re-run `install.sh`.

Not carried over, because foot lacks them: bold text color and cursor transparency.
