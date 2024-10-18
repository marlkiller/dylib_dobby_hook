
#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

##################################################################
# 1. Configuration
##################################################################
current_path=$PWD
app_name="AirBuddy"
helper_name="AirBuddyHelper"
Installer="codes.rambo.AirBuddy.Installer"
app_path="/Applications/${app_name}.app"
app_helper_path="/Applications/${app_name}.app/Contents/Library/LoginItems/${helper_name}.app"
echo -e "${GREEN}Helper name: ${helper_name}${NC}"

##################################################################
# 2. Backup
##################################################################
helper_executable_path="${app_helper_path}/Contents/MacOS/AirBuddyHelper"
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



echo -e "${YELLOW}Updating permissions for ${helper_executable_path}${NC}"
sudo chmod a+rwx "$helper_executable_path"
/usr/bin/xattr -cr "$helper_executable_path"

# if need?
echo -e "${GREEN}🔄 Removing old $helper_name files...${NC}"


echo -e "${GREEN}🔧 Modifying Info.plist for $app_name...${NC}"
identifier_name="identifier \\\"codes.rambo.AirBuddyHelper\\\""
requirements_name="$identifier_name"
sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' "/Applications/$app_name.app/Contents/Info.plist"
sudo /usr/libexec/PlistBuddy -c "Set :SMPrivilegedExecutables:$Installer \"$requirements_name\"" "/Applications/$app_name.app/Contents/Info.plist"
sudo /usr/libexec/PlistBuddy -c 'Print SMPrivilegedExecutables' "/Applications/$app_name.app/Contents/Info.plist"


##################################################################
# 4. Code Signing
##################################################################
echo -e "${GREEN}🔍 Checking code signature before re-signing${NC}"
sudo codesign -d -r- "$app_helper_path"

echo -e "${GREEN}🔏 Re-signing $app_name and $helper_name...${NC}"
sudo codesign -f -s - --all-architectures --deep "$app_helper_path"
sudo codesign -f -s - --all-architectures --deep "$app_path"

echo -e "${GREEN}🔍 Checking code signature after re-signing${NC}"
sudo codesign -d -r- "$app_helper_path"
