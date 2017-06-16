mkdir -p build
ditto main.swift build/main.swift

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

