#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

##################################################################
# 1. Configuration
##################################################################

current_path=$PWD
mac_patch_helper="$current_path/../tools/mac_patch_helper"
mac_patch_helper_config="$current_path/../tools/patch.json"
SMJobBlessUtil="$current_path/../tools/SMJobBlessUtil-python3.py"

app_name="$1"
helper_name="$2"

echo -e "${GREEN}Helper name: ${helper_name}${NC}"


##################################################################
# 2. Backup
##################################################################

helper_executable_path="/Applications/${app_name}.app/Contents/Library/LaunchServices/${helper_name}"
helper_executable_backup_path="${helper_executable_path}_Backup"
echo -e "${GREEN}Helper executable path: ${helper_executable_path}${NC}"

if [ ! -f "$helper_executable_backup_path" ]; then
    cp "$helper_executable_path" "$helper_executable_backup_path"
    echo -e "${YELLOW}🔄 Backup created.${NC}"
fi

##################################################################
# 3. Helper Injection
##################################################################
dylib_name="dylib_dobby_hook"
prefix="lib"
insert_dylib="${current_path}/../tools/insert_dylib"

chmod a+x "${insert_dylib}"

BUILT_PRODUCTS_DIR="${current_path}/../release"
app_bundle_framework="/Applications/${app_name}.app/Contents/Frameworks/"
echo -e "${GREEN}App bundle framework directory: ${app_bundle_framework}${NC}"

if [ ! -d "$app_bundle_framework" ]; then
  mkdir -p "$app_bundle_framework"
  echo -e "${YELLOW}📁 Created framework directory.${NC}"
fi
echo -e "${GREEN}🚀 Injecting dylib into ${helper_executable_path}${NC}"
"${insert_dylib}" --weak --all-yes "${app_bundle_framework}/${prefix}${dylib_name}.dylib" "$helper_executable_backup_path" "$helper_executable_path"

##################################################################
# 4. Patch
##################################################################

echo -e "${GREEN}🔧 Running mac_patch_helper to apply patch...${NC}"
sudo chmod a+x "$mac_patch_helper"
/usr/bin/xattr -cr "$mac_patch_helper"
$mac_patch_helper "$app_name" "$mac_patch_helper_config"

app_path="/Applications/${app_name}.app"
app_helper_path="/Applications/${app_name}.app/Contents/Library/LaunchServices/${helper_name}"

echo -e "${YELLOW}Updating permissions for ${app_helper_path}${NC}"
sudo chmod a+rwx "$app_helper_path"
/usr/bin/xattr -cr "$app_helper_path"

echo -e "${GREEN}🔄 Removing old $helper_name files...${NC}"
sudo launchctl unload "/Library/LaunchDaemons/com.binarynights.ForkLiftHelper.plist" 2>/dev/null
sudo /usr/bin/killall -u root -9 "com.binarynights.ForkLiftHelper" 2>/dev/null
sudo /bin/rm "/Library/LaunchDaemons/com.binarynights.ForkLiftHelper.plist" 2>/dev/null
sudo /bin/rm "/Library/PrivilegedHelperTools/com.binarynights.ForkLiftHelper" 2>/dev/null
sudo rm -rf "~/Library/Preferences/com.binarynights.ForkLift.plist" 2>/dev/null
sudo rm -rf "~/Library/Application Support/com.binarynights.ForkLift" 2>/dev/null
sudo /bin/rm "/Library/PrivilegedHelperTools/com.binarynights.ForkLiftHelper" 2>/dev/null

echo -e "${GREEN}🔧 Modifying Info.plist for $app_name...${NC}"
identifier_name="identifier \\\"$helper_name\\\""
requirements_name="$identifier_name"
sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' "/Applications/$app_name.app/Contents/Info.plist"
sudo /usr/libexec/PlistBuddy -c "Set :SMPrivilegedExecutables:$helper_name \"$requirements_name\"" "/Applications/$app_name.app/Contents/Info.plist"
sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' "/Applications/$app_name.app/Contents/Info.plist"

##################################################################
# 5. Code Signing
##################################################################

echo -e "${GREEN}🔍 Checking code signature before re-signing${NC}"
sudo codesign -d -r- "$app_helper_path"

echo -e "${GREEN}🔏 Re-signing $app_name and $helper_name...${NC}"
sudo codesign -f -s - --all-architectures --deep "$app_path"
sudo codesign -f -s - --all-architectures --deep "$app_helper_path"

echo -e "${GREEN}🔍 Checking code signature after re-signing${NC}"
sudo codesign -d -r- "$app_helper_path"
