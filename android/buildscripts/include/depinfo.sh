#!/bin/bash -e

## Toolchain

# NDK r27d (current LTS), pinned. Installed with sdkmanager into the runner's SDK.
v_ndk=27.3.13750724
# Lowest Android API the libraries are compiled for (upstream: 21; app floor: 24).
v_api=21

## Dependency versions (same pins as darwin/packages.lock.nix)
# Each entry: version, URL, sha256 of the downloaded tarball.

v_mpv=0.42.0
u_mpv=https://github.com/mpv-player/mpv/archive/refs/tags/v0.42.0.tar.gz
s_mpv=bcfebbfa2b65a6d88dc97ea18117831072373e38b5785a2afb874ed4df5070dd

v_ffmpeg=9.1
u_ffmpeg=https://ffmpeg.org/releases/ffmpeg-9.1.tar.xz
s_ffmpeg=1a4d394ae63d190a526cd052eb4415c156b5c5e2df37efab41a7de0b8fde2433

# 3.6.x LTS: mbedtls 4.x removed APIs FFmpeg's tls_mbedtls.c uses.
# Release tarball (includes the framework/ submodule; GitHub archives do not).
v_mbedtls=3.6.8
u_mbedtls=https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.8/mbedtls-3.6.8.tar.bz2
s_mbedtls=bc54b818e87f49c0b3281dd85d24adaede0e63b4e822e3fbd49c005a38b9595b

v_dav1d=1.5.5
u_dav1d=https://code.videolan.org/videolan/dav1d/-/archive/1.5.5/dav1d-1.5.5.tar.bz2
s_dav1d=afc5378daba30eafd11d7b4f0ec863270d7b175f38393a2e1e0ff76f3a45c8b9

v_libxml2=2.15.4
u_libxml2=https://download.gnome.org/sources/libxml2/2.15/libxml2-2.15.4.tar.xz
s_libxml2=98087fd181d9070724f3fbc65c7377db03038eb92bd882374daff44940138821

v_freetype=2.14.3
u_freetype=https://downloads.sourceforge.net/project/freetype/freetype2/2.14.3/freetype-2.14.3.tar.xz
s_freetype=36bc4f1cc413335368ee656c42afca65c5a3987e8768cc28cf11ba775e785a5f

v_fribidi=1.0.18
u_fribidi=https://github.com/fribidi/fribidi/releases/download/v1.0.18/fribidi-1.0.18.tar.xz
s_fribidi=1de5e8073d035388b71d0b2d452b1da1f8caeea8a7702997b401fe1b6250727f

v_harfbuzz=14.6.0
u_harfbuzz=https://github.com/harfbuzz/harfbuzz/releases/download/14.6.0/harfbuzz-14.6.0.tar.xz
s_harfbuzz=d07a007327277708a2a73ae437887cdbaf282937f6d03ca5467723e9099af586

v_libass=0.17.5
u_libass=https://github.com/libass/libass/releases/download/0.17.5/libass-0.17.5.tar.xz
s_libass=2dca25c0e0c837ddf00b52011b3f82cac1e4ddd3ad018227806b0c2288864acc

# libplacebo is required since mpv 0.37 (>= 7.387 for 0.42); built static (OpenGL only) into libmpv.
v_libplacebo=7.387.0
u_libplacebo=https://github.com/haasn/libplacebo/archive/refs/tags/v7.387.0.tar.gz
s_libplacebo=f9e62d3774a9c4cfd198ec3abaa88294aaade2e31c04d5ab02bcf4abc98b1df5
# GitHub tarballs omit submodules: libplacebo v7.387.0's 3rdparty/{glad,fast_float} commits
u_glad=https://github.com/Dav1dde/glad/archive/73db193f853e2ee079bf3ca8a64aa2eaf6459043.tar.gz
s_glad=33dbeae44d8315ece57e14eba4b1b4a02ac5406d1c4f49cd20048c91522a6b9a
u_fast_float=https://github.com/fastfloat/fast_float/archive/97b54ca9e75f5303507699d27c6b4f4efe4641a1.tar.gz
s_fast_float=2b132274539286e41f37857cac22aa8441d21bd86d55de825a3342b149f66801

# media-kit-android-helper (libmediakitandroidhelper.so), same commit as upstream v1.1.7..v1.1.11
v_helper=42054e5d479f39ccbb0ae604862e2bcaf59b74c2


## Dependency tree

dep_mbedtls=()
dep_dav1d=()
dep_libxml2=()
dep_ffmpeg=(mbedtls dav1d libxml2)
dep_freetype=()
dep_fribidi=()
dep_harfbuzz=()
dep_libass=(freetype fribidi harfbuzz)
dep_libplacebo=()
dep_mpv=(ffmpeg libass libplacebo)
