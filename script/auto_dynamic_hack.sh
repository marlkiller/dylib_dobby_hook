#!/bin/bash

# This script generates a 'AppStarter' script to launch the target application,
# dynamically injecting the dobby_hook_dylib using the DYLD_INSERT_LIBRARIES environment variable while keeping the original files and code signatures intact.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
         
current_path=$PWD
dylib_name="dylib_dobby_hook"
prefix="lib"
BUILT_PRODUCTS_DIR="${current_path}/../release"
         
force_flag=false
# 判断脚本是否有 -f 参数
if [[ "$@" =~ "-f" ]]; then
    force_flag=true
fi

ALL_APPS_LIST=(
    "Surge"
)

if [ ! -f "${BUILT_PRODUCTS_DIR}/${prefix}${dylib_name}.dylib" ]; then
    echo -e "\033[31mError: [${BUILT_PRODUCTS_DIR}/${prefix}${dylib_name}.dylib] does not exist.\033[0m"
    echo -e "\033[31mPlease compile the project first.\033[0m"
    exit 1
fi
check_sip_status() {
    sip_status=$(csrutil status | grep -i "enabled")
    if [[ ! -z "$sip_status" ]]; then
        printf "${RED}❌ SIP (System Integrity Protection) is enabled. Please disable it and try again.${NC}\n"
        exit 1
    fi
}

inject_dobby_hook() {
    app_name="$1"
    if [ -d "/Applications/${app_name}.app" ]; then
        version=$(defaults read "/Applications/${app_name}.app/Contents/Info.plist" CFBundleShortVersionString)
        bundle_id=$(defaults read "/Applications/${app_name}.app/Contents/Info.plist" CFBundleIdentifier)
        if [ "$force_flag" = true ]; then
            user_input="Y"
        else
            printf "✅ ${GREEN}[${app_name}${NC} ${version} ${RED}(${bundle_id})${NC}${GREEN}]${NC} exists, wanna inject? (Y/N): "
            read -r user_input
        fi
        if [ "$user_input" = "Y" ] || [ "$user_input" = "y" ]; then
            printf "\n${GREEN}🚀 [${app_name}] - dylib_dobby_hook Dynamic Injection starting...${NC}\n"
            app_bundle_framework="/Applications/${app_name}.app/Contents/Frameworks/"
            cp -f "${BUILT_PRODUCTS_DIR}/${prefix}${dylib_name}.dylib" "${app_bundle_framework}"
            starter_path="/Applications/${app_name}.app/Contents/MacOS/${app_name}Starter"
            
            cat <<EOF > "$starter_path"
#!/bin/bash

CurrentAppPath=\$(cd \$(dirname \$0) && cd .. && pwd)
dylib_path="\${CurrentAppPath}/Frameworks/libdylib_dobby_hook.dylib"

if [ ! -f "\$dylib_path" ]; then
    echo -e "\033[31mError: [\$dylib_path] does not exist.\033[0m"
    exit 1
fi

env DYLD_INSERT_LIBRARIES="\$dylib_path" /Applications/${app_name}.app/Contents/MacOS/${app_name} &
EOF
            
            chmod +x "$starter_path"
            printf "${GREEN}✅ Dynamic Injection completed: ${starter_path}${NC}\n"
        else
            printf "${YELLOW}😒 App skipped on user demand.${NC}\n"
        fi
    else
        printf "${RED}❌ [${app_name}]${NC} not found. Please download and install the app.\n"
    fi
}

start() {
    check_sip_status
    for app_entry in "${ALL_APPS_LIST[@]}"; do
        IFS="|" read -r app_name <<<"$app_entry"
        inject_dobby_hook "$app_name"
    done
}

printf "\n${GREEN}💉💉💉 dylib_dobby_hook Dynamic Injector 🚀🚀🚀${NC}\n\n"
printf "${GREEN}🤖 Dynamic Injection Start...${NC}\n\n"
start
