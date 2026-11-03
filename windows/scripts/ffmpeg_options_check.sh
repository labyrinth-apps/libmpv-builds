#!/usr/bin/env bash
# Fails if packages/ffmpeg.cmake passes FFmpeg's configure an option it doesn't know, or a
# component pattern that matches nothing (configure only warns, so renamed/removed components
# would silently drop out). Runs configure's option parsing only; dependency probes may fail.
#   scripts/ffmpeg_options_check.sh <ffmpeg-ref> [ffmpeg.cmake]
set -euo pipefail
ref="$1"
cmake_file="${2:-packages/ffmpeg.cmake}"
src="$(mktemp -d)"
trap 'rm -rf "$src"' EXIT

curl -fsSL "https://github.com/FFmpeg/FFmpeg/archive/refs/tags/${ref}.tar.gz" | tar xz -C "$src" --strip-components=1

# Literal --enable-*/--disable-* options; skip ones built from CMake variables.
mapfile -t opts < <(grep -oE '^\s+--(enable|disable)-[A-Za-z0-9_-]+(=[A-Za-z0-9_*]+)?\s*$' "$cmake_file" | tr -d ' \t')
echo "checking ${#opts[@]} options against FFmpeg ${ref}"

out="$(cd "$src" && ./configure --disable-x86asm "${opts[@]}" 2>&1 || true)"
bad="$(grep -E 'Unknown option|did not match anything' <<<"$out" || true)"
if [ -n "$bad" ]; then
  echo "$bad"
  echo "FAIL: fix packages/ffmpeg.cmake for ${ref}"
  exit 1
fi
echo "PASS: every option is known and every component pattern matches"
