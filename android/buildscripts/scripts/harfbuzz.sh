#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

build=_build$ndk_suffix

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf $build
	exit 0
else
	exit 255
fi

unset CC CXX # meson wants these unset

# harfbuzz >= 11 also builds raster/vector/gpu/subset libraries: off
meson setup $build --cross-file "$prefix_dir"/crossfile.txt \
	-Dauto_features=disabled \
	-D{raster,vector,gpu,subset,utilities,tests,docs}=disabled

ninja -C $build -j$cores
DESTDIR="$prefix_dir" ninja -C $build install
