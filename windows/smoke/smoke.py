#!/usr/bin/env python3
"""Smoke test for a built libmpv (ctypes, headless: vo=null ao=null).

  python smoke.py <path/to/libmpv-2.dll> [--expect-mpv 0.41.0] [--expect-ffmpeg 8.1.3]

Checks the cases the app depends on and exits non-zero on the first failure:
- HTTPS fMP4 HLS with separate audio (drama-like) opens and a seek lands near its
  target (FFmpeg <= 7.1 runs to EOF instead);
- MPEG-TS HLS (anime-like) plays;
- TS segments disguised with a PNG header (anime downloads) decode;
- an .ass subtitle loads;
- with --extended: TrueHD/MLP and VC-1 decoders exist and the bwdif deinterlacer
  can be inserted (PGS/EIA-608 are checked at build time: scripts/features_gate.sh).
"""
import argparse, ctypes, json, os, struct, sys, tempfile, time, urllib.request, zlib

SHAKA = "https://storage.googleapis.com/shaka-demo-assets/angel-one-hls/hls.m3u8"
MUX = "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"
MUX_SEG = "https://test-streams.mux.dev/x36xhzz/url_0/url_462/193039199_mp4_h264_aac_hd_7.ts"


LOG = os.path.join(tempfile.gettempdir(), "mpv-smoke.log")


def mpv_path(p):
    # mpv's command string treats backslashes as escapes (Windows paths).
    return p.replace("\\", "/")


# --tls: what the app sets on our builds (certificate checks on).
EXTRA_OPTS = []
GOOD_CERT = SHAKA
# Self-signed for another hostname (test fixture, valid until 2126).
BAD_PEM = os.path.join(os.path.dirname(os.path.abspath(__file__)), "selfsigned-untrusted.pem")


class Mpv:
    def __init__(self, lib, extra=()):
        self.m = lib
        self.h = lib.mpv_create()
        for k, v in [("vo", "null"), ("ao", "null"), ("hr-seek", "yes"),
                     ("demuxer-lavf-o", "allowed_extensions=ALL"),
                     ("log-file", mpv_path(LOG)), ("msg-level", "all=v"),
                     *EXTRA_OPTS, *extra]:
            lib.mpv_set_option_string(self.h, k.encode(), v.encode())
        lib.mpv_initialize(self.h)

    def get(self, name):
        r = self.m.mpv_get_property_string(self.h, name.encode())
        if not r:
            return None
        s = ctypes.string_at(r).decode()
        self.m.mpv_free(r)
        return s

    def cmd(self, s):
        return self.m.mpv_command_string(self.h, s.encode())

    def close(self):
        self.m.mpv_terminate_destroy(self.h)


def load(path):
    lib = ctypes.CDLL(path)
    lib.mpv_create.restype = ctypes.c_void_p
    lib.mpv_initialize.argtypes = [ctypes.c_void_p]
    lib.mpv_set_option_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
    lib.mpv_get_property_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    lib.mpv_get_property_string.restype = ctypes.c_void_p
    lib.mpv_free.argtypes = [ctypes.c_void_p]
    lib.mpv_command_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    lib.mpv_terminate_destroy.argtypes = [ctypes.c_void_p]
    return lib


def wait(cond, timeout):
    end = time.time() + timeout
    while time.time() < end:
        if cond():
            return True
        time.sleep(0.2)
    return False


def fnum(s):
    try:
        return float(s)
    except (TypeError, ValueError):
        return None


def check(ok, msg):
    print(("PASS " if ok else "FAIL ") + msg, flush=True)
    if not ok:
        try:
            lines = open(LOG, encoding="utf-8", errors="replace").read().splitlines()
            print("--- last mpv log lines ---", *lines[-60:], sep="\n", flush=True)
        except OSError:
            pass
        sys.exit(1)


def png_prefixed_playlist(tmp):
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0)) + chunk(b"IEND", b"")
    seg = urllib.request.urlopen(MUX_SEG, timeout=60).read()
    for i in range(3):
        with open(os.path.join(tmp, f"s{i}.png"), "wb") as f:
            f.write(png + seg)
    p = os.path.join(tmp, "p.m3u8")
    with open(p, "w") as f:
        f.write("#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:12\n#EXT-X-PLAYLIST-TYPE:VOD\n")
        f.write("".join(f"#EXTINF:10.0,\ns{i}.png\n" for i in range(3)) + "#EXT-X-ENDLIST\n")
    return p


def opens_raw(lib, url):
    """True if the TLS connection succeeded (rawaudio accepts any bytes)."""
    p = Mpv(lib, [("demuxer", "rawaudio")])
    p.cmd(f'loadfile "{url}"')
    ok = wait(lambda: p.get("file-format") == "rawaudio", 20)
    p.close()
    return ok


class _Server:
    """Local HTTP or HTTPS (untrusted cert) server; records request paths."""

    def __init__(self, directory, tls=False):
        import functools, http.server, ssl, threading
        self.paths = []
        self.connections = 0  # TLS connections, whether or not the handshake finished
        outer = self

        class H(http.server.SimpleHTTPRequestHandler):
            def log_message(self, *a):
                outer.paths.append(self.path)

        class S(http.server.ThreadingHTTPServer):
            def get_request(self):  # socketserver drops failed handshakes silently
                outer.connections += 1
                return super().get_request()

        self.srv = S(("127.0.0.1", 0), functools.partial(H, directory=directory))
        if tls:
            ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            ctx.load_cert_chain(BAD_PEM)
            self.srv.socket = ctx.wrap_socket(self.srv.socket, server_side=True)
        self.url = f"{'https' if tls else 'http'}://127.0.0.1:{self.srv.server_port}"
        threading.Thread(target=self.srv.serve_forever, daemon=True).start()

    def close(self):
        self.srv.shutdown()


