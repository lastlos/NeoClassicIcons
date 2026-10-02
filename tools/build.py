#!/usr/bin/env python3
"""NeoClassicIcons build script.

Reads the ASCII pixel-art sources in ``src/*.txt`` and generates:

  icons/16/<name>.png            16x16 icons
  icons/32/<name>.png            32x32 icons (2x nearest-neighbour, keeps pixels crisp)
  package/neoclassicicons_images.res  FPC resource with all PNGs (RCDATA) + palette icon
  package/neoclassiciconnames.pas  index constants and name table
  docs/preview.png               contact sheet used by the README
  docs/ICONS.md                  icon list with names, constants and descriptions

Usage:  python3 tools/build.py            build everything (requires Pillow)
        python3 tools/build.py --check    verify that the committed files match src/ (CI)
"""
import os
import struct
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SRC = os.path.join(ROOT, "src")

# Classic 16-colour VGA/Windows palette plus a few in-between shades.
PALETTE = {
    ".": None,              # transparent
    "k": (0, 0, 0),         # black
    "g": (128, 128, 128),   # gray
    "s": (192, 192, 192),   # silver
    "w": (255, 255, 255),   # white
    "n": (0, 0, 128),       # navy
    "b": (0, 0, 255),       # blue
    "L": (200, 230, 255),   # light blue (glass)
    "c": (0, 255, 255),     # cyan
    "C": (0, 128, 128),     # teal
    "r": (255, 0, 0),       # red
    "m": (128, 0, 0),       # maroon
    "G": (0, 128, 0),       # green
    "l": (0, 255, 0),       # lime
    "y": (255, 255, 0),     # yellow
    "o": (128, 128, 0),     # olive
    "O": (255, 128, 0),     # orange
    "t": (230, 190, 120),   # tan
    "T": (250, 225, 175),   # light tan
    "d": (150, 95, 40),     # brown
    "p": (128, 0, 128),     # purple
    "P": (255, 0, 255),     # magenta
}

PALETTE_ICON = "image"   # source used for the IDE component-palette icon
SIZE = 16


class Icon:
    def __init__(self, name, title, category, rows):
        self.name, self.title, self.category, self.rows = name, title, category, rows

    @property
    def const(self):
        return "nci" + "".join(p.capitalize() for p in self.name.split("_"))

    def image(self, scale=1):
        img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        for y, row in enumerate(self.rows):
            for x, ch in enumerate(row):
                rgb = PALETTE[ch]
                if rgb:
                    img.putpixel((x, y), rgb + (255,))
        if scale != 1:
            img = img.resize((SIZE * scale, SIZE * scale), Image.NEAREST)
        return img


