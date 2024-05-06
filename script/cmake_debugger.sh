current_path=$PWD

app_name="DevUtils"
#inject_bin=""

echo ">>>>>> app_name is ${app_name}"

dylib_name="dylib_dobby_hook"
prefix="lib"
insert_dylib="${current_path}/../tools/insert_dylib"


app_bundle_path="/Applications/${app_name}.app/Contents/MacOS"
app_bundle_framework="/Applications/${app_name}.app/Contents/Frameworks/"
echo ">>>>>> app_bundle_framework is ${app_bundle_framework}"

if [ ! -d "$app_bundle_framework" ]; then
  mkdir -p "$app_bundle_framework"
fi

if [ -n "$inject_bin" ]; then
    app_executable_path="$inject_bin"
else
    app_executable_path="${app_bundle_path}/${app_name}"
fi


app_executable_backup_path="${app_executable_path}_Backup"
echo ">>>>>> app_executable_path is ${app_executable_path}"

if [ -f "${insert_dylib}" ]; then
    cp -f "${insert_dylib}" "${app_bundle_path}/insert_dylib"
fi

if [ ! -f "$app_executable_backup_path" ];
then
    cp "$app_executable_path" "$app_executable_backup_path"
fi

cp -f "${current_path}/../release/libdobby.dylib" "${app_bundle_framework}"
"${app_bundle_path}/insert_dylib" --weak --all-yes "${current_path}/../release/${prefix}${dylib_name}.dylib" "$app_executable_backup_path" "$app_executable_path"
rm -rf "${app_bundle_path}/insert_dylib"
echo ">>>>>> hack [${app_name}] completed"


