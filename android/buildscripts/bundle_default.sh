#!/bin/bash
# Builds the LGPL "default" flavour for one ABI and packages it like upstream v1.1.7:
#   artifacts/default-<abi>.jar = lib/<abi>/libmediakitandroidhelper.so + lib/<abi>/libmpv.so
# Usage: bundle_default.sh <armv7l|arm64|x86|x86_64>
set -euxo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
arch=${1:?arch}

case "$arch" in
	armv7l) abi=armeabi-v7a ndk_suffix= ;;
	arm64) abi=arm64-v8a ndk_suffix=-arm64 ;;
	x86) abi=x86 ndk_suffix=-x86 ;;
	x86_64) abi=x86_64 ndk_suffix=-x64 ;;
	*) echo "bad arch $arch" >&2; exit 1 ;;
esac

rm -rf deps prefix artifacts
./download.sh
./patch.sh
./build.sh --arch "$arch" mpv

. ./include/depinfo.sh
ndk="$PWD/sdk/android-sdk-linux/ndk/$v_ndk"
bin="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin"
cores=$(nproc)

# libmediakitandroidhelper.so: upstream builds it through the helper app's Gradle
# (CMake, c++_static, release); same sources, built directly with CMake here.
cmake -S deps/media-kit-android-helper/app/src/main/cpp -B "deps/helper-build-$abi" -G Ninja \
	-DCMAKE_TOOLCHAIN_FILE="$ndk/build/cmake/android.toolchain.cmake" \
	-DANDROID_ABI="$abi" -DANDROID_PLATFORM="android-$v_api" -DANDROID_STL=c++_static \
	-DCMAKE_BUILD_TYPE=Release
ninja -C "deps/helper-build-$abi" -j"$cores"

stage="artifacts/stage/lib/$abi"
mkdir -p "$stage" artifacts/debug
cp prefix/$abi/lib/libmpv.so "artifacts/debug/libmpv-$abi.so"
"$bin/llvm-strip" --strip-all -o "$stage/libmpv.so" prefix/$abi/lib/libmpv.so
"$bin/llvm-strip" --strip-all -o "$stage/libmediakitandroidhelper.so" \
	"deps/helper-build-$abi/libmediakitandroidhelper.so"

(cd artifacts/stage && zip -X "../default-$abi.jar" "lib/$abi/libmediakitandroidhelper.so" "lib/$abi/libmpv.so")
(cd artifacts && md5sum "default-$abi.jar" | cut -d' ' -f1 > "default-$abi.jar.md5" && cat "default-$abi.jar.md5")

# Licence/features gate inputs
lic="artifacts/licence/$abi"
mkdir -p "$lic/ffmpeg" "$lic/mpv"
fb="deps/ffmpeg/_build$ndk_suffix"
cp "$fb/config.h" "$fb/config_components.h" "$lic/ffmpeg/"
cp "$fb/ffbuild/config.mak" "$lic/ffmpeg/"
cp "deps/mpv/_build$ndk_suffix/config.h" "$lic/mpv/"
cp deps/mpv/configure.log "$lic/mpv/" || true
