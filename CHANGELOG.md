# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the
project uses [Semantic Versioning](https://semver.org/). Removing, renaming or
reordering an icon changes image indexes and is therefore a breaking change.

## [1.0.0] - 2026-10-02

### Added
- 78 icons in six categories (File, Edit, Action, Navigation, Data, Application),
  16x16 pixel art with pixel-doubled 32x32 versions.
- Lazarus package `neoclassicicons` with `TNeoClassicImageList` (self-filling,
  HiDPI resolutions 16/24/32, no image data in .lfm files) and the
  `NeoClassicIconNames` unit with `nciXxx` index constants.
- Optional `NeoClassicTheme` unit: Windows 2000 / Delphi 7 look for GTK2 apps.
- Demo application, automated tests and `tools/build.py` (with `--check` for CI).
