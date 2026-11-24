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
- **mpv 0.42 / FFmpeg 9.1:** keep libcurl off (mpv `-Dlibcurl=disabled`, FFmpeg `--disable-libcurl`; Android
  and darwin get it from `auto_features=disabled`/`--disable-autodetect`). With mpv's curl backend the app's
  `stream-lavf-o` reconnect options don't apply, and curl has no Secure Transport. Windows doesn't start from
  `auto_features=disabled`, so each new mpv auto feature must be turned off there by hand. libplacebo >= 7.387.
- **Apple without Swift:** the `mac` client must not be created or playback waits forever; Apple frameworks
  must be linked explicitly (`-Db_lundef=true` exposes them).
- **macOS 27:** mpv 0.41 had no sound on 48 kHz (fixed in 0.42). CI runs macOS 15: re-check audio on a real
  Mac on every mpv bump and new macOS.
- **xcframework tool:** detect iOS device slices by `platform IOS` (LC_BUILD_VERSION, minos 16).
- **TLS:** mpv's `tls-verify` reaches HLS segments (no FFmpeg default patch needed). mbedtls finishes the
  handshake and then hangs up on a bad certificate, so the smoke gate checks "connected but no request",
  not a server-side handshake error. Python's socketserver drops failed handshakes silently.
- **Smoke harness:** mpv command strings treat `\` as an escape (use `/` in Windows paths); Windows
  consoles are cp1252 (stdout uses `errors="backslashreplace"`); `keep-open=yes` or tiny files hit EOF
  before a poll; a `file://` playlist can't fetch https segments.
- **CI flakes:** ffmpeg.org resets requests from macOS runners (darwin pre-fetches with retries); the
  Windows toolchain cache expires after 7 days (re-run `windows-toolchain.yml`, 3–4 h).
- **Windows build image:** shinchiro keeps only the newest `ghcr.io/shinchiro/archlinux:latest`, so the
  pinned digest disappears when they push a new one (docker pull "not found"). Repin both Windows
  workflows to the current digest (ghcr `tags/list` + manifest HEAD), then rebuild the toolchain.
- **Measuring:** compare engines only in the same hour (A/B); day-to-day network variance swamps
  differences. Mac frame drops depend on whether the window is visible.
