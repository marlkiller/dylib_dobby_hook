#!/bin/bash

set -e

# Default values
BUILD_TYPE="Release"
BUILD_SYSTEM="cmake"
ENABLE_HIKARI="OFF"

usage() {
  echo "Usage: $0 [-s cmake|xcode] [-t Debug|Release] [-h ON|OFF]"
  echo "  -s  Build system: cmake (default) or xcode"
  echo "  -t  Build type: Debug or Release (default: Release)"
  echo "  -h  Enable Hikari: ON or OFF (default: OFF)"
  exit 1
}

# Parse arguments
while getopts "s:t:h:" opt; do
  case $opt in
    s) BUILD_SYSTEM="$OPTARG" ;;
    t) BUILD_TYPE="$OPTARG" ;;
    h) ENABLE_HIKARI="$OPTARG" ;;
    *) usage ;;
  esac
done

PROJECT_ROOT=$(pwd)

if [ "$BUILD_SYSTEM" = "xcode" ]; then
  echo "🔨 Building with Xcode ($BUILD_TYPE)..."
  DERIVED_DATA_PATH="$PROJECT_ROOT/xcode-build"
  XCODE_ARGS=(
    -scheme dylib_dobby_hook
    -configuration "$BUILD_TYPE"
    -derivedDataPath "$DERIVED_DATA_PATH"
    COMPILER_INDEX_STORE_ENABLE=NO
    ENABLE_BITCODE=NO
    GCC_OPTIMIZATION_LEVEL=0
  )
  if [ "$ENABLE_HIKARI" = "ON" ]; then
    XCODE_ARGS+=(
      OTHER_CFLAGS="\
        -mllvm -hikari \
        -mllvm -enable-strcry \
        -mllvm -enable-cffobf \
        -mllvm -enable-subobf \
        -mllvm -enable-fco \
        -mllvm -ah_objcruntime \
        -mllvm -ah_inline \
        -mllvm -enable-indibran \
        -mllvm -indibran-enc-jump-target \
        -mllvm -ah_antirebind"
      TOOLCHAINS=Hikari_LLVM20.1.5
    )
    echo "✅ Hikari enabled for Xcode."
  else
    echo "ℹ️ Hikari disabled for Xcode."
  fi
  xcodebuild clean -scheme dylib_dobby_hook -configuration "$BUILD_TYPE" -derivedDataPath "$DERIVED_DATA_PATH"
  xcodebuild "${XCODE_ARGS[@]}"
  PRODUCT_DYLIB="$DERIVED_DATA_PATH/Build/Products/$BUILD_TYPE/libdylib_dobby_hook.dylib"
  echo "✅ Build completed. Product located at: $PRODUCT_DYLIB"

else
  echo "🔨 Building with CMake ($BUILD_TYPE)..."
  BUILD_DIR="$PROJECT_ROOT/cmake-build-$BUILD_TYPE"
  SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
  if [ -z "$SDK_PATH" ]; then
      echo "Error: Could not determine macOS SDK path. Is Xcode or Command Line Tools installed correctly?"
      echo "Please ensure Xcode is installed or run 'xcode-select --install'."
      exit 1
  fi
  export MACOS_SDK_ROOT="$SDK_PATH"
  if [ "$ENABLE_HIKARI" = "ON" ]; then
    # https://github.com/Aethereux/Hikari-LLVM19/releases/tag/Hikari-LLVM20
    #export hikari_llvm_bin="/Applications/Xcode.app/Contents/Developer/Toolchains/Hikari_LLVM20.1.5.xctoolchain/usr/bin"
    PATH_Hikari_XCODE="/Applications/Xcode.app/Contents/Developer/Toolchains/Hikari_LLVM20.1.5.xctoolchain/usr/bin"
    PATH_Hikari_USER_LIBRARY="~/Library/Developer/Toolchains/Hikari_LLVM20.1.5.xctoolchain/usr/bin"

    # Check if the Xcode path exists
    if [ -d "$PATH_Hikari_XCODE" ]; then
        export hikari_llvm_bin="$PATH_Hikari_XCODE"
        echo "Using Hikari LLVM from Xcode path: $hikari_llvm_bin"
    # Otherwise, check if the user's Library path exists
    elif [ -d "$(eval echo "$PATH_Hikari_USER_LIBRARY")" ]; then # 'eval echo' is needed to expand '~'
        export hikari_llvm_bin="$(eval echo "$PATH_Hikari_USER_LIBRARY")"
        echo "Using Hikari LLVM from user Library path: $hikari_llvm_bin"
    else
        echo "Error: No valid path found for Hikari LLVM toolchain."
        echo "Please ensure Hikari_LLVM20.1.5.xctoolchain exists in one of the following directories:"
        echo "  - /Applications/Xcode.app/Contents/Developer/Toolchains/"
        echo "  - ~/Library/Developer/Toolchains/"
        exit 1 # Exit the script as the toolchain wasn't found
    fi
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
  cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DENABLE_HIKARI="$ENABLE_HIKARI" -DCMAKE_OSX_SYSROOT="${MACOS_SDK_ROOT}" "$PROJECT_ROOT"
  make -j4
  make install
  cd "$PROJECT_ROOT"
fi

echo "✅ Project build and installation completed."

FILES=(
  "release"
  "script"
  "tools"
)
EXCLUDE_FILES=(
  "local_apps.json"
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
