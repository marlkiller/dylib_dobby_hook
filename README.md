## About

该项目是一个 macOS dylib 项目，集成了 Dobby Hook 框架，旨在通过使用 Dobby Hook 框架对软件进行辅助增强。

开发环境:

- MacOS (关闭 SIP & 允许任何来源)
- xcode 15.2 | clion
- dobby
- insert_dylib
- hopper | ida

目录结构 :

1. dylib_dobby_hook: 源码
2. libs:  项目依赖的开源 dobby 库
3. release:  build 后的成品
4. script:
    - auto_hack.sh 静态注入 `sudo bash auto_hack.sh`
    - auto_dynamic_hack.sh 动态注入[SIP OFF] `sudo bash auto_dynamic_hack.sh`
5. tools: insert_dylib 开源注入工具

## Feat

1. 跨平台 HOOK
2. Xcode|Clion 集成开发调试环境
3. 特征码搜索

<details>
  <summary>点击这里展开/收起</summary>

| App             | version | x86 | arm | Download                                     | SIP | Author              |
|-----------------|---------|-----|-----|----------------------------------------------|-----|---------------------|
| TablePlus       | 6.*     | ✔   | ✔   | https://tableplus.com/                       |     |                     |
| DevUtils        | 1.*     | ✔   | ✔   | https://devutils.com/                        |     |                     |
| AirBuddy        | 2.*     | ✔   | ✔   | https://v2.airbuddy.app/download             |     |                     |
| Navicat Premium | 17.*    | ✔   | ✔   | App Store                                    |     |                     |
| Paste           | 4.*     | ✔   | ✔   | App Store                                    |     | Hokkaido            |
| Transmit        | 5.*     | ✔   | ✔   | https://panic.com/transmit/#download         |     |                     |
| AnyGo           | 7.*     | ✔   | ✔   | https://itoolab.com/gps-location-changer/    |     |                     |
| Downie          | 4.*     | ✔   | ✔   | https://software.charliemonroe.net/downie/   |     |                     |
| Permute         | 3.*     | ✔   | ✔   | https://software.charliemonroe.net/permute/  |     |                     |
| ProxyMan        | 5.      | ✔   | ✔   | https://proxyman.io/                         | ON  |                     |
| Movist Pro      | 2.*     | ✔   | ✔   | https://movistprime.com/                     |     |                     |
| Surge           | 5.8.*   | ✔   | ✔   | https://nssurge.com/                         | ON  |                     |
| Infuse          | 7.7.*   | ✔   | ✔   | App Store                                    |     |                     |
| MacUpdater      | 3.      | ✔   | ✔   | https://www.corecode.io/macupdater/#download |     |                     |
| CleanShotX      | 4.      | ✔   | ✔   | https://updates.getcleanshot.com/v3/         |     |                     |
| ForkLift        | 4.      | ✔   | ✔   | https://binarynights.com/                    | ON  |                     |
| IDA Pro         | 9.      | ✔   | ✔   | https://out5.hex-rays.com/beta90_6ba923/     |     | alula               |

</details>

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
#import "HackProtocol.h"


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
cp -f source_bin source_bin_backup 
"${insert_dylib}" --weak --all-yes "${YOUR_BUILD_PATH}/libdylib_dobby_hook.dylib" "source_bin_backup" "source_bin"
```

## Sponsor

[![JetBrains](jetbrains.svg)](https://www.jetbrains.com/?from=dylib_dobby_hook "JetBrains")

## Ref

1. [MacOS逆向] MacOS TablePlus dylib注入 HOOK x86/arm 双插
   完美破解 [https://www.52pojie.cn/thread-1739112-1-1.html](https://www.52pojie.cn/thread-1881366-1-1.html)
2. [C&C++ 原创] C++ 跨平台 内联汇编集成 (MacOS,Linux,Windows) https://www.52pojie.cn/thread-1653689-1-1.html
3. jmpews/Dobby https://github.com/jmpews/Dobby

## WARN

仅供研究学习使用，请勿用于非法用途  
注：若转载请注明来源（本贴地址）与作者信息。

