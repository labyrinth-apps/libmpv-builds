#!/bin/bash
# Fails unless every FFmpeg build has the components added beyond media_kit's set.
# Usage: features_gate.sh <dir>...   (mk-pkg-ffmpeg outputs; reads share/ffmpeg/config_components.h)
set -u
[ $# -gt 0 ] || { echo "usage: features_gate.sh <dir>..." >&2; exit 1; }
ccs=$(find -L "$@" -path "*/share/ffmpeg/config_components.h" 2>/dev/null)
[ -n "$ccs" ] || { echo "FEATURES GATE FAILED: no share/ffmpeg/config_components.h under: $*" >&2; exit 1; }
missing=0
for cc in $ccs; do
  for c in TRUEHD_DECODER MLP_DECODER VC1_DECODER PGSSUB_DECODER CCAPTION_DECODER \
           MLP_DEMUXER VC1_DEMUXER MLP_PARSER VC1_PARSER \
           BWDIF_FILTER YADIF_FILTER BUFFER_FILTER BUFFERSINK_FILTER; do
    grep -q "^#define CONFIG_$c 1" "$cc" || { echo "missing: CONFIG_$c ($cc)" >&2; missing=1; }
  done
done
[ $missing -eq 0 ] || { echo "FEATURES GATE FAILED" >&2; exit 1; }
echo "Features gate OK ($(echo "$ccs" | wc -l | tr -d ' ') ffmpeg builds)"
