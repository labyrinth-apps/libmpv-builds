# libmpv-builds

LGPL-only builds of [mpv](https://mpv.io) (libmpv) and [FFmpeg](https://ffmpeg.org) for the
[media_kit](https://github.com/media-kit/media-kit) packages used by the Labyrinth app. media_kit's own
binaries are stuck on FFmpeg 6.0 / mpv 0.36 (Apple, Android) or a 2024 FFmpeg 7.1 snapshot (Windows),
whose HLS demuxer can't seek fMP4 streams; these builds fix that and stay current.

| Folder | Platform | Output | Engine | TLS |
|---|---|---|---|---|
| `darwin/` | iOS 16+ (device + simulator), macOS 13.5+ (arm64 + x86_64) | 15 xcframeworks (SwiftPM binary targets) | mpv 0.41.0 / FFmpeg 8.1.3 | Secure Transport (system trust store) |
| `windows/` | Windows x86_64 | `libmpv-2.dll` in `mpv-dev-x86_64-*.7z` | mpv 0.41.0 / FFmpeg 8.1.3 | Schannel (system trust store) |
| `android/` | arm64-v8a, armeabi-v7a, x86_64, x86 (API 21+, 16 KB pages) | `default-<abi>.jar` | mpv 0.41.0 / FFmpeg 8.1.3 | mbedtls + Android system CAs |

All three ship and are used by the app (2026-11-03). ARM64 Windows and Linux aren't built here.

## What's different from media_kit's builds
- **FFmpeg 8.1.3**: fMP4 HLS seeks land where asked (6.x/7.1 run to EOF after a seek).
- **PNG/GIF-disguised HLS segments** play (wang-bin's patch; some providers disguise TS this way).
- **Extra formats:** TrueHD/MLP, VC-1, PGS and EIA-608 subtitles, `bwdif`/`yadif` deinterlacing.
- **HTTPS certificate checking** against the OS trust store when the app sets `tls-verify=yes`
  (media_kit's builds had no trust store, so nothing was verified).
- Backported fixes: macOS 27 coreaudio (no sound on 48 kHz, mpv #18384), mpv without Swift on Apple,
  D3D9 removal for current ANGLE headers (Windows). Details per folder in `UPSTREAM.md`.

## CI (GitHub Actions, one workflow per platform)

| Workflow | What it does |
|---|---|
| `windows-toolchain.yml` | Builds the LLVM-mingw toolchain (3–4 h), cached for 7 days. Re-run when the cache expires. |
| `windows-libmpv.yml` | Matrix `stable` (mpv 0.41.0 + FFmpeg n8.1.3) and `next` (mpv master + FFmpeg n9.0.2, informational). |
| `darwin-libmpv.yml` | Nix build of the iOS and macOS xcframeworks (`macos-15`). |
| `android-libmpv.yml` | NDK build of the 4 ABIs + emulator smoke test. |

Every run gates on:
- **Licence:** `CONFIG_GPL 0`, `CONFIG_NONFREE 0`, mpv `HAVE_GPL 0`, no GPL libraries.
- **Features:** the extra decoders/demuxers/filters are compiled in (`config_components.h`).
- **Options** (Windows): `scripts/ffmpeg_options_check.sh` / `mpv_options_check.sh` fail within a
  minute on any configure option the pinned version doesn't know or that matches nothing.
- **Smoke** (`windows/smoke/smoke.py`, reused for macOS; `android/smoke/smoke.c` on an emulator):
  TS HLS plays, HTTPS fMP4 opens and **the seek lands near the target**, PNG-disguised segments decode,
  ASS loads, extra decoders/filters exist, and with `--tls`: a valid certificate is accepted while a local
  self-signed server is connected to but never sent a request (also for an HLS segment behind it).
- **Control:** the same smoke against media_kit's upstream binary must fail the seek check, proving the
  test still catches the bug.

## Releasing
Run the platform workflow with `release=true` (only after a green run on the same commit):

```
gh workflow run darwin-libmpv.yml  -R labyrinth-apps/libmpv-builds -f release=true
gh workflow run windows-libmpv.yml -R labyrinth-apps/libmpv-builds -f release=true
gh workflow run android-libmpv.yml -R labyrinth-apps/libmpv-builds -f release=true
```

The release job only runs if build, gates and smoke pass. Tags: `<platform>-<YYYYMMDD>-mpv<ver>-ff<ver>-g<sha7>`.
Assets:
- **darwin:** one zip per framework per platform, `checksums.txt` (SwiftPM SHA-256), and
  `Package-{ios,macos}.swift.snippet` to paste into the app's vendored `Package.swift`.
- **windows:** `mpv-dev-x86_64-<date>-git-<mpv sha>.7z` + `.md5` (media_kit's layout). The file name can
  repeat across releases; the app's vendored CMake re-extracts when the MD5 changes.
- **android:** `default-<abi>.jar` + `.jar.md5` for the 4 ABIs.

Don't delete a release an app commit still points at: rebuilding that commit would fail.

## Using a release in the app
The app vendors media_kit's four `media_kit_libs_*_video` packages under `third_party/` (see each
`VENDORED.md` there) and points them at a release:
- **Apple:** paste the release's snippet over `libmpvArtifactBase` + `libmpvChecksums` (never hand-edit a
  checksum) and keep `libmpvTargets` equal to the snippet's keys.
- **Windows:** `LIBMPV`, `LIBMPV_MD5`, `LIBMPV_URL` in `windows/CMakeLists.txt` (x86_64 only).
- **Android:** the 4 URLs + MD5s in `android/build.gradle`.

Then re-run the app's baseline (`docs/media/mediakit-baseline-procedure.md` in the app repo) and compare
same-hour A/Bs; network variance between days is bigger than most real differences.

## FFmpeg 9
The Windows `next` variant (mpv master + FFmpeg 9.0.2) passes every check. We stay on 8.1.3 until mpv
0.42 is released, then switch with a version bump.

## Licences
- Scripts in this repo: MIT (see `LICENSE`), except where a folder's `UPSTREAM.md` says otherwise.
- Released binaries: FFmpeg and mpv built **without GPL components** (`--disable-gpl`, `-Dgpl=false`), so
  they are LGPL (v3, via `--enable-version3`). Each release lists the exact source versions; the sources
  are the pinned upstream tags plus the patches in this repo.