def load_icons(write_order=True):
    icons, errors = [], []
    for fn in sorted(os.listdir(SRC)):
        if not fn.endswith(".txt"):
            continue
        name = fn[:-4]
        meta, rows = {}, []
        with open(os.path.join(SRC, fn), encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\n")
                if line.startswith("#"):
                    if ":" in line:
                        k, v = line[1:].split(":", 1)
                        meta[k.strip().lower()] = v.strip()
                elif line.strip():
                    rows.append(line)
        where = "src/" + fn
        if len(rows) != SIZE:
            errors.append("%s: expected %d rows, found %d" % (where, SIZE, len(rows)))
            continue
        for i, r in enumerate(rows):
            if len(r) != SIZE:
                errors.append("%s row %d: expected %d columns, found %d" % (where, i + 1, SIZE, len(r)))
            bad = set(r) - set(PALETTE)
            if bad:
                errors.append("%s row %d: unknown palette characters %s" % (where, i + 1, "".join(sorted(bad))))
        if not name.replace("_", "").isalnum() or name.lower() != name:
            errors.append("%s: file name must be lower_case_with_underscores" % where)
        icons.append(Icon(name, meta.get("title", name), meta.get("category", "Misc"), rows))
    if errors:
        sys.exit("\n".join(["Source errors:"] + errors))
    return order_icons(icons, write_order)


ORDER_FILE = os.path.join(SRC, "order.lst")


def order_icons(icons, write_order=True):
    """Image indexes must never change between releases (forms store ImageIndex as a number),
    so the order comes from src/order.lst. New icons are appended to the end of that file."""
    by_name = {i.name: i for i in icons}
    order = []
    if os.path.exists(ORDER_FILE):
        with open(ORDER_FILE, encoding="utf-8") as f:
            order = [l.strip() for l in f if l.strip() and not l.startswith("#")]
    missing = [n for n in order if n not in by_name]
    if missing:
        sys.exit("order.lst lists icons without a source file (never remove or rename a released icon): "
                 + ", ".join(missing))
    if len(set(order)) != len(order):
        sys.exit("order.lst contains duplicate names")
    new = sorted((i for i in icons if i.name not in order),
                 key=lambda i: (CATEGORY_ORDER.index(i.category) if i.category in CATEGORY_ORDER else 99, i.name))
    if new and not write_order:
        sys.exit("New icons are not in src/order.lst yet - run: python3 tools/build.py\n  "
                 + ", ".join(i.name for i in new))
    if new:
        order += [i.name for i in new]
        with open(ORDER_FILE, "w", encoding="utf-8", newline="\n") as f:
            f.write("# Image index order. NEVER reorder or remove lines - only append.\n")
            f.write("\n".join(order) + "\n")
        print("Appended to order.lst:", ", ".join(i.name for i in new))
    return [by_name[n] for n in order]


CATEGORY_ORDER = ["File", "Edit", "Action", "Navigation", "Data", "Application"]


# --------------------------------------------------------------------------- .res
def _res_entry(name, data, rtype=10):  # 10 = RT_RCDATA
    def align(b):
        return b + b"\0" * (-len(b) % 4)
    hdr = align(struct.pack("<HH", 0xFFFF, rtype) + (name.upper() + "\0").encode("utf-16-le"))
    hdr += struct.pack("<IHHII", 0, 0x30, 0, 0, 0)
    return align(struct.pack("<II", len(data), 8 + len(hdr)) + hdr + data)


def write_res(path, resources):
    empty = struct.pack("<II", 0, 32) + struct.pack("<HHHH", 0xFFFF, 0, 0xFFFF, 0) + b"\0" * 16
    with open(path, "wb") as f:
        f.write(empty)
        for name, data in resources:
            f.write(_res_entry(name, data))


def png_bytes(img):
    import io
    b = io.BytesIO()
    img.save(b, "PNG", optimize=True)
    return b.getvalue()


def palette_icon(icons, size):
    """Component palette icon (24/36/48 px): the image_list icon, centred."""
    src = next((i for i in icons if i.name == PALETTE_ICON), icons[0])
    scale = 1 if size < 32 else 2
    glyph = src.image(scale)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    off = (size - glyph.width) // 2
    canvas.paste(glyph, (off, off), glyph)
    return canvas


# --------------------------------------------------------------------------- pascal
PAS_HEADER = """unit NeoClassicIconNames;

{ NeoClassicIcons - classic 16x16 pixel-art icons for Lazarus.
  THIS FILE IS GENERATED by tools/build.py - do not edit by hand.
  SPDX-License-Identifier: MIT }

{$mode objfpc}{$H+}

interface

const
  NeoClassicIconCount = %d;

  // Image indexes in TNeoClassicImageList
%s

  // Resource base names (16 px: NAME, 32 px: NAME_200)
  NeoClassicIconList: array[0..NeoClassicIconCount - 1] of string = (
%s
  );

  // Short English descriptions, same order
  NeoClassicIconTitles: array[0..NeoClassicIconCount - 1] of string = (
%s
  );

{ Returns the image index for an icon name such as 'document_save', or -1. }
function NeoClassicIconIndex(const AName: string): Integer;

implementation

uses
  SysUtils;

function NeoClassicIconIndex(const AName: string): Integer;
begin
  for Result := 0 to NeoClassicIconCount - 1 do
    if SameText(NeoClassicIconList[Result], AName) then
      Exit;
  Result := -1;
end;

end.
"""


def write_pascal(path, icons):
    w = max(len(i.const) for i in icons)
    consts, cat = [], None
    for idx, i in enumerate(icons):
        if i.category != cat:
            cat = i.category
            consts.append("  // %s" % cat)
        consts.append("  %s = %d;%s{ %s }" % (i.const.ljust(w), idx, " " * (4 - len(str(idx))), i.title))
    names = ",\n".join("    '%s'" % i.name for i in icons)
    titles = ",\n".join("    '%s'" % i.title.replace("'", "''") for i in icons)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(PAS_HEADER % (len(icons), "\n".join(consts), names, titles))


# --------------------------------------------------------------------------- docs
def _font(size):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
              "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
              "C:/Windows/Fonts/tahoma.ttf", "/Library/Fonts/Arial.ttf"):
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def write_preview(path, icons, cols=8):
    """Contact sheet on a classic button-face background, 32 px icons with names."""
    face, cell_w, cell_h = (212, 208, 200), 128, 64
    rows = (len(icons) + cols - 1) // cols
    head = 40
    img = Image.new("RGB", (cols * cell_w + 16, rows * cell_h + head + 12), face)
    d = ImageDraw.Draw(img)
    d.text((10, 10), "NeoClassicIcons - %d icons (32 px shown)" % len(icons), fill=(0, 0, 0), font=_font(16))
    f = _font(11)
    for n, i in enumerate(icons):
        x, y = 8 + (n % cols) * cell_w, head + (n // cols) * cell_h
        im = i.image(2)
        img.paste(im, (x + (cell_w - 32) // 2, y + 4), im)
        label = i.name if len(i.name) <= 20 else i.name[:19] + "…"
        tw = d.textlength(label, font=f)
        d.text((x + (cell_w - tw) / 2, y + 42), label, fill=(0, 0, 0), font=f)
    img.save(path, optimize=True)


def write_toolbar_demo(path, icons, names):
    """A Win2000-style toolbar strip with 32 px icons, for the README."""
    face, s, pad = (212, 208, 200), 32, 8
    sel = [i for n in names for i in icons if i.name == n]
    w = len(sel) * (s + 2 * pad) + 8
    strip = Image.new("RGB", (w, s + 2 * pad + 6), face)
    d = ImageDraw.Draw(strip)
    d.line((0, 0, w, 0), fill=(255, 255, 255))
    d.line((0, strip.height - 1, w, strip.height - 1), fill=(128, 128, 128))
    for n, i in enumerate(sel):
        im = i.image(2)
        strip.paste(im, (4 + n * (s + 2 * pad) + pad, 3 + pad), im)
    strip.save(path, optimize=True)


def write_icons_md(path, icons):
    lines = ["# Icon list", "",
             "Generated by `tools/build.py`. Constants live in `package/neoclassiciconnames.pas`.", ""]
    cat = None
    for idx, i in enumerate(icons):
        if i.category != cat:
            cat = i.category
            lines += ["", "## " + cat, "", "| | Name | Constant | Index | Description |", "|---|---|---|---|---|"]
        lines.append("| ![](../icons/16/%s.png) | `%s` | `%s` | %d | %s |" % (i.name, i.name, i.const, idx, i.title))
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


# --------------------------------------------------------------------------- main
def build(out, icons):
    """Writes every generated file below the directory `out`."""
    for sub in ("icons/16", "icons/32", "package", "docs"):
        os.makedirs(os.path.join(out, sub), exist_ok=True)
    # remove stale PNGs (renamed/deleted sources)
    names = {i.name for i in icons}
    for sub in ("icons/16", "icons/32"):
        for fn in os.listdir(os.path.join(out, sub)):
            if fn.endswith(".png") and fn[:-4] not in names:
                os.remove(os.path.join(out, sub, fn))

    resources = []
    for i in icons:
        p16, p32 = i.image(1), i.image(2)
        p16.save(os.path.join(out, "icons/16", i.name + ".png"), optimize=True)
        p32.save(os.path.join(out, "icons/32", i.name + ".png"), optimize=True)
        resources.append(("NCI_" + i.name, png_bytes(p16)))
        resources.append(("NCI_" + i.name + "_200", png_bytes(p32)))
    # IDE component palette icon (Lazarus looks up the upper-case class name)
    resources.append(("TNEOCLASSICIMAGELIST", png_bytes(palette_icon(icons, 24))))
    resources.append(("TNEOCLASSICIMAGELIST_150", png_bytes(palette_icon(icons, 36))))
    resources.append(("TNEOCLASSICIMAGELIST_200", png_bytes(palette_icon(icons, 48))))
    write_res(os.path.join(out, "package", "neoclassicicons_images.res"), resources)
    write_pascal(os.path.join(out, "package", "neoclassiciconnames.pas"), icons)
    write_preview(os.path.join(out, "docs", "preview.png"), icons)
    write_toolbar_demo(os.path.join(out, "docs", "toolbar.png"), icons,
                       ["document_new", "document_open", "document_save", "document_print", "edit_cut",
                        "edit_copy", "edit_paste", "edit_undo", "edit_redo", "edit_find", "add", "edit_delete",
                        "refresh", "info", "exit"])
    write_icons_md(os.path.join(out, "docs", "ICONS.md"), icons)


# --------------------------------------------------------------------------- --check
def read_res(path):
    """Parses a Win32 .res file into {name: data} (RCDATA entries only)."""
    with open(path, "rb") as f:
        raw = f.read()
    out, pos = {}, 0
    while pos + 8 <= len(raw):
        size, hsize = struct.unpack_from("<II", raw, pos)
        hdr = raw[pos + 8:pos + hsize]
        # type is 0xFFFF + id (4 bytes); name is a NUL-terminated UTF-16 string
        name_raw = hdr[4:]
        end = next(i for i in range(0, len(name_raw), 2) if name_raw[i:i + 2] == b"\0\0")
        name = name_raw[:end].decode("utf-16-le")
        if size:
            out[name] = raw[pos + hsize:pos + hsize + size]
        pos += hsize + size
        pos += -pos % 4
    return out


def same_pixels(a, b):
    import io
    ia = Image.open(io.BytesIO(a) if isinstance(a, bytes) else a).convert("RGBA")
    ib = Image.open(io.BytesIO(b) if isinstance(b, bytes) else b).convert("RGBA")
    if ia.size != ib.size:
        return False
    # fully transparent pixels may differ in their RGB part
    norm = lambda im: [p if p[3] else (0, 0, 0, 0) for p in im.getdata()]
    return norm(ia) == norm(ib)


def check(icons):
    """Fails if the committed generated files do not match src/ (pixel-level for images,
    so different Pillow/zlib versions do not cause false alarms). docs/preview.png is
    skipped because its labels depend on the installed fonts."""
    import tempfile
    problems = []
    with tempfile.TemporaryDirectory() as tmp:
        build(tmp, icons)
        for sub in ("icons/16", "icons/32"):
            fresh = sorted(os.listdir(os.path.join(tmp, sub)))
            have = sorted(f for f in os.listdir(os.path.join(ROOT, sub)) if f.endswith(".png")) \
                if os.path.isdir(os.path.join(ROOT, sub)) else []
            if fresh != have:
                problems.append("%s: file list differs" % sub)
                continue
            for fn in fresh:
                if not same_pixels(os.path.join(tmp, sub, fn), os.path.join(ROOT, sub, fn)):
                    problems.append("%s/%s: pixels differ" % (sub, fn))
        if not same_pixels(os.path.join(tmp, "docs/toolbar.png"), os.path.join(ROOT, "docs/toolbar.png")):
            problems.append("docs/toolbar.png: pixels differ")
        for rel in ("package/neoclassiciconnames.pas", "docs/ICONS.md"):
            with open(os.path.join(tmp, rel), encoding="utf-8") as f1, \
                 open(os.path.join(ROOT, rel), encoding="utf-8") as f2:
                if f1.read() != f2.read():
                    problems.append(rel + ": content differs")
        rel = "package/neoclassicicons_images.res"
        fresh, have = read_res(os.path.join(tmp, rel)), read_res(os.path.join(ROOT, rel))
        if sorted(fresh) != sorted(have):
            problems.append(rel + ": resource names differ")
        else:
            problems += [rel + ": " + n + " differs" for n in fresh if not same_pixels(fresh[n], have[n])]
    if problems:
        sys.exit("Generated files are out of date - run: python3 tools/build.py\n  " + "\n  ".join(problems))
    print("Generated files are up to date (%d icons)." % len(icons))


def main():
    checking = "--check" in sys.argv[1:]
    icons = load_icons(write_order=not checking)
    if checking:
        check(icons)
    else:
        build(ROOT, icons)
        print("Built %d icons." % len(icons))


if __name__ == "__main__":
    main()
