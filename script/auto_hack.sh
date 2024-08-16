

force_flag=false
# 判断脚本是否有 -f 参数
if [[ "$@" =~ "-f" ]]; then
    force_flag=true
fi


hack_app() {
    
    echo "=========================================================="
    app_name="$1"
    app_path="$2"
    script_after="$3"
    
    if [ -d "/Applications/${app_name}.app" ]; then
    
        version=$(defaults read "/Applications/${app_name}.app/Contents/Info.plist" CFBundleShortVersionString)
        bundle_id=$(defaults read "/Applications/${app_name}.app/Contents/Info.plist" CFBundleIdentifier)
        if [ "$force_flag" = true ]; then
            user_input="Y"
        else
            read -p "[${app_name} ${version} (${bundle_id})] 存在, 是否执行注入？ (Y/N): " user_input  
        fi
        
        if [ "$user_input" = "Y" ] || [ "$user_input" = "y" ]; then
            echo ">>>>>> hack [${app_name}] starting"
            sh all_in_one.sh "$app_name" "$app_path"
            
            if [ -n "$script_after" ]; then
              sh "$script_after"
            fi
        else
            echo ">>>>>> ignore [${app_name}]"
        fi
    else
        echo ">>>>>> ignore [${app_name}] ; app does not exist"
    fi

}


hack_app "DevUtils"
hack_app "TablePlus" "/Applications/TablePlus.app/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle"
hack_app "Paste"
hack_app "Navicat Premium" "/Applications/Navicat Premium.app/Contents/Frameworks/EE.framework/Versions/A/EE"
hack_app "Transmit"
# hack_app "AnyGo"
hack_app "Downie 4" "/Applications/Downie 4.app/Contents/Frameworks/Licensing.framework/Versions/A/Licensing"
hack_app "Permute 3" "/Applications/Permute 3.app/Contents/Frameworks/Licensing.framework/Versions/A/Licensing"
hack_app "Proxyman" "/Applications/Proxyman.app/Contents/Frameworks/HexFiend.framework/Versions/A/HexFiend"
hack_app "Movist Pro" "/Applications/Movist Pro.app/Contents/Frameworks/MediaKeyTap.framework/Versions/A/MediaKeyTap"
hack_app "AirBuddy" "/Applications/AirBuddy.app/Contents/Frameworks/LetsMove.framework/Versions/A/LetsMove"
hack_app "Infuse" "/Applications/Infuse.app/Contents/Frameworks/Differentiator.framework/Versions/A/Differentiator"
hack_app "MacUpdater" "/Applications/MacUpdater.app/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle"
hack_app "CleanShot X" "/Applications/CleanShot X.app/Contents/Frameworks/LetsMove.framework/Versions/A/LetsMove"


# fixed with helper
hack_app "IDA Professional 9.0" "/Applications/IDA Professional 9.0.app/Contents/Frameworks/QtDBus.framework/Versions/5/QtDBus" "apps/ida_hack.sh"
hack_app "ForkLift" "/Applications/ForkLift.app/Contents/Frameworks/UniversalDetector.framework/Versions/A/UniversalDetector" "apps/forklift_hack.sh"
# hack_app "Surge" "/Applications/Surge.app/Contents/Frameworks/MMMarkdown.framework/Versions/A/MMMarkdown" "apps/surge_hack.sh"



 
