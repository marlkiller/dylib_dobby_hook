#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

##################################################################
# 1. Configuration
##################################################################
current_path=$PWD
mac_patch_helper="$PWD/../tools/mac_patch_helper"
mac_patch_helper_config="$PWD/../tools/patch.json"
SMJobBlessUtil="$PWD/../tools/SMJobBlessUtil-python3.py"
app_name="Alfred 5"
app_path="/Applications/${app_name}.app"
preferences_path= "${app_path}/Contents/Preferences/Alfred Preferences.app/Contents/MacOS/Alfred Preferences"

##################################################################
# 2. Code Signing
##################################################################
echo -e "${GREEN}🔏 Re-signing $preferences_path...${NC}"
sudo codesign -f -s - --all-architectures --deep "$preferences_path"
sudo codesign -f -s - --all-architectures --deep "$app_path"
