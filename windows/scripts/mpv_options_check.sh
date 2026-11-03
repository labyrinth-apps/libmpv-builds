#!/usr/bin/env bash
# Fails if packages/mpv.cmake passes a -D<option> that mpv's meson.options at <ref> doesn't define
# (meson then aborts setup an hour into the build).
#   scripts/mpv_options_check.sh <mpv-ref> [mpv.cmake]
set -euo pipefail
ref="$1"
cmake_file="${2:-packages/mpv.cmake}"
opts_file="$(mktemp)"
trap 'rm -f "$opts_file"' EXIT
curl -fsSL "https://raw.githubusercontent.com/mpv-player/mpv/${ref}/meson.options" -o "$opts_file"

# Meson built-ins (not in meson.options).
builtin='^(prefix|libdir|default_library|prefer_static|debug|b_ndebug|optimization|b_lto|b_lto_mode|c_args|cpp_args|buildtype|strip|wrap_mode)$'
bad=0
for o in $(grep -oE '^\s+-D[a-z0-9_-]+' "$cmake_file" | tr -d ' \t' | sed 's/^-D//' | sort -u); do
  [[ "$o" =~ $builtin ]] && continue
  grep -qE "option\('$o'" "$opts_file" || { echo "unknown mpv option at ${ref}: $o"; bad=1; }
done
[ "$bad" = 0 ] || { echo "FAIL: fix packages/mpv.cmake for ${ref}"; exit 1; }
echo "PASS: every mpv option exists at ${ref}"
