#!/bin/bash
# Sanity checks on the built xcframework zips of one platform.
# Usage: verify_xcframeworks.sh <dir-with-zips> <ios|macos>
set -euo pipefail
dir=$1 os=$2
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
for z in "$dir"/*.zip; do unzip -q "$z" -d "$t"; done
rc=0
err() { echo "ERROR: $*" >&2; rc=1; }

if [ "$os" = ios ]; then
  slices="ios-arm64:arm64:16.0 ios-arm64_x86_64-simulator:arm64,x86_64:16.0"
else
  slices="macos-arm64_x86_64:arm64,x86_64:13.5"
fi

for xc in "$t"/*.xcframework; do
  name=$(basename "$xc" .xcframework)
  for s in $slices; do
    IFS=: read -r slice archs minos <<<"$s"
    fw="$xc/$slice/$name.framework"
    bin="$fw/$name"
    if [ ! -e "$bin" ]; then
      err "$name: missing $slice slice (found: $(ls "$xc" | tr '\n' ' '))"
      [ "$name" = Mpv ] && plutil -p "$xc/Info.plist" | grep -E "LibraryIdentifier|SupportedPlatform" >&2
      continue
    fi
    got=$(lipo -archs "$bin" | tr ' ' '\n' | sort | paste -sd, -)
    want=$(echo "$archs" | tr ',' '\n' | sort | paste -sd, -)
    [ "$got" = "$want" ] || err "$name/$slice: archs $got, want $want"
    for a in ${archs//,/ }; do
      m=$(vtool -arch "$a" -show-build "$bin" | awk '/minos/ {print $2}')
      [ "$m" = "$minos" ] || err "$name/$slice/$a: minos '$m', want $minos"
    done
    if otool -L "$bin" | grep -qE "/nix/store|libplacebo"; then
      err "$name/$slice: bad load command: $(otool -L "$bin" | grep -E '/nix/store|libplacebo')"
    fi
  done
done
[ "$rc" = 0 ] && echo "verify OK: $(ls -d "$t"/*.xcframework | wc -l | tr -d ' ') xcframeworks ($os)"
otool -L "$t/Mpv.xcframework/"*"/Mpv.framework/Mpv" 2>/dev/null | head -40 || true
exit $rc
