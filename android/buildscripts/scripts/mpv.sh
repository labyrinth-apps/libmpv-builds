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

set -o pipefail
unset CC CXX # meson wants these unset

# Start from nothing; enable what upstream's default flavour auto-detected
# (android-media-ndk cplugins egl-android gl opensles vector zlib) plus audiotrack
# (always built in 0.36, a feature since). iconv is API 28+, aaudio API 26+: off.
meson setup $build --cross-file "$prefix_dir"/crossfile.txt \
	--prefer-static \
	--default-library shared \
	-Dauto_features=disabled \
	-Dgpl=false \
	-Dlibmpv=true \
	-Dcplayer=false \
	-Dtests=false \
	-Dfuzzers=false \
	-Dbuild-date=true \
	-D{android-media-ndk,audiotrack,opensles,egl-android,gl,cplugins,vector,zlib}=enabled \
	2>&1 | tee configure.log

ninja -C $build -j$cores
DESTDIR="$prefix_dir" ninja -C $build install
