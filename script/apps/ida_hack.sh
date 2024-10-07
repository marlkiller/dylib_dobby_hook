 #!/bin/bash

current_path=$PWD
mac_patch_helper="$PWD/../tools/mac_patch_helper"
mac_patch_helper_config="$PWD/../tools/patch.json"


sudo chmod a+x $mac_patch_helper
ida_path="/Applications/IDA Professional 9.0.app"



$mac_patch_helper "IDA" $mac_patch_helper_config 
cp -f "$PWD/apps/IDA/idapro.hexlic" "$ida_path/Contents/MacOS/"

# 检查是否为 ARM 架构
# if [ "$(uname -m)" = "arm64" ]; then
#     plugin_path="$ida_path/Contents/MacOS/plugins/arm_mac_user64.dylib"
#     if [ -f "$plugin_path" ]; then
#         sudo mv "$plugin_path" "${plugin_path}.Backup"
#     fi
# fi


# sudo codesign --force --deep --sign - /Applications/IDA\ Professional\ 9.0.app/Contents/MacOS/libida64.dylib
# sudo codesign --force --deep --sign - /Applications/IDA\ Professional\ 9.0.app/Contents/MacOS/libida.dylib
