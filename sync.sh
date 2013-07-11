#!/bin/sh

set -e

source config.sh

SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
DIST_DIR_BASE=${DIST_DIR_BASE:="$SCRIPT_DIR/dist"}

git submodule update --init opus
cd opus
git checkout master
git pull 
cd ..

for ARCH in $ARCHS
do
    OPUS_DIR=opus-$ARCH
    echo "Syncing source for $ARCH to directory $OPUS_DIR"
    rsync opus/ $OPUS_DIR/ --exclude '.*' -a --delete
done
