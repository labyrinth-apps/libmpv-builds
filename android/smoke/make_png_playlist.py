#!/usr/bin/env python3
"""Writes the PNG-prefixed TS HLS case of windows/smoke/smoke.py into <dir>
(p.m3u8 + s0..s2.png: a minimal PNG header followed by a Mux TS segment)."""
import os, struct, sys, urllib.request, zlib

MUX_SEG = "https://test-streams.mux.dev/x36xhzz/url_0/url_462/193039199_mp4_h264_aac_hd_7.ts"


def chunk(t, d):
    return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)


def main(out):
    os.makedirs(out, exist_ok=True)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0)) + chunk(b"IEND", b"")
    seg = urllib.request.urlopen(MUX_SEG, timeout=60).read()
    for i in range(3):
        with open(os.path.join(out, f"s{i}.png"), "wb") as f:
            f.write(png + seg)
    with open(os.path.join(out, "p.m3u8"), "w") as f:
        f.write("#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:12\n#EXT-X-PLAYLIST-TYPE:VOD\n")
        f.write("".join(f"#EXTINF:10.0,\ns{i}.png\n" for i in range(3)) + "#EXT-X-ENDLIST\n")


if __name__ == "__main__":
    main(sys.argv[1])
