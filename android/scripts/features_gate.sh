#!/bin/bash
# Fails unless every FFmpeg build found has the components added beyond media_kit's set.
# Usage: features_gate.sh <dir>...   (finds */ffmpeg/config_components.h)
set -u
ccs=$(find -L "$@" -path "*/ffmpeg/config_components.h" 2>/dev/null)
[ -n "$ccs" ] || { echo "FEATURES GATE FAILED: no ffmpeg/config_components.h under: $*" >&2; exit 1; }
for cc in $ccs; do
  missing=0
  for c in TRUEHD_DECODER MLP_DECODER VC1_DECODER PGSSUB_DECODER CCAPTION_DECODER \
           BWDIF_FILTER YADIF_FILTER BUFFER_FILTER BUFFERSINK_FILTER \
           PNG_PIPE_DEMUXER GIF_DEMUXER GIF_PIPE_DEMUXER; do
    grep -q "^#define CONFIG_$c 1" "$cc" || { echo "missing: CONFIG_$c ($cc)" >&2; missing=1; }
  done
  [ $missing -eq 0 ] || { echo "FEATURES GATE FAILED ($cc)" >&2; exit 1; }
  echo "Features gate OK: $cc"
done
