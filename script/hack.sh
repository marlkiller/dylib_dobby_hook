#!/bin/bash

current_path=$PWD
echo "✅ Current Path: $current_path"

app_name="DevUtils"
# The default is injected into the main program, if you need to customize, please edit the variable inject_bin, otherwise do not touch it
# inject_bin="/Applications/Navicat Premium.app/Contents/Frameworks/EE.framework/Versions/A/EE"
# inject_bin="/Applications/${app_name}.app/Contents/MacOS//${app_name}"

dylib_name="dylib_dobby_hook"
prefix="lib"
insert_dylib="${current_path}/../tools/insert_dylib"
chmod a+x ${insert_dylib}

BUILT_PRODUCTS_DIR="${current_path}/../release"

app_bundle_path="/Applications/${app_name}.app/Contents/MacOS"
app_bundle_framework="/Applications/${app_name}.app/Contents/Frameworks/"

if [ ! -d "$app_bundle_framework" ]; then
    mkdir -p "$app_bundle_framework"
fi

if [ -n "$inject_bin" ]; then
    app_executable_path="$inject_bin"
else
    app_executable_path="${app_bundle_path}/${app_name}"
fi
app_executable_backup_path="${app_executable_path}_Backup"

if [ ! -f "$app_executable_backup_path" ]; then
    cp "$app_executable_path" "$app_executable_backup_path"
fi

cp -f "${BUILT_PRODUCTS_DIR}/${prefix}${dylib_name}.dylib" "${app_bundle_framework}"

"${insert_dylib}" --weak --all-yes "@rpath/${prefix}${dylib_name}.dylib" "$app_executable_backup_path" "$app_executable_path"
