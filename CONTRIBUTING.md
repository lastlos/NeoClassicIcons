# Contributing

Thanks for helping! New icons, fixes to existing pixels and code improvements are all welcome.

## Icon source format

Each icon is a text file `src/<name>.txt` with two header lines and exactly 16 rows of 16 characters:

```
# title: Save
# category: File
kkkkkkkkkkkkkkk.
knkwwwwwwwwwknk.
...
```

- **File names** are `lower_case_with_underscores`. The name becomes the resource name, the PNG file name and the constant (`document_save` → `nciDocumentSave`).
- **Categories:** `File`, `Edit`, `Action`, `Navigation`, `Data`, `Application`, `Device`, `Media`, `Format`.
- **Every character is one pixel**, taken from the palette below. `.` is transparent.

| Char | Colour | RGB | | Char | Colour | RGB |
|---|---|---|---|---|---|---|
| `.` | transparent | — | | `r` | red | 255,0,0 |
| `k` | black | 0,0,0 | | `m` | maroon | 128,0,0 |
| `g` | gray | 128,128,128 | | `G` | green | 0,128,0 |
| `s` | silver | 192,192,192 | | `l` | lime | 0,255,0 |
| `w` | white | 255,255,255 | | `y` | yellow | 255,255,0 |
| `n` | navy | 0,0,128 | | `o` | olive | 128,128,0 |
| `b` | blue | 0,0,255 | | `O` | orange | 255,128,0 |
| `L` | light blue | 200,230,255 | | `t` | tan | 230,190,120 |
| `c` | cyan | 0,255,255 | | `T` | light tan | 250,225,175 |
| `C` | teal | 0,128,128 | | `d` | brown | 150,95,40 |
| `p` | purple | 128,0,128 | | `P` | magenta | 255,0,255 |

## Style guide

- Draw at 16×16 and check the 32×32 result too, because every pixel is doubled.
- Give shapes a 1 px dark outline (`k`, or a darker shade of the fill such as `n` for blue or `m` for red).
- Light comes from the top-left. Use lighter pixels top-left and a darker shade along the bottom-right inner edge.
- Prefer the classic 16 colours. Add a new palette entry only when there is a real need, and discuss it in the PR.
- Keep a 0–1 px transparent margin so icons line up next to each other.

## Index stability (important)

Forms store `ImageIndex` as a number, so **an icon's index must never change**:

- `src/order.lst` defines the index order. `tools/build.py` appends new icons to it automatically.
- **Never** reorder, rename or delete lines in `order.lst`, and never remove or rename a released icon. If an icon needs redrawing, change its pixels; the index stays the same.
- If an icon must be replaced by a better name, add the new icon and keep the old one.

## Building and testing

```sh
python3 tools/build.py                 # needs Pillow (pip install pillow / apt install python3-pil)
python3 tools/build.py --check         # what CI runs
lazbuild package/neoclassicicons.lpk
lazbuild tests/imagelisttest.lpi && tests/imagelisttest     # on Linux CI: xvfb-run -a tests/imagelisttest
lazbuild examples/demo/demo.lpi && examples/demo/demo       # look at your icon in context
```

Commit the generated files (`icons/`, `package/neoclassicicons_images.res`, `package/neoclassiciconnames.pas`, `docs/`) together with your `src/` changes. CI fails if they are out of date.

## Licensing of contributions

By contributing, you agree that your work is released under the [MIT License](LICENSE) of this project. Please only submit artwork you drew yourself.
