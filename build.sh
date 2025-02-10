#!/usr/bin/env arch -x86_64 bash
set -e

export WINE_MAIN_VERSION="10.x" # 10.0, 9.x, 9.0, 8.x, 8.0

export JOB_COUNT=12
# export JOB_COUNT=$(sysctl -n hw.logicalcpu)

export ROOT=$(pwd)
export BUILDROOT=$ROOT/build
export INSTALLROOT=$ROOT/install
export SOURCESROOT=$ROOT/sources

export WINE_VERSION="wine-10.1"
export WINE_MONO_VERSION="wine-mono-9.4.0"
export WINE_GECKO_VERSION="wine-gecko-2.47.4"

export WINESKIN_VERSION="WS12"

export BISON_PATH=$(brew --prefix bison)

export PATH="$BISON_PATH/bin:$(brew --prefix)/bin:/usr/bin:/bin"

export OPTFLAGS="-g -O2"
export CROSSCFLAGS="-Wno-incompatible-pointer-types"
export LDFLAGS="-Wl,-rpath,/usr/local/lib -Wl,-rpath,/opt/local/lib -L$BISON_PATH/lib"

echo "Download sources: wine"

export WINE_SOURCE_URL="https://dl.winehq.org/wine/source/$WINE_MAIN_VERSION/$WINE_VERSION.tar.xz"

if [[ ! -f $WINE_VERSION.tar.xz ]]; then
    echo "Download $WINE_VERSION.tar.xz"
    curl -o $WINE_VERSION.tar.xz $WINE_SOURCE_URL
fi

echo "Download binaries: wine-mono, wine-gecko"

export WINE_MONO_BINARY_x86_URL="https://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION#wine-mono-}/$WINE_MONO_VERSION-x86.tar.xz"
export WINE_GECKO_BINARY_x86_URL="https://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION#wine-gecko-}/$WINE_GECKO_VERSION-x86.tar.xz"
export WINE_GECKO_BINARY_x86_64_URL="https://dl.winehq.org/wine/wine-gecko/${WINE_GECKO_VERSION#wine-gecko-}/$WINE_GECKO_VERSION-x86_64.tar.xz"

if [[ ! -f $WINE_MONO_VERSION-x86.tar.xz ]]; then
    echo "Download $WINE_MONO_VERSION-x86.tar.xz"
    curl -o $WINE_MONO_VERSION-x86.tar.xz $WINE_MONO_BINARY_x86_URL
fi

if [[ ! -f $WINE_GECKO_VERSION-x86.tar.xz ]]; then
    echo "Download $WINE_GECKO_VERSION-x86.tar.xz"
    curl -o $WINE_GECKO_VERSION-x86.tar.xz $WINE_GECKO_BINARY_x86_URL
fi

if [[ ! -f $WINE_GECKO_VERSION-x86_64.tar.xz ]]; then
    echo "Download $WINE_GECKO_VERSION-x86_64.tar.xz"
    curl -o $WINE_GECKO_VERSION-x86_64.tar.xz $WINE_GECKO_BINARY_x86_64_URL
fi

mkdir -p $SOURCESROOT

if [[ -d "$SOURCESROOT/$WINE_VERSION" ]]; then
    rm -rf $SOURCESROOT/$WINE_VERSION
fi

echo "Extract $WINE_VERSION"
pushd $SOURCESROOT
tar xf $ROOT/$WINE_VERSION.tar.xz
popd

pushd $SOURCESROOT/$WINE_VERSION
git apply $ROOT/patches/0001-winemac.drv-no-flicker.patch
git apply $ROOT/patches/0002-macos-hacks.patch
git apply $ROOT/patches/0003-winemac.drv-export-essential-apis.patch
git apply $ROOT/patches/0004-winemac.drv-tiny-cursor-clip.patch
git apply $ROOT/patches/0005-add-msync.patch
git apply $ROOT/patches/0006-wined3d-moltenvk-hacks.patch
popd

export WINE_CONFIGURE=$SOURCESROOT/$WINE_VERSION/configure

