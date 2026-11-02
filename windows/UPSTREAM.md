# Upstream

- Base: [shinchiro/mpv-winbuild-cmake](https://github.com/shinchiro/mpv-winbuild-cmake) at
  `bda10a2816ce9908d419b3f4b564227330457e76` (2026-10-30). Upstream publishes no licence; copied as is
  (owner decision, 2026-11-03), to be updated if upstream adds one.
- "Video" flavour (LGPL-only codec/demuxer whitelist, hardware decoding): ported from
  [media-kit/libmpv-win32-video-cmake](https://github.com/media-kit/libmpv-win32-video-cmake)
  `git diff 9c153bc 8ddbe54`, plus its `ffmpeg-hls-support-segments-pretend-to-be-gif-png.patch`
  (master `4e49192`, by wang-bin).
- Dropped: `ffmpeg-dash-base-url-escape.patch` (upstream in FFmpeg 8.1).
