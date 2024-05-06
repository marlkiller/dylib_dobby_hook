current_path=$PWD
mac_patch_helper="$PWD/../tools/mac_patch_helper"
mac_patch_helper_config="$PWD/../tools/patch.json"
SMJobBlessUtil="$PWD/../tools/SMJobBlessUtil-python3.py"


sudo chmod a+x $mac_patch_helper



# 修改 helper
$mac_patch_helper Surge $mac_patch_helper_config


surge_path="/Applications/Surge.app"
surge_helper_path="/Applications/Surge.app/Contents/Library/LaunchServices/com.nssurge.surge-mac.helper"


echo $SUDO_USER
sudo chmod a+rwx "$surge_helper_path"

# 先使用lipo将help strip成单一架构的binary，否则codesign重签名后验证依然不通过（因为只签了当前架构的）?
# lipo -thin x86_64 "$surge_helper_path" -output "$surge_helper_path"
# lipo -thin x86_64 "$surge_path/Contents/MacOS/Surge" -output "$surge_path/Contents/MacOS/Surge"
# lipo -info "$surge_path"
# lipo -info "$surge_helper_path"


# /tmp/uninstall-surge-helper.sh
sudo /bin/launchctl unload /Library/LaunchDaemons/com.nssurge.surge-mac.helper.plist
sudo /usr/bin/killall -u root -9 com.nssurge.surge-mac.helper
sudo /bin/rm /Library/LaunchDaemons/com.nssurge.surge-mac.helper.plist
sudo /bin/rm /Library/PrivilegedHelperTools/com.nssurge.surge-mac.helper
sudo /bin/rm "~/Library/Preferences/com.nssurge.surge-mac.plist" 
sudo /bin/rm "~/Library/Application Support/com.nssurge.surge-mac" 


xattr -c '/Applications/Surge.app'
# 修改主程序的 Info.plist 的 SMPrivilegedExecutables 域并重签名
sudo /usr/libexec/PlistBuddy -c "Set :SMPrivilegedExecutables:com.nssurge.surge-mac.helper \"identifier \\\"com.nssurge.surge-mac.helper\\\"\"" "/Applications/Surge.app/Contents/Info.plist"
sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' /Applications/Surge.app/Contents/Info.plist

echo "codesign.."
sudo codesign -f -s - --all-architectures --deep "$surge_path"
sudo codesign -f -s - --all-architectures --deep "$surge_helper_path"
python3 "$SMJobBlessUtil" check "$surge_path"

# echo "codesign.."
# sudo codesign -f -s - --all-architectures --deep "$surge_path"
# sudo codesign -f -s - --all-architectures --deep "$surge_helper_path"
# python3 "$SMJobBlessUtil" check "$surge_path"
# /Users/voidm/Downloads/Surge.app/Contents/Library/LaunchServices/com.nssurge.surge-mac.helper: tool designated requirement malformed