## About

xcode 开发 dylib , 基于跨平台的 dobby HOOK 框架来构建跨平台的通杀补丁.  
你妈再也不用担心你只能跑 Rosetta 了..

开发环境:

- MacOS (关闭 SIP)
- xcode 15.2
- dobby
- insert_dylib
- hopper | ida

目录结构 :

1. dylib_dobby_hook: 源码
2. libs:  项目依赖的开源 dobby 库
3. release:  build 后的成品
4. script:
    - hack.sh 自定义注入脚本 `sudo sh hack.sh`
    - auto_hack.sh 妹妹全自动注入脚本 `sudo sh auto_hack.sh`
5. tools: insert_dylib 开源注入工具

## Feat

1. 跨平台 HOOK
2. Xcode 集成开发调试环境
3. 特征码搜索

| App             | version | x86 | arm | Download                                    | remark                                                                                                     | Author              |
|-----------------|---------|-----|-----|---------------------------------------------|------------------------------------------------------------------------------------------------------------|---------------------|
| TablePlus       | 6.*     | ✔   | ✔   | https://tableplus.com/                      |                                                                                                            |                     |
| DevUtils        | 1.*     | ✔   | ✔   | https://devutils.com/                       |                                                                                                            |                     |
| AirBuddy        | 2.*     | ✔   | ✔   | https://v2.airbuddy.app/download            | inject_bin="/Applications/AirBuddy.app/Contents/Frameworks/LetsMove.framework/Versions/A/LetsMove"         |                     |
| Navicat Premium | 16.*    | ✔   | ✔   | App Store                                   | inject_bin="/Applications/Navicat Premium.app/Contents/Frameworks/EE.framework/Versions/A/EE"              | QiuChenlyOpenSource |
| Paste           | 4.1.3   | ✘   | ✔   | App Store                                   |                                                                                                            | LeeeMooo            |
| Transmit        | 5.*     | ✔   | ✔   | https://panic.com/transmit/#download        |                                                                                                            |                     |
| <s>AnyGo<s>     | 7.*     | ✔   | ✔   | https://itoolab.com/gps-location-changer/   | DMCA !!                                                                                                    |                     |
| Downie          | 4.*     | ✔   | ✔   | https://software.charliemonroe.net/downie/  | inject_bin="/Applications/Permute 3.app/Contents/Frameworks/Licensing.framework/Versions/A/Licensing"      |                     |
| Permute         | 3.*     | ✔   | ✔   | https://software.charliemonroe.net/permute/ | inject_bin="/Applications/Downie 4.app/Contents/Frameworks/Licensing.framework/Versions/A/Licensing"       |                     |
| ProxyMan        | 5.*     | ✔   | ✔   | https://proxyman.io/                        | inject_bin="/Applications/Proxyman.app/Contents/Frameworks/HexFiend.framework/Versions/A/HexFiend"         |                     |
| Movist Pro      | 2.*     | ✔   | ✔   | https://movistprime.com/                    | inject_bin="/Applications/Movist Pro.app/Contents/Frameworks/MediaKeyTap.framework/Versions/A/MediaKeyTap" |                     |

## Quick Start

```
git clone https://github.com/marlkiller/dylib_dobby_hook.git 
cd script 
sudo sh auto_hack.sh
```
## Develop

### 0x0

基础代码已经完成, 为了兼容更多的 app 补丁, 使用了适配器模式来进行扩展

### 0x1 定义实现类(以当前 XXX 为例)

```objective-c

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "HackProtocol.h"


@interface XXXHack : NSObject <HackProtocol>

@end

@implementation XXXHack

- (NSString *)getAppName {
    return @"com.dev.xxx";
}

- (NSString *)getSupportAppVersion {
    return @"1.0";
}


- (BOOL)hack {
        
#if defined(__arm64__) || defined(__aarch64__)
    // do arm something..
#elif defined(__x86_64__)
    // do x86 something..
#endif
    return YES;
}
@end

```

### 0x2 Build & 注入

编译后, 会得到一个我们的 dylib 补丁  
然后编写 shell 脚本,来注入

```shell
current_path=$PWD
echo "当前路径：$current_path"

app_name="DevUtils"

# 默认注入到主程序中，如果需要自定义，请编辑 inject_bin 变量，否则不要碰它
# inject_bin="/Applications/Navicat Premium.app/Contents/Frameworks/EE.framework/Versions/A/EE"
# inject_bin="/Applications/${app_name}.app/Contents/MacOS//${app_name}"

# release dylib
dylib_name="dylib_dobby_hook"
prefix="lib"
insert_dylib="${current_path}/../tools/insert_dylib"

BUILT_PRODUCTS_DIR="${current_path}/../release"

app_bundle_path="/Applications/${app_name}.app/Contents/MacOS/"
app_bundle_framework="/Applications/${app_name}.app/Contents/Frameworks"

if [ -n "$inject_bin" ]; then
    app_executable_path="$inject_bin"
else
    app_executable_path="${app_bundle_path}/${app_name}"
fi
app_executable_backup_path="${app_executable_path}_Backup"

# 注入前,备份程序
cp -f "${insert_dylib}" "${app_bundle_path}/"
if [ ! -f "$app_executable_backup_path" ]; 
then
    cp "$app_executable_path" "$app_executable_backup_path"
fi

# 复制 dylib 到目标程序下,执行注入
cp -f "${BUILT_PRODUCTS_DIR}/${prefix}${dylib_name}.dylib" "${app_bundle_framework}"
cp -f "${BUILT_PRODUCTS_DIR}/libdobby.dylib" "${app_bundle_framework}"

"${app_bundle_path}/insert_dylib" --weak --all-yes "@rpath/${prefix}${dylib_name}.dylib" "$app_executable_backup_path" "$app_executable_path"
```

## Ref

1. [MacOS逆向] MacOS TablePlus dylib注入 HOOK x86/arm 双插
   完美破解 [https://www.52pojie.cn/thread-1739112-1-1.html](https://www.52pojie.cn/thread-1881366-1-1.html)
2. [C&C++ 原创] C++ 跨平台 内联汇编集成 (MacOS,Linux,Windows) https://www.52pojie.cn/thread-1653689-1-1.html
3. jmpews/Dobby https://github.com/jmpews/Dobby

## WARN

仅供研究学习使用，请勿用于非法用途  
注：若转载请注明来源（本贴地址）与作者信息。

