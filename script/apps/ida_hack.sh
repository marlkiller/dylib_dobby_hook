 #!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

current_path=$PWD
ida_path="/Applications/IDA Professional 9.1.app"
app_name=$(basename "$ida_path" .app)

echo -e "${GREEN}✅ [${app_name}] - Copying license file...${NC}"
cp -f "$PWD/apps/IDA/idapro.hexlic" "$ida_path/Contents/MacOS/"

idapro_dir="$HOME/.idapro"
if [ ! -d "$idapro_dir" ]; then
    mkdir -p "$idapro_dir"
    echo -e "${GREEN}✅ [${app_name}] - Created ~/.idapro directory.${NC}"
fi

plugins_dir="$idapro_dir/plugins"

rm -rf "$plugins_dir"
cp -R "$PWD/apps/IDA/plugins" "$plugins_dir"
echo -e "${GREEN}✅ [${app_name}] - Overwritten existing plugins with new ones.${NC}"


# 检查是否为 ARM 架构
# if [ "$(uname -m)" = "arm64" ]; then
#     plugin_path="$ida_path/Contents/MacOS/plugins/arm_mac_user64.dylib"
#     if [ -f "$plugin_path" ]; then
#         sudo mv "$plugin_path" "${plugin_path}.Backup"
#     fi
# fi


# sudo codesign --force --deep --sign - /Applications/IDA\ Professional\ 9.0.app/Contents/MacOS/libida64.dylib
# sudo codesign --force --deep --sign - /Applications/IDA\ Professional\ 9.0.app/Contents/MacOS/libida32.dylib
# sudo codesign --force --deep --sign - /Applications/IDA\ Professional\ 9.0.app/Contents/MacOS/libida.dylib
