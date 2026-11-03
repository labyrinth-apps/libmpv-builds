#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$ndk_suffix
	exit 0
else
	exit 255
fi

mkdir -p _build$ndk_suffix
cd _build$ndk_suffix

../configure \
	CFLAGS="-O2 -fPIC" CXXFLAGS="-O2 -fPIC" \
	--host=$ndk_triple \
	--with-pic \
	--disable-asm \
	--enable-static \
	--disable-shared \
	--disable-fontconfig \
	--disable-libunibreak \
	--disable-require-system-font-provider

make -j$cores
make DESTDIR="$prefix_dir" install
