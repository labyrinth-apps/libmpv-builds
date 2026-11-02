#!/bin/bash
# Fixture tests for licence_gate.sh: GPL/nonfree/missing configs must fail.
set -u
here=$(cd "$(dirname "$0")" && pwd)
gate="$here/licence_gate.sh"
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mk() { # mk <dir> <gpl> <nonfree> <mpv_gpl> [extra config.mak line]
  mkdir -p "$1/ff/share/ffmpeg" "$1/mpv/share/mpv"
  printf '#define CONFIG_GPL %s\n#define CONFIG_NONFREE %s\n' "$2" "$3" > "$1/ff/share/ffmpeg/config.h"
  printf 'CONFIG_LIBDAV1D=yes\n!CONFIG_LIBX264=yes\n%s\n' "${5:-}" > "$1/ff/share/ffmpeg/config.mak"
  printf '#define HAVE_GPL %s\n' "$4" > "$1/mpv/share/mpv/config.h"
}
rc=0
expect() { # expect <pass|fail> <name> <dir>...
  want=$1 name=$2; shift 2
  if "$gate" "$@" >/dev/null 2>&1; then got=pass; else got=fail; fi
  if [ "$got" = "$want" ]; then echo "ok   $name ($got)"; else echo "FAIL $name: expected $want, got $got"; rc=1; fi
}
mk "$t/clean" 0 0 0;                         expect pass clean "$t/clean"
mk "$t/ffgpl" 1 0 0;                         expect fail ffmpeg-gpl "$t/ffgpl"
mk "$t/nonfree" 0 1 0;                       expect fail ffmpeg-nonfree "$t/nonfree"
mk "$t/mpvgpl" 0 0 1;                        expect fail mpv-gpl "$t/mpvgpl"
mk "$t/x264" 0 0 0 "CONFIG_LIBX264=yes";     expect fail ffmpeg-x264 "$t/x264"
mk "$t/nompv" 0 0 0; rm -r "$t/nompv/mpv";   expect fail mpv-missing "$t/nompv"
mk "$t/noff" 0 0 0; rm -r "$t/noff/ff";      expect fail ffmpeg-missing "$t/noff"
mk "$t/mixa" 0 0 0; mk "$t/mixb" 1 0 0;      expect fail one-of-two-gpl "$t/mixa" "$t/mixb"
mk "$t/okb" 0 0 0;                           expect pass two-clean "$t/mixa" "$t/okb"
exit $rc
