# Every source tarball is pinned by version + sha256 of the (non-extracted)
# tarball. See nix/utils/fetch-tarball/default.nix.
{
  dav1d = {
    version = "1.5.4";
    url = "https://code.videolan.org/videolan/dav1d/-/archive/1.5.4/dav1d-1.5.4.tar.bz2";
    sha256 = "2abfb0c89212e6e4733a54e0ae509ec00a5b845a6360946f918806e14aedb011";
  };
  fast_float = {
    # libplacebo v7.360.1 3rdparty/fast_float submodule commit
    version = "97b54ca9";
    url = "https://github.com/fastfloat/fast_float/archive/97b54ca9e75f5303507699d27c6b4f4efe4641a1.tar.gz";
    sha256 = "2b132274539286e41f37857cac22aa8441d21bd86d55de825a3342b149f66801";
  };
  ffmpeg = {
    version = "8.1.3";
    url = "https://ffmpeg.org/releases/ffmpeg-8.1.3.tar.xz";
    sha256 = "7138d28c96d9d3e3af4ee3d8cad72741f8ffb40da90c1112235dea3ecd3178a3";
  };
  freetype = {
    version = "2.14.3";
    url = "https://downloads.sourceforge.net/project/freetype/freetype2/2.14.3/freetype-2.14.3.tar.xz";
    sha256 = "36bc4f1cc413335368ee656c42afca65c5a3987e8768cc28cf11ba775e785a5f";
  };
  fribidi = {
    version = "1.0.18";
    url = "https://github.com/fribidi/fribidi/releases/download/v1.0.18/fribidi-1.0.18.tar.xz";
    sha256 = "1de5e8073d035388b71d0b2d452b1da1f8caeea8a7702997b401fe1b6250727f";
  };
  glad = {
    # libplacebo v7.360.1 3rdparty/glad submodule commit
    version = "73db193f";
    url = "https://github.com/Dav1dde/glad/archive/73db193f853e2ee079bf3ca8a64aa2eaf6459043.tar.gz";
    sha256 = "33dbeae44d8315ece57e14eba4b1b4a02ac5406d1c4f49cd20048c91522a6b9a";
  };
  harfbuzz = {
    version = "14.6.0";
    url = "https://github.com/harfbuzz/harfbuzz/releases/download/14.6.0/harfbuzz-14.6.0.tar.xz";
    sha256 = "d07a007327277708a2a73ae437887cdbaf282937f6d03ca5467723e9099af586";
  };
  libass = {
    version = "0.17.5";
    url = "https://github.com/libass/libass/releases/download/0.17.5/libass-0.17.5.tar.xz";
    sha256 = "2dca25c0e0c837ddf00b52011b3f82cac1e4ddd3ad018227806b0c2288864acc";
  };
  libplacebo = {
    version = "7.360.1";
    url = "https://github.com/haasn/libplacebo/archive/refs/tags/v7.360.1.tar.gz";
    sha256 = "d05fdf90bea2f629eaa2d115e909fd356388ac639e54f77b87a018a6d76224bd";
  };
  libpng = {
    version = "1.6.59";
    url = "https://github.com/pnggroup/libpng/archive/v1.6.59.tar.gz";
    sha256 = "2540302a1844ad2b2b501977abecfa850f265f97b78f065a712ab4074a89f5b5";
  };
  libpngPatch = {
    version = "1.6.59-1";
    url = "https://wrapdb.mesonbuild.com/v2/libpng_1.6.59-1/get_patch";
    sha256 = "d20d5e20516a550817026b0074c4051ff4342da43f0600827316ea85f89d1d38";
  };
  libxml2 = {
    version = "2.15.4";
    url = "https://download.gnome.org/sources/libxml2/2.15/libxml2-2.15.4.tar.xz";
    sha256 = "98087fd181d9070724f3fbc65c7377db03038eb92bd882374daff44940138821";
  };
  mbedtls = {
    # 3.6.x LTS: mbedtls 4.x removed APIs FFmpeg's tls_mbedtls.c uses.
    # Release tarball (includes the framework/ submodule; GitHub archives do not).
    version = "3.6.7";
    url = "https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.7/mbedtls-3.6.7.tar.bz2";
    sha256 = "a7e8bcbec0e6f761b4af24f25677626b35f762f68eef79c08677a363212d11f6";
  };
  mpv = {
    version = "0.41.0";
    url = "https://github.com/mpv-player/mpv/archive/refs/tags/v0.41.0.tar.gz";
    sha256 = "ee21092a5ee427353392360929dc64645c54479aefdb5babc5cfbb5fad626209";
  };
  uchardet = {
    version = "0.0.8";
    url = "https://www.freedesktop.org/software/uchardet/releases/uchardet-0.0.8.tar.xz";
    sha256 = "e97a60cfc00a1c147a674b097bb1422abd9fa78a2d9ce3f3fdcc2e78a34ac5f0";
  };
}
