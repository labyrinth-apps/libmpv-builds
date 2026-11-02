#!/usr/bin/env python3
"""HTTPS certificate-verification diagnostic for a built libmpv (mbedtls has no
system CA store). Reports, never fails:

  python tls_check.py <path/to/libmpv> [--ca-file /etc/ssl/cert.pem]

Opens an HTTPS HLS stream with tls-verify=yes (optionally with tls-ca-file) and
prints whether it opened. mpv's default is tls-verify=no.
"""
import argparse, ctypes, time

URL = "https://storage.googleapis.com/shaka-demo-assets/angel-one-hls/hls.m3u8"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("lib")
    ap.add_argument("--ca-file")
    a = ap.parse_args()
    m = ctypes.CDLL(a.lib)
    m.mpv_create.restype = ctypes.c_void_p
    m.mpv_initialize.argtypes = [ctypes.c_void_p]
    m.mpv_set_option_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
    m.mpv_get_property_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    m.mpv_get_property_string.restype = ctypes.c_void_p
    m.mpv_free.argtypes = [ctypes.c_void_p]
    m.mpv_command_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    m.mpv_terminate_destroy.argtypes = [ctypes.c_void_p]
    h = m.mpv_create()
    opts = [("vo", "null"), ("ao", "null"), ("tls-verify", "yes"), ("terminal", "yes"), ("msg-level", "all=warn")]
    if a.ca_file:
        opts.append(("tls-ca-file", a.ca_file))
    for k, v in opts:
        m.mpv_set_option_string(h, k.encode(), v.encode())
    m.mpv_initialize(h)
    m.mpv_command_string(h, f'loadfile "{URL}"'.encode())
    dur = None
    end = time.time() + 45
    while time.time() < end and not dur:
        r = m.mpv_get_property_string(h, b"duration")
        if r:
            dur = ctypes.string_at(r).decode()
            m.mpv_free(r)
        time.sleep(0.3)
    label = f"tls-verify=yes ca-file={a.ca_file or '(none)'}"
    print(f"TLS {'OPENED' if dur else 'FAILED'}: {label} duration={dur}", flush=True)
    m.mpv_terminate_destroy(h)


if __name__ == "__main__":
    main()
