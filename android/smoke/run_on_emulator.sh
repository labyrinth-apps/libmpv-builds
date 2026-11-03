#!/bin/bash
# Runs inside android-emulator-runner (one script so state survives between steps).
# Usage: run_on_emulator.sh <work dir with: smoke, png/, ours/libmpv.so, control/libmpv.so> <mpv> <ffmpeg>
set -euo pipefail
w=${1:?work dir}; mpv_v=${2:?}; ff_v=${3:?}
d=/data/local/tmp/smoke
adb wait-for-device
adb shell getprop ro.build.version.sdk
adb shell getprop ro.product.cpu.abi
adb shell rm -rf $d
adb shell mkdir -p $d/ours $d/control $d/png
adb push "$w/smoke" $d/ >/dev/null
adb push "$w/ours/libmpv.so" $d/ours/ >/dev/null
adb push "$w/control/libmpv.so" $d/control/ >/dev/null
adb push "$w/png/." $d/png/ >/dev/null
adb shell chmod 755 $d/smoke
adb shell ls -la $d $d/png

echo "::group::our build"
adb shell "cd $d && ./smoke ./ours/libmpv.so $d/png/p.m3u8 --expect-mpv v$mpv_v --expect-ffmpeg $ff_v --extended; echo SMOKE_EXIT=\$?" 2>&1 | tee "$w/ours.log"
echo "::endgroup::"
echo "::group::control (upstream v1.1.7)"
adb shell "cd $d && ./smoke ./control/libmpv.so $d/png/p.m3u8; echo SMOKE_EXIT=\$?" 2>&1 | tee "$w/control.log"
echo "::endgroup::"

rc=0
if grep -q "^ALL PASS" "$w/ours.log" && grep -q "^SMOKE_EXIT=0" "$w/ours.log"; then
  echo "Our build: ALL PASS"
else
  echo "Our build FAILED the smoke test" >&2; rc=1
fi
# The PNG case must be decoded *because of* the patch, not by luck of the TS probe.
if grep -q "segments pretend to be png" "$w/ours.log"; then
  echo "PNG-segment patch detected the disguised segments"
else
  echo "PNG-segment patch did not report detecting PNG segments" >&2; rc=1
fi
# Control must get past the HTTPS open check and fail exactly on the seek.
if grep -q "^PASS HTTPS fMP4 HLS opens" "$w/control.log" &&
   grep -q "^FAIL fMP4 seek lands near the target" "$w/control.log"; then
  echo "Control (FFmpeg 6) failed the seek check as expected"
else
  echo "Control did not fail the way it should: the smoke test may no longer catch the FFmpeg 6 seek bug" >&2; rc=1
fi
exit $rc
