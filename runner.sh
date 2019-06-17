#!/usr/bin/env bash

SRC_ROOT=$(dirname "$1")
PLUGIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Derive a tmp build directory
SRC_UUID="$( echo -n "$SRC_ROOT" | md5 )"
BUILD_DIR="/tmp/SwiftPlayground-$SRC_UUID"
ASSET_DIR="/tmp/SwiftPlaygroundAssets-$SRC_UUID"

# Remove if it already existed. Errors seem to be swallowed otherwise
rm -rf "$BUILD_DIR"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || exit 1

# For now, dump the entire file into main this is likely contents.swift
# Consider writing the buffer instead
cat "$1" > main.swift

# Build up a SwiftC invocation and then run

if [[ -d "$SRC_ROOT"/Sources/ ]]; then
    # Framework includes, rpath, and source includes
    PLAYGROUND_FLAGS="-F$SRC_ROOT/Sources/ -I$SRC_ROOT/Sources/ -Xlinker -rpath -Xlinker $SRC_ROOT/Sources/"

    # WARNING! this may be dangerous in some terminals.
    PLAYGROUND_SOURCES="$( find "$SRC_ROOT"/Sources/*.swift )"
else
    PLAYGROUND_FLAGS=""
    PLAYGROUND_SOURCES=""
fi

# Check contents.xcplayground for ios
if grep -q "target-platform='ios'" "$SRC_ROOT/contents.xcplayground" &>/dev/null; then
    XCODE_APP_DEVELOPER_DIR=$( xcode-select -p )

    rm -rf "$ASSET_DIR"
    mkdir -p "$ASSET_DIR"
    cp "$PLUGIN_DIR/PlaygroundUIRuntime.swift" .
    echo "private let assetDirectory = \"$ASSET_DIR\"" >> ./PlaygroundUIRuntime.swift

    # Build and run for iOS
    xcrun swiftc \
    -Xfrontend \
    -debugger-support \
    -Xfrontend \
    -playground \
    -module-name \
    Playground \
    -target \
    x86_64-apple-ios10.0 \
    -sdk \
    "$XCODE_APP_DEVELOPER_DIR/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" \
    -F \
    "$XCODE_APP_DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks" \
    $PLAYGROUND_FLAGS \
    -o \
    main \
    main.swift \
    $PLAYGROUND_SOURCES \
    PlaygroundUIRuntime.swift

    # Run on the simulator by default.
    # We build for x86_64, so use the first iPhone that isn't a 5.
    # Find a device that is either (booted) or (shutdown)
    DEVICE=$(xcrun simctl list | grep 'iPhone [^5] .*(.*).*(.*)' | perl -ne 'print "$&\n" if /([A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12})/' | sed -n 1p )
    xcrun simctl spawn "$DEVICE" ./main
else
    # Build and run for the host target
    # This invocation theoretically shouldn't need any OSX specifics at this
    # level.
    xcrun swiftc \
    -Xfrontend \
    -debugger-support \
    -Xfrontend \
    -playground \
    -module-name \
    Playground \
    $PLAYGROUND_FLAGS \
    -o \
    main \
    main.swift \
    $PLAYGROUND_SOURCES \
    "$PLUGIN_DIR"/PlaygroundRuntime.swift

    ./main
fi
