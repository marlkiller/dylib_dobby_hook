## About

[English](https://github.com/marlkiller/dylib_dobby_hook/blob/master/README.md) | [中文](https://github.com/marlkiller/dylib_dobby_hook/blob/master/README.zh-CN.md) |[Others..TODO]()


该项目是一个 macOS dylib 项目，旨在通过 Hook 对软件进行辅助增强。

开发环境:

- macOS (关闭 SIP & 允许任何来源)
- Xcode 15.2 | CLion
- Hopper | IDA

目录结构 :

1. dylib_dobby_hook: 源码
2. libs: 项目依赖的库
   - [tinyhook](https://github.com/Antibioticss/tinyhook)
3. release: build 后的成品库
4. script:
    - auto_hack.sh: 一键脚本 `sudo bash auto_hack.sh`
5. tools: 
    - insert_dylib: 开源静态注入工具
    - dynamic_inject: 动态注入工具 [SIP OFF]
    - process_inject: 进程注入工具 [测试版][SIP OFF]

## Feat

1. 跨平台 [intel/apple] HOOK
2. Xcode|Clion|VSCode 集成开发调试环境
3. 特征码搜索

查看受支持应用程序的完整列表 [here](./supported-apps.md).

## Usage

[download latest release](https://github.com/marlkiller/dylib_dobby_hook/releases/download/latest/dylib_dobby_hook.tar.gz)

```shell
tar -xzvf dylib_dobby_hook.tar.gz
cd script 
sudo bash auto_hack.sh
```

## Develop

### 0x0

基础代码已经完成, 为了兼容更多的 app 补丁, 使用了适配器模式来进行扩展

### 0x1 定义实现类(以当前 XXX 为例)

```objective-c

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "HackProtocolDefault.h"


@interface XXXHack : HackProtocolDefault

@end

@implementation XXXHack

- (NSString *)getAppName {
return @"com.dev.xxx";
}

- (NSString *)getSupportAppVersion {
return @"1.0";
}


- (BOOL)hack {

#if
defined(__arm64__) || defined(__aarch64__)
// do arm something..
#elif
defined(__x86_64__)
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

## 静态注入
cp -f source_bin source_bin_backup 
"${insert_dylib}" --weak --all-yes "${YOUR_BUILD_PATH}/libdylib_dobby_hook.dylib" "source_bin_backup" "source_bin"

## 动态注入 [SIP OFF]
./dynamic_inject "xxx.app" "${YOUR_BUILD_PATH}/libdylib_dobby_hook.dylib"

## 进程注入 [SIP OFF]
./process_inject "$pid" "${YOUR_BUILD_PATH}/libdylib_dobby_hook.dylib"
```


## Sponsor

[![JetBrains](jetbrains.svg)](https://www.jetbrains.com/?from=dylib_dobby_hook "JetBrains")

## WARN

仅供研究学习使用，请勿用于非法用途  
注：若转载请注明来源（本贴地址）与作者信息。

