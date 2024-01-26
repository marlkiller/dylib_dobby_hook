## 前记
xcode 开发 dylib , 基于跨平台的 dobby HOOK 框架来构建跨平台的通杀补丁.  
你妈再也不用担心你只能跑 Rosetta 了..  

开发环境: 
- xcode 15.2
- dobby
- insert_dylib
- hopper | ida

## Feat

1. 跨平台 HOOK
2. Xcode 集成开发调试环境
3. 特征码搜索

## 项目搭建

1. xcode 新建一个 MacOS > Library 项目

稍微做一些配置:
-- 关掉代码优化: Optimization Level -> None 
这个东西开了的话 hook 或者 写内联汇编会出问题

-- 跨平台构建打开: Build Active Architecture Only > No 
这个东西开了的话, m系列代码 编译出来的 x86/arm 都可以用,跨平台必备

2. 项目中引入 dobby 动态库 < libdobby.dylib >, 并且 引入 dobby.h 头文件

3. 编写 hook 代码


## hook 代码

关键 hook 函数,可以参考帖子(以 TabpePlus 该软件为例) :
[https://www.52pojie.cn/thread-1739112-1-1.html  
](https://www.52pojie.cn/thread-1881366-1-1.html)

### 代码优化

基础代码已经完成, 为了兼容更多的 app 补丁, 我们对代码做一些重构优化。
使用适配器模式来扩展  

### 定义 Hack 接口
接口定义几个方法, 比如教研app名称/版本号,以及执行 hack
```
@protocol HackProtocol

- (NSString *)getAppName;
- (NSString *)getSupportAppVersion;
- (BOOL)hack;
@end
```

### 定义实现类(已当前 TablePlus 为例)

```
#import <Foundation/Foundation.h>
#import "TablePlusHack.h"
#import <objc/runtime.h>

@implementation TablePlusHack


- (NSString *)getAppName {
    return @"com.tinyapp.TablePlus";
}

- (NSString *)getSupportAppVersion {    
    return @"5.8.2";
}


#if defined(__arm64__) || defined(__aarch64__)


- (BOOL)hack {
    // do arm something..
    return YES;
}
    
#elif defined(__x86_64__)

- (BOOL)hack {
    // do x86 something..
    return YES;
}

#endif
@end
```


### dylib 入口函数

```
+ (void) load {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Please confirm if the app has been backed up.\nIf there are any issues, please restore it yourself!"];
    [alert addButtonWithTitle:@"Confirm"];
    [alert addButtonWithTitle:@"Cancel"];
    NSInteger response = [alert runModal];
    if (response == NSAlertFirstButtonReturn) {
        [Constant doHack];
    } else {
        return;
    }
}
```

## build 注入

编译后, 会得到一个我们的 dylib 补丁  
然后编写 shell 脚本,来注入  

```shell
current_path=$PWD
echo "当前路径：$current_path"

app_name="TablePlus"

dylib_name="dylib_dobby_hook"
prefix="lib"

insert_dylib="${current_path}/../tools/insert_dylib"

# 我们的 release 补丁路径
BUILT_PRODUCTS_DIR="${current_path}/../Release"

app_bundle_path="/Applications/${app_name}.app/Contents/MacOS/"

cp -f "${insert_dylib}" "${app_bundle_path}/"   

app_bundle_framework="/Applications/${app_name}.app/Contents/Frameworks"
app_executable_path="${app_bundle_path}/${app_name}"
app_executable_backup_path="${app_executable_path}_Backup"

# 第一次注入的之后备份源文件
if [ ! -f "$app_executable_backup_path" ]; 
then
    cp "$app_executable_path" "$app_executable_backup_path"
fi


# 把补丁 与 补丁依赖的 dobby hook 框架都复制到目标程序下
cp -R "${BUILT_PRODUCTS_DIR}/${prefix}${dylib_name}.dylib" ${app_bundle_framework}
cp -R "${BUILT_PRODUCTS_DIR}/libdobby.dylib" ${app_bundle_framework}

# 用 insert_dylib 来向目标程序注入
"${app_bundle_path}/insert_dylib" --weak --all-yes "@rpath/${prefix}${dylib_name}.dylib" "$app_executable_backup_path" "$app_executable_path"

```


至此,代码重构优化结束,如果补丁要支持新的 app ,只需要添加一个 HackProtocol 实现类即可,  
对别的地方的代码, 零入侵.


## Ref
1. [MacOS逆向] MacOS TablePlus dylib注入 HOOK x86/arm 双插 完美破解 [https://www.52pojie.cn/thread-1739112-1-1.html](https://www.52pojie.cn/thread-1881366-1-1.html)
2. [C&C++ 原创] C++ 跨平台 内联汇编集成 (MacOS,Linux,Windows) https://www.52pojie.cn/thread-1653689-1-1.html
3. jmpews/Dobby https://github.com/jmpews/Dobby

## Release

项目已经打包 github,可以直接用 xcode 打开 :
https://github.com/marlkiller/dylib_dobby_hook  

目录:
1. libs:  项目依赖的开源 dobby 库
2. release:  build 后的成品
3. script:  里面有个 hack.sh, 可以直接sudo sh 执行一键注入脚本
4. tools: insert_dylib 开源注入工具




