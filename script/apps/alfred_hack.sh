#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

insert_dylib="$PWD/../tools/insert_dylib"
app_name="Alfred 5"
app_path="/Applications/${app_name}.app"
preferences_bin="${app_path}/Contents/Preferences/Alfred Preferences.app/Contents/MacOS/Alfred Preferences"

echo -e "${GREEN}✅ [${app_name}] - Injecting dylib into Alfred Preferences...${NC}"
sudo "$insert_dylib" --inplace --weak --all-yes --no-strip-codesig '@rpath/libdylib_dobby_hook.dylib' "$preferences_bin"

echo -e "${GREEN}✅ [${app_name}] - Re-signing Alfred Preferences...${NC}"
sudo codesign -f -s - --all-architectures --deep "$preferences_bin"
