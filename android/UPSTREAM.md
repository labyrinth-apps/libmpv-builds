# Upstream

`android/` is derived from [media-kit/libmpv-android-video-build](https://github.com/media-kit/libmpv-android-video-build)
at commit `1ecf5100ec0f75e1d0630f48851b85769c92eed2` (tag v1.1.11; MIT, see `LICENSE`; copyright
remains with its authors). The first commit touching `android/` is an import of that tree minus
upstream's `.github/` and the GPL `encoders-gpl` flavour (its flavour script, bundle script,
`patch-encoders-gpl.sh`, `patches-encoders-gpl/`, libx264). Every change since is in later commits.

Built by `.github/workflows/android-libmpv.yml` on GitHub Actions (`ubuntu-24.04`, NDK r27d).

## What changed vs upstream

**Scope: LGPL `default` flavour only.** Removed the `full` flavour and the packages only the
`full`/`encoders-gpl` flavours used (libogg, libvorbis, libvpx, fftools-ffi, shaderc), and the
unused root Gradle project. `flavors/default.sh` is now `scripts/ffmpeg.sh` (FFmpeg keeps
`--disable-gpl --disable-nonfree --enable-version3`; mpv uses `-Dgpl=false`).

**Outputs unchanged in shape:** `default-<abi>.jar` for arm64-v8a, armeabi-v7a, x86_64 and x86,
each containing exactly `lib/<abi>/libmediakitandroidhelper.so` and `lib/<abi>/libmpv.so`
(FFmpeg and libplacebo static inside libmpv), as in v1.1.7. Plus `default-<abi>.jar.md5`.
Native API level 21 (as upstream), 16 KB page alignment (as upstream).

**Versions** (`buildscripts/include/depinfo.sh`; release tarballs pinned by sha256, the same pins
as `darwin/packages.lock.nix`):

| package | upstream | now |
| --- | --- | --- |
| mpv | 0.36.0-549 (`78d4374`) | 0.41.0 |
| FFmpeg | 6.0 | 8.1.3 |
| libplacebo | — | 7.360.1 (new, static, OpenGL only; plus its glad/fast_float submodule commits) |
| mbedtls | 3.4.0 | 3.6.7 (3.6 LTS; 4.x removed APIs FFmpeg uses) |
| dav1d | 1.2.0 | 1.5.4 |
| libass | 0.17.1 | 0.17.5 |
| fribidi | 1.0.12 | 1.0.18 |
| harfbuzz | 7.2.0 | 14.6.0 |
| freetype | 2.13.0 | 2.14.3 |
| libxml2 | 2.10.3 | 2.15.4 |
| NDK | 25.2.9519653 | 27.3.13750724 (r27d LTS) |
| media-kit-android-helper | `42054e5` | `42054e5` (unchanged; built with CMake instead of its Gradle app) |

**Build changes.**
- Sources are release tarballs checked against sha256 (upstream: shallow git clones of tags/branches).
  `patch.sh` uses `patch -p1` instead of `git reset --hard` + `git apply`.
- `download-sdk.sh` only installs the pinned NDK into an existing SDK (CI symlinks the runner's);
  build tools come from the workflow (meson via pip; Ubuntu 24.04 rejects `sudo pip3 install`).
- mpv: configure starts from `-Dauto_features=disabled` and enables what upstream's build
  auto-detected (`android-media-ndk cplugins egl-android gl opensles vector zlib`) plus
  `audiotrack` (a feature since 0.36, always built before). `iconv` (bionic: API 28+) and
  `aaudio` (API 26+) stay off. `-Dlibplacebo=disabled` is gone (libplacebo is mandatory since 0.37).
- libplacebo: static, `-Dauto_features=disabled -Dopengl=enabled`, no Vulkan/shaderc/glslang/lcms/dovi.
  Its `convert.cc` is C++, so `libplacebo.pc` gets `-l:libc++_static.a -l:libc++abi.a` (a plain `-lc++`
  would make libmpv need `libc++_shared.so`, which the jar doesn't ship) and the static C++ runtime
  is linked with `--exclude-libs` so it isn't exported.
- mbedtls: `make no_test` from the release tarball; on x86 (i686) `MBEDTLS_AESNI_C` is unset
  (as mpv-android does).
- libxml2: meson, `-Dminimum=true` plus push/reader/sax1/iso8859x/pattern/threads (as mpv-android).
- harfbuzz: `-Dauto_features=disabled`, raster/vector/gpu/subset/utilities off.
- freetype: optional deps (brotli, bzip2, harfbuzz, png, zlib) off. libass: no fontconfig/libunibreak.
- FFmpeg: `--disable-postproc` dropped (libpostproc was removed in 8.0). Also enables the
  `png_pipe`, `gif` and `gif_pipe` demuxers so the PNG-segment patch can detect disguised segments.
- FFmpeg, owner-approved additions (same as `windows/`): decoders `truehd mlp vc1* pgssub ccaption`;
  demuxers `mlp vc1`; parsers `mlp vc1`; filters `bwdif yadif buffer buffersink abuffer abuffersink
  format aformat null anull` (mpv inserts deinterlacers through lavfi).
- `libmediakitandroidhelper.so` is built from the same helper commit with the NDK's CMake toolchain
  (`c++_static`, Release, stripped) instead of assembling the helper's demo APK with Gradle.

## Patches (`buildscripts/patches/`)

| patch | status | why |
| --- | --- | --- |
| `mpv/mpv_lavc_set_java_vm.patch` | kept, rebased | Exports `mpv_lavc_set_java_vm`, which media_kit's `AndroidHelper` calls to hand FFmpeg the JavaVM (MediaCodec). FFmpeg is static, so `av_jni_set_java_vm` isn't visible. The header moved to `include/mpv/client.h`. |
| `ffmpeg/ffmpeg-hls-support-segments-pretend-to-be-gif-png.patch` | **added** | Copied from `windows/packages/` (wang-bin). HLS segments with a PNG/GIF header in front of TS (anime downloads) play again. |
| `ffmpeg/hls_mp4_seek.patch` | dropped | FFmpeg 8.1 seeks fMP4 HLS correctly (the smoke test checks this). |
| `ffmpeg/dash_base_url_escape.patch` | dropped | Upstream in FFmpeg 8.1. |

## Checks (CI)

- `scripts/licence_gate.sh`: every ABI's FFmpeg `config.h` has `CONFIG_GPL 0` / `CONFIG_NONFREE 0`,
  its `config.mak` references no GPL/nonfree libs, and mpv's `config.h` has `HAVE_GPL 0`.
  `scripts/test_licence_gate.sh` proves it rejects fake GPL configs (runs before every build).
- `scripts/features_gate.sh`: the added decoders/filters/demuxers are in `config_components.h`.
- `scripts/verify_jar.sh`: jar entries, SONAMEs, NEEDED allow-list (no `libc++_shared.so`),
  `mpv_lavc_set_java_vm` exported, no exported C++ runtime, 16 KB LOAD alignment, LGPL configure strings.
- `smoke/`: on an x86_64 emulator (API 30), a small NDK executable `dlopen`s libmpv.so (vo/ao null) and
  checks HTTPS fMP4 HLS open + `seek 30 absolute` landing in 30.3–36 s, Mux TS HLS plays, PNG-prefixed
  TS segments decode, the added decoders exist and `vf add bwdif` works. The same binary against
  upstream v1.1.7's x86_64 jar (MD5-verified) must fail the seek check.
