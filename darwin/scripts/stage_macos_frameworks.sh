#!/bin/bash
# Unzips macOS xcframework zips and flattens their .framework bundles into one
# directory usable as DYLD_FRAMEWORK_PATH. Usage: stage_macos_frameworks.sh <zip-dir> <out-dir>
set -euo pipefail
zips=$1 out=$2
t=$(mktemp -d)
for z in "$zips"/*.zip; do unzip -q "$z" -d "$t"; done
mkdir -p "$out"
for fw in "$t"/*.xcframework/macos-*/*.framework; do cp -R "$fw" "$out/"; done
ls "$out"
