# libplacebo is required by mpv >= 0.37. Built as a static, OpenGL-only
# library so it links into libmpv and the framework set stays unchanged.
{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
}:

let
  name = "libplacebo";
  locks = import ../../../packages.lock.nix;
  packageLock = locks.${name};
  inherit (packageLock) version;

  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch; };
  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };

  # glad (GL loader generator) needs jinja2 at build time
  python = pkgs.python3.withPackages (ps: [
    ps.jinja2
    ps.markupsafe
  ]);
  nativeBuildInputs = [
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
    python
  ];

  pname = import ../../utils/name/package.nix name;
  src = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-source-${version}";
    inherit (packageLock) url sha256;
  };
  # GitHub tarballs omit submodules: fetch the pinned ones separately
  glad = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-glad-source-${locks.glad.version}";
    inherit (locks.glad) url sha256;
  };
  fastFloat = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-fast-float-source-${locks.fast_float.version}";
    inherit (locks.fast_float) url sha256;
  };
  patchedSource = pkgs.runCommand "${pname}-patched-source-${version}" { } ''
    cp -r ${src} src
    chmod -R 777 src
    rm -rf src/3rdparty/glad src/3rdparty/fast_float
    cp -r ${glad} src/3rdparty/glad
    cp -r ${fastFloat} src/3rdparty/fast_float
    cp -r src $out
  '';
  fixedSource = callPackage ../../utils/patch-shebangs/default.nix {
    name = "${pname}-fixed-source-${version}";
    src = patchedSource;
    inherit nativeBuildInputs;
  };
in

pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${version}";
  pname = pname;
  inherit version;
  src = fixedSource;
  dontUnpack = true;
  enableParallelBuilding = true;
  inherit nativeBuildInputs;
  # meson runs libplacebo's generators with its own interpreter, not the
  # python on PATH, so point it at jinja2 explicitly.
  PYTHONPATH = "${python}/${python.sitePackages}";
  configurePhase = ''
    meson setup build $src \
      --native-file ${nativeFile} \
      --cross-file ${crossFile} \
      --prefix=$out \
      --buildtype=release \
      --default-library=static \
      -Dauto_features=disabled \
      -Dopengl=enabled \
      -Dgl-proc-addr=disabled \
      -Dvulkan=disabled \
      -Dvk-proc-addr=disabled \
      -Dd3d11=disabled \
      -Dglslang=disabled \
      -Dshaderc=disabled \
      -Dlcms=disabled \
      -Ddovi=disabled \
      -Dlibdovi=disabled \
      -Dunwind=disabled \
      -Dxxhash=disabled \
      -Ddemos=false \
      -Dtests=false \
      -Dbench=false \
      -Dfuzz=false
  '';
  buildPhase = ''
    meson compile -vC build
  '';
  installPhase = ''
    meson install -C build

    # libmpv is a C project: linking this static C++ (convert.cc) lib into it
    # needs libc++, which pkg-config only lists in Libs.private.
    sed -i 's|^Libs: \(.*\)$|Libs: \1 -lc++|' $out/lib/pkgconfig/libplacebo.pc
    cat $out/lib/pkgconfig/libplacebo.pc
  '';
}
