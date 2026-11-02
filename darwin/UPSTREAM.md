# Upstream

`darwin/` is derived from [media-kit/libmpv-darwin-build](https://github.com/media-kit/libmpv-darwin-build)
at commit `aadae8ce295dd15a222839c361c4c984ce9befb2` (MIT, see `LICENSE.txt`; copyright
remains with its authors). The first commit touching `darwin/` is a pristine import
(minus upstream's `.github/` and `.vscode/`); every change since is in later commits.

Built by `.github/workflows/darwin-libmpv.yml` on GitHub Actions (`macos-15`, Xcode 16.4).

## What changed vs upstream

**Scope: LGPL `video-default` only.**
- Removed the `audio` variant, the `full` and GPL `encodersgpl` flavours, and the
  packages only they used: libx264, libvpx, libvorbis, libogg, fftools-ffi.
- FFmpeg also gets explicit `--disable-gpl --disable-nonfree` (next to `--enable-version3`,
  needed for mbedtls). mpv uses `-Dgpl=false`.
- `scripts/licence_gate.sh` fails the build unless every FFmpeg `config.h` has
  `CONFIG_GPL 0` / `CONFIG_NONFREE 0`, its `config.mak` has no GPL/nonfree libs, and every mpv
  `config.h` has `HAVE_GPL 0`. `scripts/test_licence_gate.sh` proves it rejects fake GPL configs.
  To make this possible, the ffmpeg and mpv packages now install their `config.h`
  (and FFmpeg's `config.mak`) under `share/`.

**Versions** (`packages.lock.nix`, each pinned by sha256):

| package | upstream | now |
| --- | --- | --- |
| mpv | 0.36.0 | 0.41.0 |
| FFmpeg | 6.0 | 8.1.3 |
| libplacebo | — | 7.360.1 (new, static, see below) |
| mbedtls | 3.4.1 | 3.6.7 (3.6 LTS; 4.x removed APIs FFmpeg uses; release tarball, which includes the `framework/` submodule) |
| dav1d | 1.2.1 | 1.5.4 |
| libass | 0.17.1 | 0.17.5 |
| fribidi | 1.0.13 | 1.0.18 |
| harfbuzz | 8.1.1 | 14.6.0 |
| freetype | 2.13.2 | 2.14.3 |
| libpng | 1.6.40 (+wrapdb 1.6.40-1) | 1.6.59 (+wrapdb 1.6.59-1) |
| libxml2 | 2.11.5 | 2.15.4 |
| uchardet | 0.0.8 | 0.0.8 |

libplacebo is required since mpv 0.37. It is built static, OpenGL-only (vulkan, shaderc,
glslang, lcms, dovi/libdovi, d3d11, unwind, xxhash, gl-proc-addr off) and linked into
libmpv, so the output is still the same 18 frameworks as upstream v0.7.2. Its GitHub
tarball lacks submodules, so `glad` and `fast_float` are fetched separately at the
v7.360.1 submodule commits; glad's generator runs with nixpkgs' jinja2. 7.360.1 is the
latest release that has had time to settle; 7.387.0 was a week old at import time.

**mpv options.** The configure step now starts from `-Dauto_features=disabled` and enables
only `iconv uchardet zlib gl plain-gl`, plus `cocoa coreaudio gl-cocoa videotoolbox-gl` on
macOS and `audiounit ios-gl` on iOS. Options that no longer exist in 0.41 are gone.

**Minimum OS.** `cross-files/*.ini`: iOS 16.0 (device; the simulators use
`-mios-simulator-version-min=16.0`) and macOS 13.5 (upstream had 9.0/12.0/10.9).

**Other build changes.**
- harfbuzz: `-Dauto_features=disabled -Dcoretext=enabled`, and the raster/vector/gpu/subset
  libraries are off (newer harfbuzz builds them by default; they would become extra frameworks).
- libpng: `-Dtests=false` (newer wrapdb builds test programs).
- mbedtls: `ENABLE_PROGRAMS=OFF ENABLE_TESTING=OFF`.
- FFmpeg: also enables the `png_pipe`, `gif` and `gif_pipe` demuxers, so the PNG-segment
  patch can detect disguised segments.

## Patches (`patches/`)

| patch | status | why |
| --- | --- | --- |
| `ffmpeg-hls-support-segments-pretend-to-be-gif-png.patch` | **added** | Copied from `windows/packages/` (wang-bin). HLS segments with a PNG/GIF header in front of TS (anime downloads) play again; FFmpeg 7+ refuses them otherwise. |
| `ffmpeg-fix-ios-hdr-texture.patch` | kept, rebased | iOS GLES can't take 10-bit textures, so VideoToolbox outputs BGRA for >8-bit 4:2:0. FFmpeg 8.1 also has 10-bit 4:2:2/4:4:4 VT formats (P210/P410/P216/P416) that this patch does not cover. |
| `mpv-audiounit-shared-session.patch` | kept, rebased | Ref-counted AVAudioSession plus the `audiounit-skip-session-management` option that media_kit sets. 0.41 already picks MixWithOthers vs exclusive itself; the patch now passes those options through. |
| `mpv-fix-missing-objc.patch` | kept, rebased | 0.41 only calls `add_languages('objc')` when `TOOLS/macos-sdk-version.py` finds `xcrun`, which isn't on PATH in the Nix sandbox. |
| `mpv-fix-cocoa-without-swift.patch` | **added** | `clipboard-mac.m` includes the Swift-generated `swift.h`, but meson builds it whenever `cocoa` is on. The Swift build is off here, so it is now built (and registered) only with Swift. |
| `ltmain-target-passthrough.patch` | kept, rebased | Newer libtool added `-q` to the same line. |
| `ffmpeg-fix-hls-mp4-seek.patch` | dropped | FFmpeg 8.1 seeks fMP4 HLS correctly (the smoke test checks this). |
| `ffmpeg-fix-dash-base-url-escape.patch` | dropped | Doesn't apply to 8.1; per the plan, not carried. |
| `ffmpeg-fix-vp9-hwaccel.patch` | dropped | It still applies textually but no longer compiles: it uses `FF_CODEC_CAP_ALLOCATE_PROGRESS`, which 8.x removed. Its separate `vp9_videotoolbox` decoder was also never enabled in video-default, and 8.1's stock vp9 decoder already has the VideoToolbox hwaccel. |
| `mpv-remove-libass.patch` | dropped | Only used by the removed audio variant. |

## Outputs

One zip per xcframework,
`libmpv-xcframeworks_<tag>_<ios|macos>-universal-video-default_<Framework>.zip`, the same
naming as upstream. Also `checksums.txt` (SwiftPM checksums) and
`Package-<os>.swift.snippet`, in the shape of media_kit's `libmpvArtifactBase` /
`libmpvChecksums`.
