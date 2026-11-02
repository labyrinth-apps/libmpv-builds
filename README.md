# libmpv-builds

LGPL-only builds of [mpv](https://mpv.io) (libmpv) and [FFmpeg](https://ffmpeg.org) for the
[media_kit](https://github.com/media-kit/media-kit) packages used by Labyrinth.

| Folder | Platform | Status |
|---|---|---|
| `windows/` | Windows x86_64 (`libmpv-2.dll`) | in progress |
| `darwin/` | iOS + macOS xcframeworks | planned |

## Licences
- Scripts in this repo: MIT (see `LICENSE`), except where a folder's `UPSTREAM.md` says otherwise.
- Released binaries: FFmpeg and mpv built **without GPL components** (`--disable-gpl`,
  `-Dgpl=false`), so they are LGPL (v3 where OpenSSL/mbedtls require `--enable-version3`). Each release
  lists the exact source versions; the sources are the pinned upstream tags plus the patches in this repo.

## Releases
`windows-<YYYYMMDD>-mpv<ver>-ff<ver>`: `mpv-dev-x86_64-<date>-git-<sha>.7z` (+ `.md5`), the same layout as
media_kit's `media_kit_libs_windows_video` expects.
