#!/bin/bash

set -e

source config.sh

# Number of CPUs (for make -j)
NCPU=`sysctl -n hw.ncpu`
if test x$NJOB = x; then
    NJOB=$NCPU
fi

PLATFORMBASE=$(xcode-select -print-path)"/Platforms"

SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
DIST_DIR_BASE=${DIST_DIR_BASE:="$SCRIPT_DIR/dist"}

if [ ! -d opus ]
then
  echo "opus source directory does not exist, run sync.sh"
fi

# PATH=${SCRIPT_DIR}/gas-preprocessor/:$PATH

for ARCH in $ARCHS
do
    OPUS_DIR=opus-$ARCH
    if [ ! -d $OPUS_DIR ]
    then
      echo "Directory $OPUS_DIR does not exist, run sync.sh"
      exit 1
    fi
    echo "Compiling source for $ARCH in directory $OPUS_DIR"

    cd $OPUS_DIR

    DIST_DIR=$DIST_DIR_BASE-$ARCH
    mkdir -p $DIST_DIR

    case $ARCH in
        armv6)
            EXTRA_FLAGS="--with-pic=no"
            EXTRA_CFLAGS="-mcpu=arm1176jzf-s"
            PLATFORM="${PLATFORMBASE}/iPhoneOS.platform"
            IOSSDK=iPhoneOS${IOSSDK_VER}
            ;;
        armv7)
            EXTRA_FLAGS="--with-pic"
            EXTRA_CFLAGS="-mcpu=cortex-a8 -mfpu=neon"
            PLATFORM="${PLATFORMBASE}/iPhoneOS.platform"
            IOSSDK=iPhoneOS${IOSSDK_VER}
            ;;
        armv7s)
            EXTRA_FLAGS="--with-pic"
            EXTRA_CFLAGS="-mcpu=cortex-a9 -mfpu=neon -miphoneos-version-min=6.0"
            PLATFORM="${PLATFORMBASE}/iPhoneOS.platform"
            IOSSDK=iPhoneOS${IOSSDK_VER}
            ;;
        i386)
            EXTRA_FLAGS="--with-pic"
            EXTRA_CFLAGS=""
            PLATFORM="${PLATFORMBASE}/iPhoneSimulator.platform"
            IOSSDK=iPhoneSimulator${IOSSDK_VER}
            ;;
        *)
            echo "Unsupported architecture ${ARCH}"
            exit 1
            ;;
    esac

    echo "Configuring opus for $ARCH..."
	
	./autogen.sh
	
	CFLAGS="-g -O2 -pipe -arch ${ARCH} \
		-isysroot ${PLATFORM}/Developer/SDKs/${IOSSDK}.sdk \
		-I${PLATFORM}/Developer/SDKs/${IOSSDK}.sdk/usr/include \
		${EXTRA_CFLAGS}"
    LDFLAGS="-arch ${ARCH} \
		-isysroot ${PLATFORM}/Developer/SDKs/${IOSSDK}.sdk \
		-L${PLATFORM}/Developer/SDKs/${IOSSDK}.sdk/usr/lib"
	
	export CFLAGS
	export LDFLAGS
	
    export CXXCPP="$PLATFORM/Developer/usr/bin/llvm-cpp-4.2"
    export CPP="$CXXCPP"
    export CXX="$PLATFORM/Developer/usr/bin/llvm-g++"
    export CC="$PLATFORM/Developer/usr/bin/llvm-gcc"
    export LD="$PLATFORM/Developer/usr/bin/ld"
    export AR="$PLATFORM/Developer/usr/bin/ar"
    export AS="$PLATFORM/Developer/usr/bin/ls"
    export NM="$PLATFORM/Developer/usr/bin/nm"
    export RANLIB="$PLATFORM/Developer/usr/bin/ranlib"
    export STRIP="$PLATFORM/Developer/usr/bin/strip"
	
    ./configure \
    	--prefix=$DIST_DIR \
		--host=${ARCH}-apple-darwin \
		--with-sysroot=${PLATFORM}/Developer/SDKs/${IOSSDK}.sdk \
		--enable-static=yes \
		--enable-shared=no \
	    --disable-doc \
		--disable-rtcd \
		${EXTRA_FLAGS}

    echo "Installing opus for $ARCH..."
    make clean
    make -j$NJOB V=1
    make install

    cd $SCRIPT_DIR

    if [ -d $DIST_DIR/bin ]
    then
      rm -rf $DIST_DIR/bin
    fi
    if [ -d $DIST_DIR/share ]
    then
      rm -rf $DIST_DIR/share
    fi
done
