#!/bin/bash
# Fails unless FFmpeg was built with the components added beyond media_kit's set.
# Usage: features_gate.sh <build_dir>
set -u
B="${1:?build dir}"
cc=$(find "$B" -path "*ffmpeg*" -name config_components.h 2>/dev/null | head -1)
[ -n "$cc" ] || { echo "FEATURES GATE FAILED: config_components.h not found under $B" >&2; exit 1; }
missing=0
# (buffer/buffersink filters are always built in FFmpeg 8: no option, no CONFIG_ symbol)
for c in TRUEHD_DECODER MLP_DECODER VC1_DECODER PGSSUB_DECODER CCAPTION_DECODER \
         BWDIF_FILTER YADIF_FILTER FORMAT_FILTER NULL_FILTER IMAGE_PNG_PIPE_DEMUXER; do
  grep -q "^#define CONFIG_$c 1" "$cc" || { echo "missing: CONFIG_$c" >&2; missing=1; }
done
[ $missing -eq 0 ] || { echo "FEATURES GATE FAILED ($cc)" >&2; exit 1; }
echo "Features gate OK: $cc"
