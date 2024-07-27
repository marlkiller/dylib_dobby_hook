current_path=$PWD
mac_patch_helper="$current_path/../tools/mac_patch_helper"
mac_patch_helper_config="$current_path/../tools/patch.json"
SMJobBlessUtil="$current_path/../tools/SMJobBlessUtil-python3.py"

helper_name="com.binarynights.ForkLiftHelper"
app_name="ForkLift"

########### 注入 ###########
echo ">>>>>> helper_name is ${helper_name}"

dylib_name="dylib_dobby_hook"
prefix="lib"
insert_dylib="${current_path}/../tools/insert_dylib"

chmod a+x ${insert_dylib}

BUILT_PRODUCTS_DIR="${current_path}/../release"

app_bundle_framework="/Applications/${app_name}.app/Contents/Frameworks/"
echo ">>>>>> app_bundle_framework is ${app_bundle_framework}"

if [ ! -d "$app_bundle_framework" ]; then
  mkdir -p "$app_bundle_framework"
fi

helper_executable_path="/Applications/${app_name}.app/Contents/Library/LaunchServices/${helper_name}"
helper_executable_backup_path="${helper_executable_path}_Backup"
echo ">>>>>> helper_executable_path is ${helper_executable_path}"

if [ ! -f "$helper_executable_backup_path" ];
then
    cp "$helper_executable_path" "$helper_executable_backup_path"
fi



echo "check insert_dylib quarantine:"
xattr "${insert_dylib}"
# sudo xattr -r -d com.apple.quarantine "${insert_dylib}"
"${insert_dylib}" --weak --all-yes "${app_bundle_framework}/${prefix}${dylib_name}.dylib" "$helper_executable_backup_path" "$helper_executable_path"
echo ">>>>>> hack [${helper_name}] completed"


############ 修复 ###########

sudo chmod a+x $mac_patch_helper
$mac_patch_helper "ForkLift" $mac_patch_helper_config

forklift_path="/Applications/ForkLift.app"
forklift_helper_path="/Applications/ForkLift.app/Contents/Library/LaunchServices/com.binarynights.ForkLiftHelper"
# codesign -dvv "/Applications/ForkLift.app/Contents/Library/LaunchServices/com.binarynights.ForkLiftHelper"

#
echo $SUDO_USER
sudo chmod a+rwx "$forklift_helper_path"


sudo launchctl unload "/Library/LaunchDaemons/com.binarynights.ForkLiftHelper.plist"
sudo /usr/bin/killall -u root -9 "com.binarynights.ForkLiftHelper"
sudo /bin/rm "/Library/LaunchDaemons/com.binarynights.ForkLiftHelper.plist"
sudo /bin/rm "/Library/PrivilegedHelperTools/com.binarynights.ForkLiftHelper" 
sudo rm -rf "~/Library/Preferences/com.binarynights.ForkLift.plist" 
sudo rm -rf "~/Library/Application Support/com.binarynights.ForkLift" 
sudo /bin/rm /Library/PrivilegedHelperTools/com.binarynights.ForkLiftHelper

xattr -c '/Applications/ForkLift.app'


# Ref : https://github.com/imothee/tmpdisk/blob/291d3f83e22967b1387ae48f4c930c2c4acbb888/BuildScripts/build.sh#L29
identifier_name="identifier \\\"$helper_name\\\""
#ORG_UNIT="certificate leaf[subject.OU] = \"$DEVELOPMENT_TEAM\""
#requirements_name="$GENERIC and $IDENTIFIER and $ORG_UNIT"
requirements_name="$identifier_name"
sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' "/Applications/ForkLift.app/Contents/Info.plist"
sudo /usr/libexec/PlistBuddy -c "Set :SMPrivilegedExecutables:$helper_name \"$requirements_name\"" "/Applications/ForkLift.app/Contents/Info.plist"
sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' "/Applications/ForkLift.app/Contents/Info.plist"


echo "codesign before"
sudo codesign -d -r- "$forklift_path"
sudo codesign -d -r- "$forklift_helper_path"

sudo codesign -f -s - --all-architectures --deep "$forklift_path"
sudo codesign -f -s - --all-architectures --deep "$forklift_helper_path"

echo "codesign after"
sudo codesign -d -r- "$forklift_path"
sudo codesign -d -r- "$forklift_helper_path"



