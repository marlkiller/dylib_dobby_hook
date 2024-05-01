current_path=$PWD

# 参数1赋值给app_name
app_name=$1
if [ -n "$2" ]; then
    inject_bin=$2
fi
# TODO 判断参数数量

echo ">>>>>> app_name is ${app_name}"

dylib_name="dylib_dobby_hook"
prefix="lib"
insert_dylib="${current_path}/../tools/insert_dylib"

# 判断是否已经注入过，如果已经存在 libdylib_dobby_hook.dylib，则返回 0，表示已经注入过
check_dylib_exist() {
    local app_path="$1"
    if otool -L "$app_path" | grep -q "${dylib_name}"; then
        return 0
    fi
    return 1
}


BUILT_PRODUCTS_DIR="${current_path}/../release"

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




if check_dylib_exist "$app_executable_path"; then
    echo ">>>>>> 目标程序 [${app_executable_path}] 已经注入过, 即将覆盖"
fi

# if check_dylib_exist "$app_executable_path"; then
#     read -p "目标程序 [${app_executable_path}] 已经注入过, 是否覆盖？ (Y/N): " user_input
#     if [ "$user_input" != "Y" ] && [ "$user_input" != "y" ]; then
#         echo ">>>>>> ignore [${app_name}]"
#         exit 0
#     fi
# fi

app_executable_backup_path="${app_executable_path}_Backup"
echo ">>>>>> app_executable_path is ${app_executable_path}"


cp -f "${insert_dylib}" "${app_bundle_path}/insert_dylib"


if [ ! -f "$app_executable_backup_path" ];
then
    cp "$app_executable_path" "$app_executable_backup_path"
fi



cp -f "${BUILT_PRODUCTS_DIR}/${prefix}${dylib_name}.dylib" "${app_bundle_framework}"
cp -f "${BUILT_PRODUCTS_DIR}/libdobby.dylib" "${app_bundle_framework}"

"${app_bundle_path}/insert_dylib" --weak --all-yes "@rpath/${prefix}${dylib_name}.dylib" "$app_executable_backup_path" "$app_executable_path"

rm -rf "${app_bundle_path}/insert_dylib"

echo ">>>>>> hack [${app_name}] completed"


