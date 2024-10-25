#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'


force_flag=false

if [[ "$@" =~ "-f" ]]; then
    force_flag=true
fi

PARENT_DIR=$(dirname "$(pwd)")
DYLIB_PATH="$PARENT_DIR/release/libdylib_dobby_hook.dylib"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}❌ Error: This script must be run as root. Exiting.${NC}"
    exit 1
fi

if [ ! -f "$DYLIB_PATH" ]; then
    echo -e "${RED}❌ Error: $DYLIB_PATH not found. Please build the project first.${NC}"
    exit 1
fi


ALL_APPS_LIST=(
    "DevUtils"
    "TablePlus|/Applications/TablePlus.app/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle"
    "Paste"
    "Navicat Premium|Contents/Frameworks/EE.framework/Versions/A/EE"
    "Transmit"
    #"AnyGo"
    "Shottr"
    "Infuse|Contents/Frameworks/Differentiator.framework/Versions/A/Differentiator"
    "MacUpdater|Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle"
    "CleanShot X|Contents/Frameworks/LetsMove.framework/Versions/A/LetsMove"
    "iStat Menus|Contents/Frameworks/Paddle.framework/Versions/A/Paddle"
    "Alfred 5|Contents/Preferences/Alfred Preferences.app/Contents/MacOS/Alfred Preferences"
    "AirBuddy|Contents/Frameworks/Paddle.framework/Versions/A/Paddle|apps/airbuddy_hack.sh"

    ## paddle:Movist Pro/Downie 4/Fork/BetterMouse/MindMac/Permute 3/AirBuddy
    #"xx|/Applications/xx.app/Contents/Frameworks/Paddle.framework/Versions/A/Paddle"

    ## fixed with helper
    "IDA Professional 9.0|Contents/Frameworks/QtDBus.framework/Versions/5/QtDBus|apps/ida_hack.sh"
    "ForkLift|Contents/Frameworks/UniversalDetector.framework/Versions/A/UniversalDetector|apps/fix_helper_and_inject.sh|com.binarynights.ForkLiftHelper"
    "Proxyman|Contents/Frameworks/HexFiend.framework/Versions/A/HexFiend|apps/fix_helper.sh|com.proxyman.NSProxy.HelperTool"
    #"Surge|/Applications/Surge.app/Contents/Frameworks/MMMarkdown.framework/Versions/A/MMMarkdown|apps/surge_hack.sh"
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
    inject_path="$2"
    script_after="$3"
    helper_name="$4"
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
            bash all_in_one.sh "$app_name" "$inject_path"
            if [ -n "$script_after" ]; then
                bash "$script_after" "$app_name" "$helper_name"
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
    processed_apps=()
    for app_entry in "${ALL_APPS_LIST[@]}"; do
        IFS="|" read -r app_name inject_path script_after helper_name<<<"$app_entry"
        # If inject_path is not provided, assign the default path.
        if [[ " ${processed_apps[*]} " =~ " ${app_name} " ]]; then
            printf "${YELLOW}⚠️  Skipping duplicate : ${GREEN}%s${NC}\n" "$app_name"
            continue
        fi
        processed_apps+=("$app_name")
        if [[ -z "$inject_path" ]]; then
            inject_path="/Applications/$app_name.app/Contents/MacOS/$app_name"
        elif [[ ! "$inject_path" = /* ]]; then
            # If inject_path is relative, prefix it with `/Applications/$app_name.app/`.
            inject_path="/Applications/$app_name.app/$inject_path"
        fi
        inject_dobby_hook "$app_name" "$inject_path" "$script_after" "$helper_name"
    done
}

printf "\n${GREEN}💉💉💉 dylib_dobby_hook Injector 🚀🚀🚀${NC}\n\n"
printf "${GREEN}🤖 Injection Start...${NC}\n\n"
start
