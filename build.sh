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
    BUILD_DIR=build/$ARCH
    mkdir -p $BUILD_DIR
    echo "Syncing source for $ARCH to directory $BUILD_DIR"
    rsync opus/ $BUILD_DIR/ --exclude '.*' -a --delete
    if [ ! -d $BUILD_DIR ]
    then
      echo "Directory $BUILD_DIR does not exist"
      exit 1
    fi
    echo "Compiling source for $ARCH in directory $BUILD_DIR"

    cd $BUILD_DIR

    DIST_DIR=$DIST_DIR_BASE/$ARCH
    mkdir -p $DIST_DIR

    case $ARCH in
        armv7)
            EXTRA_FLAGS="--with-pic"
            EXTRA_CFLAGS="-mcpu=cortex-a8 -mfpu=neon -miphoneos-version-min=${DEPLOYMENT_TARGET}"
            PLATFORM="${PLATFORMBASE}/iPhoneOS.platform"
            IOSSDK=iPhoneOS${IOSSDK_VER}
            ;;
        armv7s)
            EXTRA_FLAGS="--with-pic"
            EXTRA_CFLAGS="-mcpu=cortex-a9 -mfpu=neon -miphoneos-version-min=${DEPLOYMENT_TARGET}"
            PLATFORM="${PLATFORMBASE}/iPhoneOS.platform"
            IOSSDK=iPhoneOS${IOSSDK_VER}
            ;;
        i386)
            EXTRA_FLAGS="--with-pic"
            EXTRA_CFLAGS=""
            EXTRA_LDFLAGS="-mios-simulator-version-min=${DEPLOYMENT_TARGET}"
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
		-L${PLATFORM}/Developer/SDKs/${IOSSDK}.sdk/usr/lib \
                ${EXTRA_LDFLAGS}"
	
    export CFLAGS
    export LDFLAGS
	
    export TOOLCHAIN_BASE=$(xcode-select -print-path)"/Toolchains/XcodeDefault.xctoolchain"
    export PROGRAMS="$TOOLCHAIN_BASE/usr/bin"
    export CXXCPP="$PROGRAMS/cpp"
    export CPP="$CXXCPP"
    export CXX="$PROGRAMS/c++"
    export CC="$PROGRAMS/cc"
    export LD="$PROGRAMS/ld"
    export AR="$PROGRAMS/ar"
    export AS="$PROGRAMS/as"
    export NM="$PROGRAMS/nm"
    export RANLIB="$PROGRAMS/ranlib"
    export STRIP="$PROGRAMS/strip"
	
    ./configure \
    	--prefix=$DIST_DIR \
		--host=${ARCH}-apple-darwin \
		--with-sysroot=${PLATFORM}/Developer/SDKs/${IOSSDK}.sdk \
		--enable-static=yes \
		--enable-shared=no \
	    --disable-extra-programs \
	    --disable-doc \
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
