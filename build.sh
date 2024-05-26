#!/bin/bash




# 设置项目根目录
PROJECT_ROOT=$(pwd)

# 设置构建目录
BUILD_DIR="$PROJECT_ROOT/cmake-build-release"


rm -rf "$BUILD_DIR"

# 创建构建目录
mkdir -p "$BUILD_DIR"

# 进入构建目录
cd "$BUILD_DIR"

# 运行 CMake 生成构建文件
cmake "$PROJECT_ROOT"

# 构建项目
make -j4

# 安装项目
make install

echo "项目构建和安装完成."


cd "$PROJECT_ROOT"

# 设置需要打包的文件列表
FILES=(
  "release"
  "script"
  "tools"
)


# 设置压缩文件名称
ARCHIVE_NAME="dylib_dobby_hook.tar.gz"

# 创建压缩文件
tar -czf "$ARCHIVE_NAME" "${FILES[@]}"

echo "已将以下文件打包到 $ARCHIVE_NAME:"
for file in "${FILES[@]}"; do
  echo "- $file"
done


