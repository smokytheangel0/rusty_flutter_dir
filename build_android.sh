#!/bin/sh

set -euo pipefail

# Build the rust project.
cd rust
cargo clean
cargo test

cargo build --target aarch64-linux-android --release

cp /Users/j/Desktop/Code/rusty_flutter/rust/target/aarch64-linux-android/release/librusted.so /Users/j/Desktop/Code/rusty_flutter/android/app/src/main/jniLibs/arm64-v8a/
