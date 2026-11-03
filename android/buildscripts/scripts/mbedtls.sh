#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	make clean
	exit 0
else
	exit 255
fi

$0 clean # separate building not supported, always clean

# i686: AES-NI intrinsics need SSE flags the NDK's x86 target doesn't enable by default
cp include/mbedtls/mbedtls_config.h.orig include/mbedtls/mbedtls_config.h 2>/dev/null ||
	cp include/mbedtls/mbedtls_config.h include/mbedtls/mbedtls_config.h.orig
if [[ "$ndk_triple" == "i686"* ]]; then
	python3 scripts/config.py unset MBEDTLS_AESNI_C
fi

make CFLAGS="-O2 -fPIC" -j$cores no_test
make CFLAGS="-O2 -fPIC" DESTDIR="$prefix_dir" install
