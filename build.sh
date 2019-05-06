#!/bin/sh

set -euo pipefail

# Build the rust project.
cd rust
cargo clean

cargo lipo --release
cargo build --target aarch64-linux-android --release
cargo build --target armv7-linux-androideabi --release
cargo build --target i686-linux-android --release

cp /Users/j/Desktop/Code/rusty_flutter/rust/target/universal/release/librusted.a /Users/j/Desktop/Code/rusty_flutter/ios/Runner/
cp /Users/j/Desktop/Code/rusty_flutter/rust/target/aarch64-linux-android/release/librusted.so /Users/j/Desktop/Code/rusty_flutter/android/app/src/main/jniLibs/arm64-v8a/
cp /Users/j/Desktop/Code/rusty_flutter/rust/target/armv7-linux-androideabi/release/librusted.so /Users/j/Desktop/Code/rusty_flutter/android/app/src/main/jniLibs/armeabi-v7a/
cp /Users/j/Desktop/Code/rusty_flutter/rust/target/i686-linux-android/release/librusted.so /Users/j/Desktop/Code/rusty_flutter/android/app/src/main/jniLibs/x86/

