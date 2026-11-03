# CLAUDE.md

Guide for working in this repo. Start with `README.md` (what ships, CI, releasing) and each folder's
`UPSTREAM.md` (what changed vs the upstream it was copied from).

## Rules
- **LGPL only.** Never enable GPL/nonfree FFmpeg components or `-Dgpl=true`; the licence gate fails the
  build if you do. New FFmpeg components go in the platform's configure list *and* `features_gate.sh`.
- **Pin everything.** Versions and sha256s live in `darwin/packages.lock.nix`,
  `android/buildscripts/include/depinfo.sh` and `windows/packages/*.cmake` (`GIT_RESET` refs). Bump the
  same version on all three platforms together.
- **Every patch is documented** in its folder's `UPSTREAM.md` (why, upstream commit if a backport, when it
  can be dropped).
- **Releases are the owner's call.** Build/smoke runs (`gh workflow run <platform>-libmpv.yml`) are fine;
  `release=true` and deleting releases are run by the owner. Never delete a release an app commit
  references.
- Keep the smoke tests honest: a new check needs a control that fails without the fix (see the seek
  control and the `--tls` gate).

## Gotchas (learned the hard way)
- **FFmpeg 8 configure:** component names (`pgssub`, `ccaption`), no `--disable-postproc` (removed), no
  `hls`/`srt` protocol options, buffer filters always built, the PNG patch needs `image_png_pipe` /
  `image_gif_pipe`. Unmatched `--enable-*=x` only warns: `windows/scripts/ffmpeg_options_check.sh` catches it.
- **mpv 0.41:** `-Dsubrandr`/`-Dlibcurl` are master-only (`mpv_options_check.sh`). Current ANGLE headers
  need the D3D9 removal backport on Windows. Without Swift (darwin) the `mac` client must not be created or
  playback waits forever; Apple frameworks must be linked explicitly (`-Db_lundef=true` exposes them).
- **macOS 27:** stock mpv 0.41 has no sound on 48 kHz (coreaudio channel-map misuse); the darwin build
  carries the upstream fix. Re-check audio on every new macOS.
- **xcframework tool:** detect iOS device slices by `platform IOS` (LC_BUILD_VERSION, minos 16).
- **TLS:** mpv's `tls-verify` reaches HLS segments (no FFmpeg default patch needed). mbedtls finishes the
  handshake and then hangs up on a bad certificate, so the smoke gate checks "connected but no request",
  not a server-side handshake error. Python's socketserver drops failed handshakes silently.
- **Smoke harness:** mpv command strings treat `\` as an escape (use `/` in Windows paths); Windows
  consoles are cp1252 (stdout uses `errors="backslashreplace"`); `keep-open=yes` or tiny files hit EOF
  before a poll; a `file://` playlist can't fetch https segments.
- **CI flakes:** ffmpeg.org resets requests from macOS runners (darwin pre-fetches with retries); the
  Windows toolchain cache expires after 7 days (re-run `windows-toolchain.yml`, 3–4 h).
- **Measuring:** compare engines only in the same hour (A/B); day-to-day network variance swamps
  differences. Mac frame drops depend on whether the window is visible.
