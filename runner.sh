dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $dir

# Clean all for now. Hack to display errors, and ideally
# we will not do this!
rm -rf build

mkdir -p build

# For now, dump the entire file into main this is likely contents.swift
cat $1 > build/main.swift

xcrun swiftc \
-Xfrontend \
-playground \
-Xfrontend \
-debugger-support \
-module-name Playgound \
-o \
build/main \
build/main.swift \
PlaygroundRuntime.swift

./build/main

