#!/bin/bash -e
# Downloads every source tarball pinned in depinfo.sh and checks its sha256.

. ./include/depinfo.sh

mkdir -p deps dl

fetch () { # fetch <name> <url> <sha256> -> deps/<name>
	local name=$1 url=$2 sum=$3
	[ -d "deps/$name" ] && return 0
	local file="dl/$name.${url##*.}"
	[ -f "$file" ] || curl -fsSL --retry 5 --retry-all-errors -o "$file" "$url"
	echo "$sum  $file" | sha256sum -c -
	mkdir "deps/$name"
	tar -xf "$file" -C "deps/$name" --strip-components=1
}

fetch mbedtls "$u_mbedtls" "$s_mbedtls"
fetch dav1d "$u_dav1d" "$s_dav1d"
fetch libxml2 "$u_libxml2" "$s_libxml2"
fetch ffmpeg "$u_ffmpeg" "$s_ffmpeg"
fetch freetype "$u_freetype" "$s_freetype"
fetch fribidi "$u_fribidi" "$s_fribidi"
fetch harfbuzz "$u_harfbuzz" "$s_harfbuzz"
fetch libass "$u_libass" "$s_libass"
fetch mpv "$u_mpv" "$s_mpv"

if [ ! -d deps/libplacebo ]; then
	fetch libplacebo "$u_libplacebo" "$s_libplacebo"
	fetch glad "$u_glad" "$s_glad"
	fetch fast_float "$u_fast_float" "$s_fast_float"
	rm -rf deps/libplacebo/3rdparty/glad deps/libplacebo/3rdparty/fast_float
	mv deps/glad deps/libplacebo/3rdparty/glad
	mv deps/fast_float deps/libplacebo/3rdparty/fast_float
fi

# media-kit-android-helper, pinned by commit
if [ ! -d deps/media-kit-android-helper ]; then
	git init -q deps/media-kit-android-helper
	git -C deps/media-kit-android-helper fetch -q --depth 1 \
		https://github.com/media-kit/media-kit-android-helper.git "$v_helper"
	git -C deps/media-kit-android-helper checkout -q FETCH_HEAD
	[ "$(git -C deps/media-kit-android-helper rev-parse HEAD)" == "$v_helper" ]
fi
