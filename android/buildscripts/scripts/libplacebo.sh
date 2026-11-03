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

# Static, OpenGL (ES) only: links into libmpv.so, so the jar keeps the same two .so files.
meson setup $build --cross-file "$prefix_dir"/crossfile.txt \
	-Dauto_features=disabled \
	-Dopengl=enabled \
	-Dgl-proc-addr=disabled \
	-D{vulkan,vk-proc-addr,d3d11,glslang,shaderc,lcms,dovi,libdovi,unwind,xxhash}=disabled \
	-D{demos,tests,bench,fuzz}=false

ninja -C $build -j$cores
DESTDIR="$prefix_dir" ninja -C $build install

# libplacebo has C++ (convert.cc); libmpv links with the C driver. Link the
# *static* libc++ (plain -lc++ would resolve to libc++_shared.so, which the jar doesn't ship).
${SED:-sed} -i '/^Libs:/ s|$| -l:libc++_static.a -l:libc++abi.a|' "$prefix_dir/lib/pkgconfig/libplacebo.pc"
cat "$prefix_dir/lib/pkgconfig/libplacebo.pc"
