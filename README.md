# opus-ios-build

Build opus codec for iOS

## USAGE

Run ./sync.sh, ./build.sh and ./combine.sh as appropriate. It is probably
needed to change some variables in ./config.sh.

To find out which SDKs are supported run:
xcodebuild -showsdks

To switch which XCode Installation is used, run
sudo xcode-select -switch $XCODEROOT

## CREDITS

Part of code is based on https://github.com/zimuliu/ffmpeg-ios-build


