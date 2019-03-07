#!/bin/sh

set -euo pipefail

# Build the rust project.
cd rust
cargo clean
cargo test

cargo lipo --release

cp /Users/j/Desktop/Code/rusty_flutter/rust/target/universal/release/librusted.a /Users/j/Desktop/Code/rusty_flutter/ios/Runner/
