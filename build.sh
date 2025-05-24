#!/bin/bash

# xcode build
# xcodebuild -scheme dylib_dobby_hook -configuration Release

PROJECT_ROOT=$(pwd)
BUILD_DIR="$PROJECT_ROOT/cmake-build-release"

# Set to "ON" to enable Hikari
ENABLE_HIKARI="OFF"
if [ "$ENABLE_HIKARI" = "ON" ]; then
  # If Hikari is enabled, configure custom LLVM toolchain
  # https://github.com/Aethereux/Hikari-LLVM19/releases/tag/Hikari-LLVM20
  export hikari_llvm_bin="/Applications/Xcode.app/Contents/Developer/Toolchains/Hikari_LLVM20.1.5.xctoolchain/usr/bin"
  export CC="${hikari_llvm_bin}/clang"
  export CXX="${hikari_llvm_bin}/clang++"
  if [ ! -x "$CC" ]; then
    echo "❌ Hikari clang not found or not executable: $CC"
    exit 1
  fi
  echo "✅ Hikari enabled: using $CC"
else
  echo "ℹ️ Hikari disabled: using default system compiler"
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_HIKARI=$ENABLE_HIKARI "$PROJECT_ROOT" 
make -j4
make install

echo "✅ Project build and installation completed."

cd "$PROJECT_ROOT"
FILES=(
  "release"
  "script"
  "tools"
)
EXCLUDE_FILES=(
  "Organismo-mac.framework"
  "script/apps/IDA/plugins/" # Too Big
)

ARCHIVE_NAME="dylib_dobby_hook.tar.gz"


EXCLUDE_PARAMS=()
for exclude in "${EXCLUDE_FILES[@]}"; do
  EXCLUDE_PARAMS+=(--exclude="$exclude")
done


tar -czf "$ARCHIVE_NAME" "${EXCLUDE_PARAMS[@]}" "${FILES[@]}"

echo "✅ The following files have been packed into $ARCHIVE_NAME:"
for file in "${FILES[@]}"; do
  echo "- $file"
done
