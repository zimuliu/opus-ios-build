#!/bin/bash

set -e

source config.sh

SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
DIST_DIR_BASE=${DIST_DIR_BASE:="$SCRIPT_DIR/dist"}

for ARCH in $ARCHS
do
  if [ -d $DIST_DIR_BASE/$ARCH ]
  then
    MAIN_ARCH=$ARCH
  fi
done

if [ -z "$MAIN_ARCH" ]
then
  echo "Please compile an architecture"
  exit 1
fi


OUTPUT_DIR="dist/all"
rm -rf $OUTPUT_DIR

mkdir -p $OUTPUT_DIR/lib $OUTPUT_DIR/include

for LIB in $DIST_DIR_BASE/*/lib/*.a
do
  LIB=`basename $LIB`
  LIPO_CREATE=""
  for ARCH in $ARCHS
  do
    if [ -d $DIST_DIR_BASE/$ARCH ]
    then
      LIPO_CREATE="$LIPO_CREATE-arch $ARCH $DIST_DIR_BASE/$ARCH/lib/$LIB "
    fi
  done
  OUTPUT="$OUTPUT_DIR/lib/$LIB"
  echo "Creating: $OUTPUT"
  xcrun -sdk iphoneos lipo -create $LIPO_CREATE -output $OUTPUT
  xcrun -sdk iphoneos lipo -info $OUTPUT
done

echo "Copying headers from $DIST_DIR_BASE/$MAIN_ARCH..."
cp -R $DIST_DIR_BASE/$MAIN_ARCH/include/* $OUTPUT_DIR/include
