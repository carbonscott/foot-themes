#!/usr/bin/env bash
# Install foot-themes: build foot theme files from terminal/*.terminal and
# hook the `ftheme` switcher into bash. Safe to re-run.
#
#   ./install.sh              install / update
#   ./install.sh --uninstall  remove themes, switcher, and the bash hook
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$HOME/.config/foot/themes"
SHARE_DIR="$HOME/.local/share/foot-themes"
MARK="# foot-themes: ftheme switcher"
HOOK="[ -r \"$SHARE_DIR/ftheme.sh\" ] && source \"$SHARE_DIR/ftheme.sh\"  $MARK"

# Machines using the carbonscott/rc repo read per-machine settings from
# ~/.bash_local; everywhere else, use ~/.bashrc.
if [[ -r $HOME/.vim/rc/bash/init.sh ]]; then RC="$HOME/.bash_local"; else RC="$HOME/.bashrc"; fi

remove_hook() {
    # Drop our marked line, plus the unmarked line an earlier manual setup added.
    [[ -f $RC ]] && sed -i "\|$MARK|d; \|foot-themes/ftheme.sh|d; \|^# foot theme switcher: ftheme$|d" "$RC" || true
}

if [[ ${1:-} == --uninstall ]]; then
    remove_hook
    for f in "$REPO"/terminal/*.terminal; do rm -f "$THEME_DIR/$(basename "${f%.terminal}").ini"; done
    rmdir "$THEME_DIR" 2>/dev/null || true
    rm -rf "$SHARE_DIR"
    echo "Uninstalled. Open a new shell to drop ftheme."
    exit
fi

missing=()
for cmd in foot fzf python3; do command -v "$cmd" >/dev/null || missing+=("$cmd"); done
if ((${#missing[@]})); then
    echo "Missing: ${missing[*]}  (on Omarchy/Arch: sudo pacman -S ${missing[*]/python3/python})" >&2
    exit 1
fi

python3 "$REPO/terminal2foot.py" "$THEME_DIR" "$REPO"/terminal/*.terminal

# Copy the switcher out of the clone so the clone can live anywhere (or be deleted).
mkdir -p "$SHARE_DIR"
cp "$REPO/ftheme.sh" "$SHARE_DIR/ftheme.sh"

remove_hook
echo "$HOOK" >>"$RC"
echo "Hooked ftheme into $RC"

for f in "$THEME_DIR"/*.ini; do foot -c "$f" --check-config; done
echo "Done. Open a new foot window (or: source $RC), then run: ftheme"
