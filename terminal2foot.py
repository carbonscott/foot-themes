#!/usr/bin/env python3
"""Convert macOS Terminal.app profiles (*.terminal) into foot theme files.

Usage: terminal2foot.py [OUT_DIR] FILE.terminal...
Default OUT_DIR is ~/.config/foot/themes.

Each output file includes the main foot.ini, then overrides [colors-dark],
and exports the `export VAR=...` assignments found in the profile's
CommandString through foot's [environment] section.
"""
import os, pathlib, plistlib, re, sys

ANSI = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]


def color(profile, key):
    """Decode an NSKeyedArchiver'd NSColor to RRGGBB (alpha dropped)."""
    objs = plistlib.loads(profile[key])["$objects"]
    o = next(o for o in objs if isinstance(o, dict) and ("NSComponents" in o or "NSRGB" in o))
    # NSComponents holds the sRGB values as authored; NSRGB is a converted fallback.
    comps = (o.get("NSComponents") or o["NSRGB"]).rstrip(b"\0").split()
    return "".join(f"{round(float(c) * 255):02x}" for c in comps[:3])


def convert(path, out_dir):
    p = plistlib.load(open(path, "rb"))
    name = p.get("name") or path.stem
    bg, fg = color(p, "BackgroundColor"), color(p, "TextColor")
    lines = [
        f"# Generated from {path.name} by terminal2foot.py",
        "include=~/.config/foot/foot.ini",
        "",
        "[colors-dark]",
        f"foreground={fg}",
        f"background={bg}",
        f"cursor={bg} {color(p, 'CursorColor')}",
        f"selection-foreground={fg}",
        f"selection-background={color(p, 'SelectionColor')}",
        "",
    ]
    lines += [f"regular{i}={color(p, f'ANSI{n}Color')}" for i, n in enumerate(ANSI)]
    lines += [""]
    lines += [f"bright{i}={color(p, f'ANSIBright{n}Color')}" for i, n in enumerate(ANSI)]

    env = re.findall(r'export\s+(\w+)="?([^";]*)"?', p.get("CommandString", ""))
    if env:
        lines += ["", "[environment]"] + [f"{k}={v}" for k, v in env]

    out = out_dir / f"{name}.ini"
    out.write_text("\n".join(lines) + "\n")
    print(f"{path.name} -> {out}")


if __name__ == "__main__":
    args = [pathlib.Path(a) for a in sys.argv[1:]]
    out_dir = pathlib.Path(os.path.expanduser("~/.config/foot/themes"))
    if args and args[0].suffix != ".terminal":
        out_dir = args.pop(0)
    out_dir.mkdir(parents=True, exist_ok=True)
    for a in args:
        convert(a, out_dir)
