#!/bin/bash

# xcode build
# xcodebuild  -scheme dylib_dobby_hook -configuration Release

PROJECT_ROOT=$(pwd)
BUILD_DIR="$PROJECT_ROOT/cmake-build-release"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
cmake "$PROJECT_ROOT"
make -j4
make install

echo "✅ Project build and installation completed."

cd "$PROJECT_ROOT"
FILES=(
  "release"
  "script"
  "tools"
)
ARCHIVE_NAME="dylib_dobby_hook.tar.gz"
tar -czf "$ARCHIVE_NAME" "${FILES[@]}"

echo "✅ The following files have been packed into $ARCHIVE_NAME:"
for file in "${FILES[@]}"; do
  echo "- $file"
done
