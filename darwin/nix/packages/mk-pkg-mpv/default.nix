{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
  variant ? import ../../utils/default/variant.nix,
}:

let
  name = "mpv";
  packageLock = (import ../../../packages.lock.nix).${name};
  inherit (packageLock) version;

  oses = import ../../utils/constants/oses.nix;
  callPackage = pkgs.lib.callPackageWith {
    inherit
      pkgs
      os
      arch
      variant
      ;
  };
  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };
  xctoolchainLipo = callPackage ../../utils/xctoolchain/lipo.nix { };
  ffmpeg = callPackage ../mk-pkg-ffmpeg/default.nix { };
  uchardet = callPackage ../mk-pkg-uchardet/default.nix { };
  libass = callPackage ../mk-pkg-libass/default.nix { };
  libplacebo = callPackage ../mk-pkg-libplacebo/default.nix { };

  nativeBuildInputs = [
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
    pkgs.python3
    xctoolchainLipo
  ];

  pname = import ../../utils/name/package.nix name;
  src = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-source-${version}";
    inherit (packageLock) url sha256;
  };
  patchedSource = pkgs.runCommand "${pname}-patched-source-${variant}-${version}" { } ''
    cp -r ${src} src
    export src=$PWD/src
    chmod -R 777 $src

    cd $src
    patch -p1 <${../../../patches/mpv-fix-missing-objc.patch}
    patch -p1 <${../../../patches/mpv-fix-cocoa-without-swift.patch}
    patch -p1 <${../../../patches/mpv-fix-apple-framework-links.patch}
    patch -p1 <${../../../patches/mpv-fix-mac-client-without-swift.patch}
    patch -p1 <${../../../patches/mpv-audiounit-shared-session.patch}
    patch -p1 <${../../../patches/mpv-fix-coreaudio-macos27.patch}
    cd -

    cp -r $src $out
  '';
  fixedSource = callPackage ../../utils/patch-shebangs/default.nix {
    name = "${pname}-fixed-source-${variant}-${version}";
    src = patchedSource;
    inherit nativeBuildInputs;
  };
in

pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${variant}-${version}";
  pname = pname;
  inherit version;
  src = fixedSource;
  dontUnpack = true;
  enableParallelBuilding = true;
  inherit nativeBuildInputs;
  # libass and libplacebo are mandatory since mpv 0.37; libplacebo is static
  # and ends up inside libmpv (no extra framework).
  buildInputs = [
    ffmpeg
    uchardet
    libass
    libplacebo
  ];
  configurePhase = ''
    # Start from nothing and enable only what media_kit needs.
    OPTIONS=(
      -Dauto_features=disabled
      -Db_lundef=true `# fail on unresolved symbols instead of -undefined dynamic_lookup`

      `# booleans (not covered by auto_features)`
      -Dgpl=false `# LGPL build`
      -Dcplayer=false `# mpv CLI player`
      -Dlibmpv=true `# libmpv library`
      -Dbuild-date=true `# include compile timestamp in binary`
      -Dtests=false `# meson unit tests`
      -Dfuzzers=false `# fuzzer binaries`

      `# misc features`
      -Diconv=enabled `# iconv`
      -Duchardet=enabled `# uchardet support`
      -Dzlib=enabled `# zlib`

      `# video output features`
      -Dgl=enabled `# OpenGL context support`
      -Dplain-gl=enabled `# OpenGL without platform-specific code (libmpv render API)`
    )

    MACOS_OPTIONS=(
      -Dcocoa=enabled `# Cocoa (required by gl-cocoa)`
      -Dcoreaudio=enabled `# CoreAudio audio output`
      -Dgl-cocoa=enabled `# gl-cocoa`
      -Dvideotoolbox-gl=enabled `# VideoToolbox with OpenGL`
    )

    IOS_OPTIONS=(
      -Daudiounit=enabled `# AudioUnit output for iOS`
      -Dios-gl=enabled `# iOS OpenGL ES hardware decoding interop (VideoToolbox)`
    )

    if [ "${os}" == "${oses.macos}" ]; then
      OPTIONS+=("''${MACOS_OPTIONS[@]}")
    else
      OPTIONS+=("''${IOS_OPTIONS[@]}")
    fi

    meson setup build $src \
      --native-file ${nativeFile} \
      --cross-file ${crossFile} \
      --prefix=$out \
      "''${OPTIONS[@]}" |
      tee configure.log
  '';
  buildPhase = ''
    meson compile -vC build
  '';
  installPhase = ''
    meson install -C build

    # copy configure.log, and config.h for the licence gate
    mkdir -p $out/share/mpv
    cp configure.log $out/share/mpv/
    cp build/config.h $out/share/mpv/config.h
  '';
}
