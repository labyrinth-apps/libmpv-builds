# Upstream

- Base: [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake) at
  `bda10a2816ce9908d419b3f4b564227330457e76` (2026-10-30). Upstream publishes no licence; copied as is
  (owner decision, 2026-11-03), to be updated if upstream adds one.
- "Video" flavour (LGPL-only codec/demuxer whitelist, hardware decoding): ported from
  [media-kit/libmpv-win32-video-cmake](https://github.com/media-kit/libmpv-win32-video-cmake)
  `git diff 9c153bc 8ddbe54`, plus its `ffmpeg-hls-support-segments-pretend-to-be-gif-png.patch`
  (master `4e49192`, by wang-bin).
- Dropped: `ffmpeg-dash-base-url-escape.patch` (upstream in FFmpeg 8.1).
- `packages/mpv-0.41-angle-remove-d3d9.patch` (applied only when `MPV_REF` is `v0.41.0`): backport of
  mpv master `fd9265a905`. Current ANGLE headers no longer define `EGL_PLATFORM_ANGLE_TYPE_D3D9_ANGLE`.
  It only removes mpv's own D3D9 window renderer; media_kit renders through its own D3D11 ANGLE context.
- FFmpeg 8 / mpv 0.41 option fixes: no `--disable-postproc` (libpostproc removed in FFmpeg 8), no
  `-Dsubrandr`/`-Dlibcurl` (mpv master only). `scripts/{ffmpeg,mpv}_options_check.sh` fail the build
  in its first minute on any option the chosen version doesn't know.
