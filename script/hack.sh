
app_name="AirBuddy"

dylib_name="integration_hack"
prefix="lib"

insert_dylib="/Users/voidm/Documents/develop/workSpace/xcode/macos/integration_hack/tools/insert_dylib"


app_bundle_path="/Applications/${app_name}.app/Contents/MacOS/"

cp -f "${insert_dylib}" "${app_bundle_path}/"   

app_bundle_framework="/Applications/${app_name}.app/Contents/Frameworks"
app_executable_path="${app_bundle_path}/${app_name}"
app_executable_backup_path="${app_executable_path}_Backup"




if [ ! -f "$app_executable_backup_path" ]; 
then
    cp "$app_executable_path" "$app_executable_backup_path"
fi

cp -R "/Users/voidm/Library/Developer/Xcode/DerivedData/integration_hack-drxdrffvpcycxsfgqhstrfwogfwl/Build/Products/Debug/${prefix}${dylib_name}.dylib" ${app_bundle_framework}


"${app_bundle_path}/insert_dylib" --weak --all-yes "@rpath/${prefix}${dylib_name}.dylib" "$app_executable_backup_path" "$app_executable_path"


