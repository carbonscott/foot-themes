# ftheme: pick a foot color theme with fzf and apply it to the current window.
#
#   ftheme            fzf picker; moving the cursor previews live, Esc reverts
#   ftheme sage       apply the first theme matching "sage"
#   ftheme default    reset to the colors this window was launched with
#   ftheme -n sage    open a NEW foot window with that theme
#
# Source this file from bash. Colors change via OSC escape codes, so they
# only affect this window. The theme's [environment] vars (BG_COLOR,
# TERM_THEME) are exported into this shell; programs already running
# (e.g. an open vim) keep their old values.
#
# Executed directly (not sourced) with a theme file, it only emits the colors:
# fzf's live preview uses this.

FTHEME_DIR="${FTHEME_DIR:-$HOME/.config/foot/themes}"
FTHEME_TTY="${FTHEME_TTY:-/dev/tty}"

# Print the NAME=value lines from the [environment] section of the given files.
_ftheme_env() {
    command sed -n '/^\[environment\]/,/^\[/{/^[A-Za-z_][A-Za-z0-9_]*=/p}' "$@"
}

# Print the installed theme names, one per line. Uses a glob rather than ls,
# which interactive shells often alias (Omarchy: ls -> eza -lh).
_ftheme_names() {
    local f
    for f in "$FTHEME_DIR"/*.ini; do
        [[ -f $f ]] && f=${f##*/} && echo "${f%.ini}"
    done
}

# Print the OSC color sequences for theme file $1 to the terminal.
# A missing file means reset to the window's launch colors.
_ftheme_colors() {
    local f=$1 sect="" k v seq="" e=$'\e'
    if [[ ! -f $f ]]; then
        printf '\e]104\e\\\e]110\e\\\e]111\e\\\e]112\e\\\e]117\e\\\e]119\e\\' >"$FTHEME_TTY"
        return
    fi
    while IFS='=' read -r k v; do
        case $k in \[*) sect=$k; continue ;; esac
        [[ $sect == "[colors-dark]" ]] || continue
        case $k in
            foreground)           seq+="$e]10;#$v$e\\" ;;
            background)           seq+="$e]11;#$v$e\\" ;;
            cursor)               seq+="$e]12;#${v#* }$e\\" ;;
            selection-background) seq+="$e]17;#$v$e\\" ;;
            selection-foreground) seq+="$e]19;#$v$e\\" ;;
            regular[0-7])         seq+="$e]4;${k#regular};#$v$e\\" ;;
            bright[0-7])          seq+="$e]4;$((8 + ${k#bright}));#$v$e\\" ;;
        esac
    done <"$f"
    printf '%s' "$seq" >"$FTHEME_TTY"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    _ftheme_colors "$1"
    exit
fi

ftheme() {
    local new=0 name file k v
    [[ $1 == -n ]] && { new=1; shift; }

    if [[ -n $1 ]]; then
        name=$(_ftheme_names | command grep -m1 -- "$1")
        [[ $1 == default ]] && name=default
    else
        local self="${BASH_SOURCE[0]}" revert="$FTHEME_DIR/${FTHEME_CURRENT:-default}.ini"
        name=$( { echo default; _ftheme_names; } |
            fzf --height=~40% --reverse --prompt='foot theme> ' \
                --header="current: ${FTHEME_CURRENT:-default}   (Esc reverts)" \
                --bind "focus:execute-silent(bash '$self' '$FTHEME_DIR'/{}.ini)")
        if [[ -z $name ]]; then
            bash "$self" "$revert"
            return 1
        fi
    fi
    [[ -z $name ]] && { echo "ftheme: no theme matching '$1'" >&2; return 1; }
    file="$FTHEME_DIR/$name.ini"

    if ((new)); then
        [[ -f $file ]] && foot -c "$file" >/dev/null 2>&1 & disown
        return
    fi

    _ftheme_colors "$file"

    # Swap the environment: clear every var any theme sets, then export this one's.
    # (Covers vars inherited from the launch config, e.g. TERM_THEME after -c sage.)
    for k in $(_ftheme_env "$FTHEME_DIR"/*.ini | command cut -d= -f1 | command sort -u); do unset "$k"; done
    [[ -f $file ]] && while IFS='=' read -r k v; do export "$k=$v"; done < <(_ftheme_env "$file")
    FTHEME_CURRENT=$name
}
