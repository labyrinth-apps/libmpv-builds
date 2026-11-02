#!/bin/bash
# Fails unless the FFmpeg + mpv build is LGPL-only. Usage: licence_gate.sh <build_dir>
set -u
B="${1:?build dir}"
fail() { echo "LICENCE GATE FAILED: $*" >&2; exit 1; }
ffcfg=$(find "$B" -path "*ffmpeg*" -name config.h -not -path "*/tests/*" 2>/dev/null | head -1)
[ -n "$ffcfg" ] || fail "FFmpeg config.h not found under $B"
grep -q "^#define CONFIG_GPL 0" "$ffcfg" || fail "CONFIG_GPL is not 0 ($ffcfg)"
grep -q "^#define CONFIG_NONFREE 0" "$ffcfg" || fail "CONFIG_NONFREE is not 0 ($ffcfg)"
mpvcfg=$(find "$B" -path "*mpv*" -name config.h 2>/dev/null | head -1)
[ -n "$mpvcfg" ] || fail "mpv config.h not found under $B"
grep -qE "^#define HAVE_GPL 0" "$mpvcfg" || fail "mpv HAVE_GPL is not 0 ($mpvcfg)"
ffmak=$(dirname "$ffcfg")/ffbuild/config.mak
if [ -f "$ffmak" ] && grep -iqE "x264|x265|xvid|rubberband|dvdnav|vapoursynth|avisynth|frei0r|vidstab|davs2" <(grep -E "^(CONFIG_LIB|EXTRALIBS)" "$ffmak" | grep -vE "=$|= *$| no$"); then
  fail "GPL library referenced in $ffmak"
fi
echo "Licence gate OK: $ffcfg, $mpvcfg"
