#!/bin/bash -e
# Installs the pinned NDK into the Android SDK at sdk/android-sdk-linux
# (on CI a symlink to the runner's $ANDROID_HOME). Build tools (meson, ninja,
# nasm, autotools, pkg-config, python3 + jinja2) are installed by the workflow.

. ./include/depinfo.sh

sdk="$PWD/sdk/android-sdk-linux"
if [ ! -d "$sdk" ]; then
	echo "Error: $sdk missing (symlink it to an Android SDK)." >&2
	exit 255
fi
if [ ! -d "$sdk/ndk/$v_ndk" ]; then
	exe="$sdk/cmdline-tools/latest/bin/sdkmanager"
	yes | "$exe" --sdk_root="$sdk" "ndk;$v_ndk" >/dev/null
fi
test -x "$sdk/ndk/$v_ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
grep -h "Pkg.Revision" "$sdk/ndk/$v_ndk/source.properties"
