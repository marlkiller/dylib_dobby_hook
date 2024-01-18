## 前记
xcode 开发 dylib , 基于跨平台的 dobby HOOK 框架来构建跨平台的通杀补丁.  
你妈再也不用担心你只能跑 Rosetta 了..  

开发环境: 
- xcode 15.2
- dobby
- insert_dylib
- hopper | ida

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
先根据 系统架构宏 写个判断  
```
#if defined(__arm64__) || defined(__aarch64__)
// 此处写 arm hook 代码

#elif defined(__x86_64__)
// 此处写 x86_64 hook 代码

#endif

```


关键 hook 函数,可以参考帖子(以 TabpePlus 该软件为例) :
[https://www.52pojie.cn/thread-1739112-1-1.html  
](https://www.52pojie.cn/thread-1881366-1-1.html)


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
### 定义一个全局的适配器工具类, 根据 appName 来获取对应的实现类,来执行 hack 操作


```
#import <Foundation/Foundation.h>
#import "Constant.h"
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import "HackProtocol.h"
#import <Cocoa/Cocoa.h>
#include <mach-o/arch.h>


@implementation Constant

static void __attribute__ ((constructor)) initialize(void){
    NSLog(@"Constant init");    

}
+ (void)initialize {
    if (self == [Constant class]) {
        NSBundle *app = [NSBundle mainBundle];
        currentAppName = [app bundleIdentifier];
        currentAppVersion = [app objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        currentAppCFBundleVersion = [app objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSLog(@"AppName is [%s],Version is [%s], myAppCFBundleVersion is [%s].", currentAppName.UTF8String, currentAppVersion.UTF8String, currentAppCFBundleVersion.UTF8String);
        NSLog(@"AppName Architecture: %@", [Constant getSystemArchitecture]);
        NSLog(@"AppName DEBUGGING : %d", [Constant isDebuggerAttached]);
    }
}
/**
 * App的唯一ID 用来过滤指定的App
 */
const NSString *currentAppName;
/**
 * app的版本号
 */
const NSString *currentAppVersion;
/**
 * 更精确的版本号 一般情况下不用到
 */
const NSString *currentAppCFBundleVersion;

+ (NSString *)getSystemArchitecture {
    const NXArchInfo *archInfo = NXGetLocalArchInfo();

    if (archInfo) {
        return [NSString stringWithUTF8String:archInfo->name];
    } else {
        return nil;
    }
}


+ (BOOL)isDebuggerAttached {
    BOOL isDebugging = NO;
    // 获取当前进程的信息
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    // 获取进程的环境变量
    NSDictionary *environment = [processInfo environment];
    // 检查环境变量中是否有调试器相关的标志
    if (environment != nil) {
        // 根据环境变量中是否包含特定的调试器标志来判断是否处于调试模式
        if (environment[@"DYLD_INSERT_LIBRARIES"] ||
            environment[@"MallocStackLogging"] ||
            environment[@"NSZombieEnabled"] ||
            environment[@"__XDEBUGGER_PRESENT"] != nil) {
            isDebugging = YES;
        }
    }
    return isDebugging;
}


+ (intptr_t)getBaseAddr:(uint32_t)index{
    BOOL isDebugging = [Constant isDebuggerAttached];
    if(isDebugging){
        // NSLog(@"The current app running with debugging");
        // 不知道为什么
        // 如果是调试模式, 计算地址不需要 + _dyld_get_image_vmaddr_slide,否则会出错
        return 0;

    }
    return _dyld_get_image_vmaddr_slide(index);
}


+ (NSArray<Class> *)getAllHackClasses {
    NSMutableArray<Class> *hackClasses = [NSMutableArray array];
    
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(NULL, 0);
    
    if (numClasses > 0) {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        
        for (int i = 0; i < numClasses; i++) {
            Class class = classes[i];
            
            if (class_conformsToProtocol(class, @protocol(HackProtocol))) {
                [hackClasses addObject:class];
            }
        }
        free(classes);
    }
    return hackClasses;
}


+ (void)doHack {
    NSArray<Class> *personClasses = [Constant getAllHackClasses];
    
    for (Class class in personClasses) {
        id<HackProtocol> it = [[class alloc] init];
        if ([currentAppName isEqualToString:[it getAppName]]) {
            if (![currentAppVersion hasPrefix:[it getSupportAppVersion]]){
                NSAlert *alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:@"OK"];
                alert.messageText =  [NSString stringWithFormat:@"Unsupported current appVersion !!\nSuppert appVersion: [%s]\nCurrent appVersion: [%s]",[it getSupportAppVersion].UTF8String, currentAppVersion.UTF8String];;
                [alert runModal];
                return;
            }            
            [it hack];
            return;
        }
    }
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    alert.messageText =  [NSString stringWithFormat:@"Unsupported current app: [%s]", currentAppName.UTF8String];;
    [alert runModal];
    
}
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



