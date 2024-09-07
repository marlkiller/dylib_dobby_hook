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

helper_name="com.binarynights.ForkLiftHelper"
app_name="ForkLift"

echo -e "${GREEN}Helper name: ${helper_name}${NC}"

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

echo -e "${YELLOW}Checking quarantine status of ${insert_dylib}:${NC}"
/usr/bin/xattr "${insert_dylib}"

echo -e "${GREEN}🚀 Injecting dylib into ${helper_executable_path}${NC}"
"${insert_dylib}" --weak --all-yes "${app_bundle_framework}/${prefix}${dylib_name}.dylib" "$helper_executable_backup_path" "$helper_executable_path"

##################################################################
# 4. Patch
##################################################################

echo -e "${GREEN}🔧 Running mac_patch_helper to apply patch...${NC}"
sudo chmod a+x "$mac_patch_helper"
$mac_patch_helper "ForkLift" "$mac_patch_helper_config"

forklift_path="/Applications/ForkLift.app"
forklift_helper_path="/Applications/ForkLift.app/Contents/Library/LaunchServices/com.binarynights.ForkLiftHelper"

echo -e "${YELLOW}Updating permissions for ${forklift_helper_path}${NC}"
sudo chmod a+rwx "$forklift_helper_path"

echo -e "${GREEN}🔄 Removing old ForkLiftHelper files...${NC}"
sudo launchctl unload "/Library/LaunchDaemons/com.binarynights.ForkLiftHelper.plist" 2>/dev/null
sudo /usr/bin/killall -u root -9 "com.binarynights.ForkLiftHelper" 2>/dev/null
sudo /bin/rm "/Library/LaunchDaemons/com.binarynights.ForkLiftHelper.plist" 2>/dev/null
sudo /bin/rm "/Library/PrivilegedHelperTools/com.binarynights.ForkLiftHelper" 2>/dev/null
sudo rm -rf "~/Library/Preferences/com.binarynights.ForkLift.plist" 2>/dev/null
sudo rm -rf "~/Library/Application Support/com.binarynights.ForkLift" 2>/dev/null
sudo /bin/rm /Library/PrivilegedHelperTools/com.binarynights.ForkLiftHelper 2>/dev/null
/usr/bin/xattr -cr '/Applications/ForkLift.app'

echo -e "${GREEN}🔧 Modifying Info.plist for ForkLift...${NC}"
identifier_name="identifier \\\"$helper_name\\\""
requirements_name="$identifier_name"
sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' "/Applications/ForkLift.app/Contents/Info.plist"
sudo /usr/libexec/PlistBuddy -c "Set :SMPrivilegedExecutables:$helper_name \"$requirements_name\"" "/Applications/ForkLift.app/Contents/Info.plist"
sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' "/Applications/ForkLift.app/Contents/Info.plist"

##################################################################
# 5. Code Signing
##################################################################

echo -e "${GREEN}🔍 Checking code signature before re-signing${NC}"
sudo codesign -d -r- "$forklift_path"
sudo codesign -d -r- "$forklift_helper_path"

echo -e "${GREEN}🔏 Re-signing ForkLift and ForkLiftHelper...${NC}"
sudo codesign -f -s - --all-architectures --deep "$forklift_path"
sudo codesign -f -s - --all-architectures --deep "$forklift_helper_path"

echo -e "${GREEN}🔍 Checking code signature after re-signing${NC}"
sudo codesign -d -r- "$forklift_path"
sudo codesign -d -r- "$forklift_helper_path"