export CC="ccache clang -arch x86_64"
export CXX="ccache clang++ -arch x86_64"
export i386_CC="ccache i686-w64-mingw32-gcc"
export x86_64_CC="ccache x86_64-w64-mingw32-gcc"

export ac_cv_lib_soname_vulkan=""

export GSTREAMER_CFLAGS=$(/Library/Frameworks/GStreamer.framework/Commands/pkg-config --cflags gstreamer-1.0 gstreamer-video-1.0 gstreamer-audio-1.0 gstreamer-tag-1.0)
export GSTREAMER_LIBS=$(/Library/Frameworks/GStreamer.framework/Commands/pkg-config --libs gstreamer-1.0 gstreamer-video-1.0 gstreamer-audio-1.0 gstreamer-tag-1.0)
export FFMPEG_CFLAGS=$(/Library/Frameworks/GStreamer.framework/Commands/pkg-config --cflags libavutil libavformat libavcodec)
export FFMPEG_LIBS=$(/Library/Frameworks/GStreamer.framework/Commands/pkg-config --libs libavutil libavformat libavcodec)

if [[ -d "$BUILDROOT" ]]; then
    rm -rf "$BUILDROOT"
fi

echo "Configure $WINE_VERSION"
mkdir -p $BUILDROOT/$WINE_VERSION
pushd $BUILDROOT/$WINE_VERSION
$WINE_CONFIGURE \
    --prefix= \
    --disable-tests \
    --enable-win64 \
    --enable-archs=i386,x86_64 \
    --without-alsa \
    --without-capi \
    --with-coreaudio \
    --with-cups \
    --without-dbus \
    --without-fontconfig \
    --with-freetype \
    --with-gettext \
    --without-gettextpo \
    --without-gphoto \
    --with-gnutls \
    --without-gssapi \
    --with-gstreamer \
    --without-inotify \
    --without-krb5 \
    --with-mingw \
    --without-netapi \
    --with-opencl \
    --with-opengl \
    --without-oss \
    --with-pcap \
    --with-pcsclite \
    --with-pthread \
    --without-pulse \
    --without-sane \
    --with-sdl \
    --without-udev \
    --with-unwind \
    --without-usb \
    --without-v4l2 \
    --with-vulkan \
    --without-wayland \
    --without-x
popd

echo "Build $WINE_VERSION"
pushd $BUILDROOT/$WINE_VERSION
make -j$JOB_COUNT
popd

if [[ -d "$INSTALLROOT" ]]; then
    rm -rf $INSTALLROOT
fi

echo "Install $WINE_VERSION"
pushd $BUILDROOT/$WINE_VERSION
make install-lib DESTDIR="$INSTALLROOT/$WINE_VERSION" -j$JOB_COUNT
popd

echo "Extract $WINE_MONO_VERSION"
mkdir -p $INSTALLROOT/$WINE_VERSION/share/wine/mono
pushd $INSTALLROOT/$WINE_VERSION/share/wine/mono
tar xf $ROOT/$WINE_MONO_VERSION-x86.tar.xz
popd

echo "Extract $WINE_GECKO_VERSION"
mkdir -p $INSTALLROOT/$WINE_VERSION/share/wine/gecko
pushd $INSTALLROOT/$WINE_VERSION/share/wine/gecko
tar xf $ROOT/$WINE_GECKO_VERSION-x86.tar.xz
tar xf $ROOT/$WINE_GECKO_VERSION-x86_64.tar.xz
popd

export ENGINE_NAME="${WINESKIN_VERSION}Wine${WINE_VERSION#wine-}"

echo "Bundle into $ENGINE_NAME.tar.7z"
if [[ -f $ENGINE_NAME.tar.7z ]]; then
    rm $ENGINE_NAME.tar.7z
fi
cp -a $INSTALLROOT/$WINE_VERSION wswine.bundle
echo $WINE_VERSION > wswine.bundle/version
tar cf $ENGINE_NAME.tar wswine.bundle
7z a $ENGINE_NAME.tar.7z $ENGINE_NAME.tar

rm $ENGINE_NAME.tar
rm -rf wswine.bundle

