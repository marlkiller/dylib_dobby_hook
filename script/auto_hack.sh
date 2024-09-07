#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'


force_flag=false
# 判断脚本是否有 -f 参数
if [[ "$@" =~ "-f" ]]; then
    force_flag=true
fi

ALL_APPS_LIST=(
    "DevUtils"
    "TablePlus|/Applications/TablePlus.app/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle"
    "Paste"
    "Navicat Premium|/Applications/Navicat Premium.app/Contents/Frameworks/EE.framework/Versions/A/EE"
    "Transmit"
    # "AnyGo"
    "Proxyman|/Applications/Proxyman.app/Contents/Frameworks/HexFiend.framework/Versions/A/HexFiend"
    "AirBuddy|/Applications/AirBuddy.app/Contents/Frameworks/LetsMove.framework/Versions/A/LetsMove"
    "Infuse|/Applications/Infuse.app/Contents/Frameworks/Differentiator.framework/Versions/A/Differentiator"
    "MacUpdater|/Applications/MacUpdater.app/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle"
    "CleanShot X|/Applications/CleanShot X.app/Contents/Frameworks/LetsMove.framework/Versions/A/LetsMove"

    ## paddle:Movist Pro/Downie 4/Fork/BetterMouse/MindMac/Permute 3
    #"xx|/Applications/xx.app/Contents/Frameworks/Paddle.framework/Versions/A/Paddle"

    ## fixed with helper
    "IDA Professional 9.0|/Applications/IDA Professional 9.0.app/Contents/Frameworks/QtDBus.framework/Versions/5/QtDBus|apps/ida_hack.sh"
    "ForkLift|/Applications/ForkLift.app/Contents/Frameworks/UniversalDetector.framework/Versions/A/UniversalDetector|apps/forklift_hack.sh"
    # "Surge|/Applications/Surge.app/Contents/Frameworks/MMMarkdown.framework/Versions/A/MMMarkdown|apps/surge_hack.sh"
)


find_paddle_apps() {
    FRAMEWORK_NAME="Paddle.framework"
    APP_NAMES=()
    
    if [ "$force_flag" = true ]; then
        user_input="Y"
    else
        echo -e "${GREEN}🔍 Do you want to search for apps with ${FRAMEWORK_NAME}? (Y/N): ${NC}"
        read -r user_input
    fi
    if [ "$user_input" != "Y" ] && [ "$user_input" != "y" ]; then
        echo -e "${YELLOW}🚫 Search for ${FRAMEWORK_NAME} aborted by user.${NC}"
        return  # Exit the function if the user did not confirm
    fi
    echo -e "${GREEN}🔍 Starting search for Paddle.framework apps...${NC}"
    
    search_framework() {
        local APP_PATH="$1"
        local APP_NAME=$(basename "$APP_PATH" .app)

        if [ -d "$APP_PATH/Contents/Frameworks/$FRAMEWORK_NAME" ]; then
            if [[ ! " ${APP_NAMES[@]} " =~ " ${APP_NAME} " ]]; then
                APP_NAMES+=("$APP_NAME")
                ALL_APPS_LIST+=("$APP_NAME|$APP_PATH/Contents/Frameworks/Paddle.framework/Versions/A/Paddle")
                printf "${GREEN}🔍 Found Paddle app: ${APP_NAME}${NC}\n"
            fi
        fi
    }
    COMMON_FOLDERS=(
        "/Applications"
        "/Users/$(whoami)/Applications"
    )
    for FOLDER in "${COMMON_FOLDERS[@]}"; do
        while IFS= read -r -d '' FILE; do
            if [[ "$FILE" == *.app ]]; then
                search_framework "$FILE"
            fi
        done < <(find "$FOLDER" -name "*.app" -print0 2>/dev/null)
    done
}


inject_dobby_hook() {
    app_name="$1"
    app_path="$2"
    script_after="$3"
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
            printf "\n${GREEN}🚀 [${app_name}] - dylib_dobby_hook Injection starting...${NC}\n"
            bash all_in_one.sh "$app_name" "$app_path"
            if [ -n "$script_after" ]; then
                bash "$script_after"
            fi
        else
            printf "${YELLOW}😒 App skipped on user demand.${NC}\n"
        fi
    else
        printf "${RED}❌ [${app_name}]${NC} not found. Please download and install the app.\n"
    fi
}

start() {
    find_paddle_apps
    for app_entry in "${ALL_APPS_LIST[@]}"; do
        IFS="|" read -r app_name app_path script_after <<<"$app_entry"
        inject_dobby_hook "$app_name" "$app_path" "$script_after"
    done
}

printf "\n${GREEN}💉💉💉 dylib_dobby_hook Injector 🚀🚀🚀${NC}\n\n"
printf "${GREEN}🤖 Injection Start...${NC}\n\n"
start
