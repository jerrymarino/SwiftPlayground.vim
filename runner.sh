mkdir -p build

# For now, dump the entire file into main
# this is likely contents.swift
cat $1 > build/main.swift

swiftc \
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

