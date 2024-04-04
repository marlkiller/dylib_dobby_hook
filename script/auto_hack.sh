# TODO 判断是否已经注入过

hack_app() {
    app_name="$1"
    app_path="$2"
    
    if [ -d "/Applications/${app_name}.app" ]; then
    
        version=$(defaults read "/Applications/${app_name}.app/Contents/Info.plist" CFBundleShortVersionString)
        bundle_id=$(defaults read "/Applications/${app_name}.app/Contents/Info.plist" CFBundleIdentifier)
        read -p "[${app_name} ${version} (${bundle_id})] 存在, 是否执行注入？ (Y/N): " user_input
        if [ "$user_input" = "Y" ] || [ "$user_input" = "y" ]; then
            echo ">>>>>> hack [${app_name}] starting"
            sh all_in_one.sh "$app_name" "$app_path"
        else
            echo ">>>>>> ignore [${app_name}]"
        fi
    else
        echo ">>>>>> ignore [${app_name}] ; app does not exist"
    fi

}


hack_app "DevUtils"
hack_app "TablePlus"
hack_app "Paste"
hack_app "Navicat Premium" "/Applications/Navicat Premium.app/Contents/Frameworks/EE.framework/Versions/A/EE"
hack_app "Transmit"
hack_app "AnyGo"
hack_app "Downie 4" "/Applications/Permute 3.app/Contents/Frameworks/Licensing.framework/Versions/A/Licensing"
hack_app "Permute 3" "/Applications/Permute 3.app/Contents/Frameworks/Licensing.framework/Versions/A/Licensing"

