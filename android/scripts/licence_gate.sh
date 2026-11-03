#!/bin/bash
# Fails unless every FFmpeg + mpv build found is LGPL-only.
# Usage: licence_gate.sh <dir>...   (e.g. buildscripts/artifacts/licence)
# Expects <..>/ffmpeg/{config.h,config.mak} and <..>/mpv/config.h (staged by bundle_default.sh).
set -u
fail() { echo "LICENCE GATE FAILED: $*" >&2; exit 1; }
[ $# -gt 0 ] || fail "usage: licence_gate.sh <dir>..."

ffcfgs=$(find -L "$@" -path "*/ffmpeg/config.h" 2>/dev/null)
mpvcfgs=$(find -L "$@" -path "*/mpv/config.h" 2>/dev/null)
[ -n "$ffcfgs" ] || fail "no ffmpeg/config.h found under: $*"
[ -n "$mpvcfgs" ] || fail "no mpv/config.h found under: $*"

for cfg in $ffcfgs; do
  grep -q "^#define CONFIG_GPL 0" "$cfg" || fail "CONFIG_GPL is not 0 ($cfg)"
  grep -q "^#define CONFIG_NONFREE 0" "$cfg" || fail "CONFIG_NONFREE is not 0 ($cfg)"
  mak=$(dirname "$cfg")/config.mak
  [ -f "$mak" ] || fail "config.mak missing next to $cfg"
  if grep -E "^(CONFIG_LIB|EXTRALIBS)" "$mak" | grep -vE "=$|= *$| no$" |
    grep -iqE "x264|x265|xvid|rubberband|dvdnav|vapoursynth|avisynth|frei0r|vidstab|davs2|fdk"; then
    fail "GPL/nonfree library referenced in $mak"
  fi
  echo "ffmpeg OK: $cfg"
done
for cfg in $mpvcfgs; do
  grep -qE "^#define HAVE_GPL 0" "$cfg" || fail "mpv HAVE_GPL is not 0 ($cfg)"
  echo "mpv OK: $cfg"
done
echo "Licence gate OK ($(echo "$ffcfgs" | wc -l | tr -d ' ') ffmpeg, $(echo "$mpvcfgs" | wc -l | tr -d ' ') mpv)"