def tls_checks(lib):
    check(opens_raw(lib, GOOD_CERT), "TLS: valid certificate accepted")
    with tempfile.TemporaryDirectory() as tmp:
        with open(os.path.join(tmp, "seg.ts"), "wb") as f:
            f.write(urllib.request.urlopen(MUX_SEG, timeout=60).read())
        bad = _Server(tmp, tls=True)
        # Rejected = the client connected but never sent a request.
        check(not opens_raw(lib, f"{bad.url}/seg.ts") and not bad.paths
              and bad.connections > 0, "TLS: untrusted certificate rejected")
        before = bad.connections
        # HLS segments get FFmpeg's default, not mpv's tls-verify: must still
        # verify. The playlist comes over plain HTTP (file:// can't fetch https).
        with open(os.path.join(tmp, "p.m3u8"), "w") as f:
            f.write("#EXTM3U\n#EXT-X-TARGETDURATION:12\n#EXT-X-PLAYLIST-TYPE:VOD\n"
                    f"#EXTINF:10.0,\n{bad.url}/seg.ts\n#EXT-X-ENDLIST\n")
        plain = _Server(tmp)
        p = Mpv(lib)
        p.cmd(f'loadfile "{plain.url}/p.m3u8"')
        played = wait(lambda: (fnum(p.get("time-pos")) or 0) > 1.0, 15)
        p.close()
        plain.close()
        bad.close()
        check(not played and "/seg.ts" not in bad.paths and bad.connections > before,
              "TLS: HLS segment behind an untrusted certificate is rejected")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dll")
    ap.add_argument("--expect-mpv")
    ap.add_argument("--expect-ffmpeg")
    ap.add_argument("--extended", action="store_true",
                    help="also require the decoders/filters added beyond media_kit's set")
    ap.add_argument("--tls", action="store_true",
                    help="run with tls-verify=yes and require bad certificates to be rejected")
    a = ap.parse_args()
    # Windows consoles (cp1252) can't print every character in mpv's log.
    sys.stdout.reconfigure(errors="backslashreplace")
    lib = load(a.dll)
    if a.tls:
        EXTRA_OPTS.append(("tls-verify", "yes"))
        tls_checks(lib)

    p = Mpv(lib)
    p.cmd(f'loadfile "{MUX}"')
    wait(lambda: p.get("ffmpeg-version"), 30)
    mv, fv = p.get("mpv-version"), p.get("ffmpeg-version")
    print(f"engine: {mv} / FFmpeg {fv}", flush=True)
    if a.expect_mpv:
        check(a.expect_mpv in (mv or ""), f"mpv version contains {a.expect_mpv}")
    if a.expect_ffmpeg:
        check(a.expect_ffmpeg in (fv or ""), f"FFmpeg version contains {a.expect_ffmpeg}")
    check(wait(lambda: (fnum(p.get("time-pos")) or 0) > 1.0, 60), "MPEG-TS HLS plays (mux)")
    if a.extended:
        decoders = {d.get("codec") for d in json.loads(p.get("decoder-list") or "[]")}
        for want in ["truehd", "mlp", "vc1"]:  # subtitle decoders aren't listed here
            check(want in decoders, f"decoder available: {want}")
        check(p.cmd("vf add bwdif") >= 0, "bwdif deinterlacer can be inserted (lavfi)")
    p.close()

    p = Mpv(lib)
    p.cmd(f'loadfile "{SHAKA}"')
    check(wait(lambda: fnum(p.get("duration")), 60), "HTTPS fMP4 HLS opens (shaka)")
    tracks = json.loads(p.get("track-list") or "[]")
    check(any(t.get("type") == "audio" for t in tracks), "shaka has an audio track")
    p.cmd("seek 30 absolute")
    landed = wait(lambda: 30.3 < (fnum(p.get("time-pos")) or 0) < 36, 30)
    print(f"  after seek: time-pos={p.get('time-pos')} eof={p.get('eof-reached')}", flush=True)
    check(landed, "fMP4 seek lands near the target (not EOF)")
    p.close()

    with tempfile.TemporaryDirectory() as tmp:
        pl = png_prefixed_playlist(tmp)
        p = Mpv(lib)
        p.cmd(f'loadfile "{mpv_path(pl)}"')
        check(wait(lambda: (fnum(p.get("time-pos")) or 0) > 1.0, 60),
              "PNG-disguised TS segments decode (anime downloads)")
        ass = os.path.join(tmp, "t.ass")
        with open(ass, "w", encoding="utf-8") as f:
            f.write("[Script Info]\nScriptType: v4.00+\n\n[V4+ Styles]\n"
                    "Format: Name, Fontname, Fontsize\nStyle: Default,Arial,20\n\n[Events]\n"
                    "Format: Layer, Start, End, Style, Text\n"
                    "Dialogue: 0,0:00:00.00,0:00:05.00,Default,hello\n")
        p.cmd(f'sub-add "{mpv_path(ass)}"')
        check(wait(lambda: any(t.get("type") == "sub" for t in json.loads(p.get("track-list") or "[]")), 10),
              "ASS subtitle loads")
        p.close()
    print("ALL PASS", flush=True)


if __name__ == "__main__":
    main()
