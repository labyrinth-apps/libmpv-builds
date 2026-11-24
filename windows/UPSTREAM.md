# Upstream

- Base: [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake) at
  `bda10a2816ce9908d419b3f4b564227330457e76` (2026-10-30). Upstream publishes no licence; copied as is
  (owner decision, 2026-11-03), to be updated if upstream adds one.
- "Video" flavour (LGPL-only codec/demuxer whitelist, hardware decoding): ported from
  [media-kit/libmpv-win32-video-cmake](https://github.com/media-kit/libmpv-win32-video-cmake)
  `git diff 9c153bc 8ddbe54`, plus its `ffmpeg-hls-support-segments-pretend-to-be-gif-png.patch`
  (master `4e49192`, by wang-bin).
- Dropped: `ffmpeg-dash-base-url-escape.patch` (upstream in FFmpeg 8.1).
- Dropped (2026-11-24, mpv 0.42): `mpv-0.41-angle-remove-d3d9.patch`, the backport of mpv `fd9265a905`
  (current ANGLE headers have no D3D9); 0.42 includes it.
- mpv 0.42 / FFmpeg 9.1: `-Dlibcurl`, `-Dsubrandr`, `-Damf`, `-Ddvda` disabled (new auto features; this
  build doesn't start from `auto_features=disabled`) and FFmpeg `--disable-libcurl` (autodetected since
  9.1). Networking stays on FFmpeg's http/tls, so the app's `stream-lavf-o` reconnect options keep
  working. No `--disable-postproc` (removed in FFmpeg 8). `scripts/{ffmpeg,mpv}_options_check.sh` fail
  the build in its first minute on any option the chosen version doesn't know.
- dav1d pinned to 1.5.5 (`6c7bee68`), up from an older master commit.
- TLS: FFmpeg uses Schannel (`--enable-schannel`) instead of OpenSSL, so `tls-verify=yes` checks against
  the Windows trust store (OpenSSL had none). Gate: `smoke.py --tls`.
