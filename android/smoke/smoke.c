// Android port of windows/smoke/smoke.py: drives a libmpv.so through the client
// API (dlopen, vo=null ao=null) on a device/emulator and exits non-zero on the
// first failed check. Same check names as smoke.py, so CI greps carry over.
//
//   smoke <libmpv.so> <png-playlist.m3u8> [--expect-mpv X] [--expect-ffmpeg Y] [--extended]
#include <dlfcn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define SHAKA "https://storage.googleapis.com/shaka-demo-assets/angel-one-hls/hls.m3u8"
#define MUX "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8"

static void *(*mpv_create)(void);
static int (*mpv_initialize)(void *);
static int (*mpv_set_option_string)(void *, const char *, const char *);
static char *(*mpv_get_property_string)(void *, const char *);
static void (*mpv_free)(void *);
static int (*mpv_command_string)(void *, const char *);
static void (*mpv_terminate_destroy)(void *);

static void *h;
static char buf[1 << 16];

static void *sym(void *lib, const char *n)
{
    void *p = dlsym(lib, n);
    if (!p) {
        printf("FAIL symbol %s: %s\n", n, dlerror());
        exit(1);
    }
    return p;
}

static void open_player(void)
{
    h = mpv_create();
    mpv_set_option_string(h, "vo", "null");
    mpv_set_option_string(h, "ao", "null");
    mpv_set_option_string(h, "hr-seek", "yes");
    mpv_set_option_string(h, "demuxer-lavf-o", "allowed_extensions=ALL");
    mpv_set_option_string(h, "terminal", "yes");
    mpv_set_option_string(h, "msg-level", getenv("SMOKE_MSG_LEVEL") ? getenv("SMOKE_MSG_LEVEL") : "all=warn");
    mpv_initialize(h);
}

static void close_player(void)
{
    mpv_terminate_destroy(h);
    h = NULL;
}

// Returns the property in a static buffer, or NULL.
static const char *get(const char *name)
{
    char *r = mpv_get_property_string(h, name);
    if (!r)
        return NULL;
    snprintf(buf, sizeof(buf), "%s", r);
    mpv_free(r);
    return buf;
}

static double num(const char *name, double dflt)
{
    const char *s = get(name);
    char *end;
    if (!s)
        return dflt;
    double v = strtod(s, &end);
    return end == s ? dflt : v;
}

static double now(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

#define WAIT(cond, timeout) ({                       \
    double end_ = now() + (timeout);                 \
    bool ok_ = false;                                \
    while (now() < end_) {                           \
        if (cond) { ok_ = true; break; }             \
        usleep(200000);                              \
    }                                                \
    ok_; })

static void check(bool ok, const char *msg)
{
    printf("%s %s\n", ok ? "PASS" : "FAIL", msg);
    fflush(stdout);
    if (!ok)
        exit(1);
}

static bool has(const char *prop, const char *needle)
{
    const char *s = get(prop);
    return s && strstr(s, needle);
}

int main(int argc, char **argv)
{
    if (argc < 3) {
        fprintf(stderr, "usage: smoke <libmpv.so> <png-playlist.m3u8> [--expect-mpv X] "
                        "[--expect-ffmpeg Y] [--extended]\n");
        return 2;
    }
    const char *expect_mpv = NULL, *expect_ff = NULL;
    bool extended = false;
    for (int i = 3; i < argc; i++) {
        if (!strcmp(argv[i], "--expect-mpv") && i + 1 < argc)
            expect_mpv = argv[++i];
        else if (!strcmp(argv[i], "--expect-ffmpeg") && i + 1 < argc)
            expect_ff = argv[++i];
        else if (!strcmp(argv[i], "--extended"))
            extended = true;
    }

    void *lib = dlopen(argv[1], RTLD_NOW);
    if (!lib) {
        printf("FAIL dlopen: %s\n", dlerror());
        return 1;
    }
    mpv_create = sym(lib, "mpv_create");
    mpv_initialize = sym(lib, "mpv_initialize");
    mpv_set_option_string = sym(lib, "mpv_set_option_string");
    mpv_get_property_string = sym(lib, "mpv_get_property_string");
    mpv_free = sym(lib, "mpv_free");
    mpv_command_string = sym(lib, "mpv_command_string");
    mpv_terminate_destroy = sym(lib, "mpv_terminate_destroy");
    check(dlsym(lib, "mpv_lavc_set_java_vm") != NULL, "mpv_lavc_set_java_vm exported");

    char cmd[4096];

    open_player();
    mpv_command_string(h, "loadfile \"" MUX "\"");
    WAIT(get("ffmpeg-version"), 30);
    char mv[256] = "", fv[256] = "";
    if (get("mpv-version"))
        snprintf(mv, sizeof(mv), "%s", buf);
    if (get("ffmpeg-version"))
        snprintf(fv, sizeof(fv), "%s", buf);
    printf("engine: %s / FFmpeg %s\n", mv, fv);
    if (expect_mpv) {
        snprintf(cmd, sizeof(cmd), "mpv version contains %s", expect_mpv);
        check(strstr(mv, expect_mpv), cmd);
    }
    if (expect_ff) {
        snprintf(cmd, sizeof(cmd), "FFmpeg version contains %s", expect_ff);
        check(strstr(fv, expect_ff), cmd);
    }
    check(WAIT(num("time-pos", 0) > 1.0, 60), "MPEG-TS HLS plays (mux)");
    if (extended) {
        // decoder-list is JSON-ish: look for "codec":"<name>" (subtitle decoders aren't listed)
        const char *want[] = {"truehd", "mlp", "vc1"};
        for (int i = 0; i < 3; i++) {
            char needle[64], msg[64];
            snprintf(needle, sizeof(needle), "\"codec\":\"%s\"", want[i]);
            snprintf(msg, sizeof(msg), "decoder available: %s", want[i]);
            check(has("decoder-list", needle), msg);
        }
        check(mpv_command_string(h, "vf add bwdif") >= 0, "bwdif deinterlacer can be inserted (lavfi)");
    }
    close_player();

    open_player();
    mpv_command_string(h, "loadfile \"" SHAKA "\"");
    check(WAIT(num("duration", 0) > 0, 60), "HTTPS fMP4 HLS opens (shaka)");
    check(has("track-list", "\"type\":\"audio\""), "shaka has an audio track");
    mpv_command_string(h, "seek 30 absolute");
    bool landed = WAIT(num("time-pos", 0) > 30.3 && num("time-pos", 0) < 36, 30);
    char tp[64] = "";
    if (get("time-pos"))
        snprintf(tp, sizeof(tp), "%s", buf);
    printf("  after seek: time-pos=%s eof=%s\n", tp, get("eof-reached") ? buf : "(null)");
    check(landed, "fMP4 seek lands near the target (not EOF)");
    close_player();

    open_player();
    snprintf(cmd, sizeof(cmd), "loadfile \"%s\"", argv[2]);
    mpv_command_string(h, cmd);
    check(WAIT(num("time-pos", 0) > 1.0, 60), "PNG-disguised TS segments decode (anime downloads)");
    close_player();

    printf("ALL PASS\n");
    return 0;
}
