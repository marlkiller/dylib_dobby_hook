current_path=$PWD
echo "当前路径：$current_path"

app_name="AirBuddy"

dylib_name="dylib_dobby_hook"
prefix="lib"

insert_dylib="${current_path}/../tools/insert_dylib"

BUILT_PRODUCTS_DIR="/Users/artemis/Library/Developer/Xcode/DerivedData/dylib_dobby_hook-gzfcyfsevajikobdprwgxscpqtly/Build/Products/Release"

app_bundle_path="/Applications/${app_name}.app/Contents/MacOS/"

cp -f "${insert_dylib}" "${app_bundle_path}/"   

app_bundle_framework="/Applications/${app_name}.app/Contents/Frameworks"
app_executable_path="${app_bundle_path}/${app_name}"
app_executable_backup_path="${app_executable_path}_Backup"




if [ ! -f "$app_executable_backup_path" ]; 
then
    cp "$app_executable_path" "$app_executable_backup_path"
fi



cp -R "${BUILT_PRODUCTS_DIR}/${prefix}${dylib_name}.dylib" ${app_bundle_framework}

cp -R "${BUILT_PRODUCTS_DIR}/libdobby.dylib" ${app_bundle_framework}

"${app_bundle_path}/insert_dylib" --weak --all-yes "@rpath/${prefix}${dylib_name}.dylib" "$app_executable_backup_path" "$app_executable_path"


