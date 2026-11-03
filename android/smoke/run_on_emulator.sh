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

# Untrusted-certificate HTTPS server on the host (the emulator reaches it at 10.0.2.2).
python3 -u -c '
import http.server, ssl, sys
class S(http.server.ThreadingHTTPServer):
    def get_request(self):  # socketserver drops failed handshakes silently
        print("TLS connection", flush=True)
        return super().get_request()
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):
        print("REQUEST", self.path, flush=True)
srv = S(("0.0.0.0", 8443), H)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER); ctx.load_cert_chain(sys.argv[1])
srv.socket = ctx.wrap_socket(srv.socket, server_side=True); srv.serve_forever()
' "$(dirname "$0")/../../windows/smoke/selfsigned-untrusted.pem" > "$w/untrusted-server.log" 2>&1 &
trap 'kill %1 2>/dev/null || true' EXIT
adb shell ls -la $d $d/png

echo "::group::our build"
adb shell "cd $d && ./smoke ./ours/libmpv.so $d/png/p.m3u8 --expect-mpv v$mpv_v --expect-ffmpeg $ff_v --extended --tls --untrusted-url https://10.0.2.2:8443/; echo SMOKE_EXIT=\$?" 2>&1 | tee "$w/ours.log"
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
# The untrusted check only counts if the emulator really connected to the server
# and then sent no request (not a dead server or a network error).
if grep -q "TLS connection" "$w/untrusted-server.log" && ! grep -q "^REQUEST" "$w/untrusted-server.log"; then
  echo "Untrusted server: connected, no request (certificate rejected)"
else
  echo "Untrusted server log doesn't prove a rejection" >&2
  cat "$w/untrusted-server.log" >&2 || true
  rc=1
fi
# Control must get past the HTTPS open check and fail exactly on the seek.
if grep -q "^PASS HTTPS fMP4 HLS opens" "$w/control.log" &&
   grep -q "^FAIL fMP4 seek lands near the target" "$w/control.log"; then
  echo "Control (FFmpeg 6) failed the seek check as expected"
else
  echo "Control did not fail the way it should: the smoke test may no longer catch the FFmpeg 6 seek bug" >&2; rc=1
fi
exit $rc
