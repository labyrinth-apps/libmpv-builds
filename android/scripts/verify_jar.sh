#!/bin/bash
# Checks a default-<abi>.jar has upstream v1.1.7's layout and a loadable, LGPL libmpv.
# Usage: verify_jar.sh <default-<abi>.jar> <llvm bin dir>
set -euo pipefail
jar=${1:?jar}; bin=${2:?llvm bin dir}
abi=$(basename "$jar" .jar); abi=${abi#default-}
fail() { echo "VERIFY FAILED ($abi): $*" >&2; exit 1; }
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
unzip -q "$jar" -d "$t"

entries=$(unzip -Z1 "$jar" | sort | tr '\n' ' ')
[ "$entries" == "lib/$abi/libmediakitandroidhelper.so lib/$abi/libmpv.so " ] || fail "entries: $entries"

allowed=" libc.so libm.so libdl.so liblog.so libandroid.so libEGL.so libOpenSLES.so libmediandk.so libz.so "
for so in libmpv.so libmediakitandroidhelper.so; do
  f="$t/lib/$abi/$so"
  dyn=$("$bin/llvm-readelf" -d "$f")
  soname=$(echo "$dyn" | sed -n 's/.*(SONAME).*\[\(.*\)\]/\1/p')
  [ "$soname" == "$so" ] || fail "$so SONAME is '$soname'"
  for n in $(echo "$dyn" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p'); do
    [[ "$allowed" == *" $n "* ]] || fail "$so needs $n"
  done
  echo "$so NEEDED: $(echo "$dyn" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p' | tr '\n' ' ')"
  # 16 KB page alignment (Android 15+)
  aligns=$("$bin/llvm-readelf" -lW "$f" | awk '$1=="LOAD"{print $NF}' | sort -u | tr '\n' ' ')
  [ "$aligns" == "0x4000 " ] || fail "$so LOAD alignment: $aligns"
done

mpv="$t/lib/$abi/libmpv.so"
# (files, not pipes: grep -q closing early + pipefail would fail the check)
"$bin/llvm-nm" -D --defined-only "$mpv" > "$t/syms"
for s in mpv_create mpv_initialize mpv_lavc_set_java_vm mpv_render_context_create; do
  grep -qw "$s" "$t/syms" || fail "libmpv.so does not export $s"
done
if grep -qE " (_ZNSt|_ZSt|__cxa_)" "$t/syms"; then fail "libmpv.so exports C++ runtime symbols"; fi

"$bin/llvm-strings" "$mpv" > "$t/strs"
grep -q -- "--disable-gpl" "$t/strs" || fail "FFmpeg configuration lacks --disable-gpl"
if grep -qE -- "--enable-(gpl|nonfree)" "$t/strs"; then fail "FFmpeg configured with GPL/nonfree"; fi
grep -q -- "-Dgpl=false" "$t/strs" || fail "mpv configuration lacks -Dgpl=false"
grep -m1 "^mpv v" "$t/strs" || true
echo "OK $abi: $(stat -c %s "$jar") bytes"
