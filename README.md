## About
[![Telegram](https://img.shields.io/badge/Join%20our%20Telegram-blue?logo=telegram)](https://t.me/dylib_dobby_hook_chat)

[English](https://github.com/marlkiller/dylib_dobby_hook/blob/master/README.md) | [中文](https://github.com/marlkiller/dylib_dobby_hook/blob/master/README.zh-CN.md) |[Others..TODO]()


This project is a macOS/IOS dylib project, aiming to enhance software through the use of the Hook framework.

Development Environment:

- macOS (SIP disabled & allow any source)
- Xcode 15.2 | CLion
- Hopper | IDA

Directory Structure:

1. dylib_dobby_hook: Source code
2. libs: Libraries that the project depends on
   - [tinyhook](https://github.com/Antibioticss/tinyhook)
3. release: Built product libraries
4. script:
   - auto_hack.sh: One-click script `sudo bash auto_hack.sh`
5. tools:
   - insert_dylib: Open-source static injection tool
   - dynamic_inject: Dynamic injection tool [SIP OFF]
   - [process_inject](https://github.com/marlkiller/process_inject): Process injection tool [SIP OFF]

## Feat

1. Cross-platform [intel/apple] HOOK
2. Integrated development and debugging environment with Xcode|CLion|VSCode
3. Signature code search

Check the full list of supported apps [here](./supported-apps.md).

## Usage

[download latest release](https://github.com/marlkiller/dylib_dobby_hook_private/releases/download/latest/dylib_dobby_hook.tar.gz)

```shell
tar -xzvf dylib_dobby_hook.tar.gz
cd script 
sudo bash auto_hack.sh
```

> **Tip:** For a more convenient experience, you can use our GUI Quick Injection App.  
> [Download AutoHackGUI](https://github.com/marlkiller/AutoHackGUI-Releases/releases/)

## Develop

### 0x0

The basic code has been completed. To be compatible with more app patches, the adapter pattern is used for extension.

### 0x1 Define Implementation Class (taking current XXX as an example)

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

#if defined(__arm64__) || defined(__aarch64__)
// do arm something..
#elif defined(__x86_64__)
// do x86 something..
#endif

return YES;
}
@end

```

### 0x2 Build & Inject

#### Build
We provide a unified build script that supports both **cmake** and **xcode** build systems, with configurable build type, Hikari support, and target OS.

```shell
# ./build.sh -s xcode -t Debug -h OFF -o mac
usage() {
  echo "Usage: $0 [-s cmake|xcode] [-t Debug|Release] [-h ON|OFF] [-o mac|ios]"
  echo "  -s  Build system: cmake (default) or xcode"
  echo "  -t  Build type: Debug or Release (default: Release)"
  echo "  -h  Enable Hikari: ON or OFF (default: OFF)"
  echo "  -o  Target OS: mac (default) or ios"
  exit 1
}
```

After compilation, you will obtain the patched dylib output under your specified build path.


#### Inject

Injection is separated into **macOS** and **iOS**.

```shell
# macOS
## Static Injection
cp -f source_bin source_bin_backup 
"${insert_dylib}" --weak --all-yes "${YOUR_BUILD_PATH}/libdylib_dobby_hook.dylib" "source_bin_backup" "source_bin"

## Dynamic Injection [SIP OFF]
./dynamic_inject "xxx.app" "${YOUR_BUILD_PATH}/libdylib_dobby_hook.dylib"

## Process Injection [SIP OFF]
./process_inject "$pid" "${YOUR_BUILD_PATH}/libdylib_dobby_hook.dylib"
```

```shell
# IOS
TODO
```

## Powered by

[![JetBrains logo.](https://resources.jetbrains.com/storage/products/company/brand/logos/jetbrains.svg)](https://jb.gg/OpenSource)

## WARN

For research and learning purposes only. Please do not use for illegal purposes.   
Note: If reprinted, please indicate the source (link to this post) and author information.

