#!/bin/sh

set -euo pipefail

# Build the rust project.
cd rust
cargo clean

#emulator
#cargo build --target i686-linux-android --release
#device
cargo build --target aarch64-linux-android --release

#emulator
#cp /Users/j/Desktop/Code/rusty_flutter/rust/target/i686-linux-android/release/librusted.so /Users/j/Desktop/Code/rusty_flutter/android/app/src/main/jniLibs/x86/
#device
cp /Users/j/Desktop/Code/rusty_flutter/rust/target/aarch64-linux-android/release/librusted.so /Users/j/Desktop/Code/rusty_flutter/android/app/src/main/jniLibs/arm64-v8a/
