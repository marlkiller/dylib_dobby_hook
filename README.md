## About

[English](https://github.com/marlkiller/dylib_dobby_hook/blob/master/README.md) | [中文](https://github.com/marlkiller/dylib_dobby_hook/blob/master/README.zh-CN.md) |[Others..TODO]()


This project is a macOS dylib project, aiming to enhance software through the use of the Hook framework.

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
   - process_inject: Process injection tool [BETA][SIP OFF]

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

### 0x2 Build & Inject

After compilation, we will get our dylib patch.
Then write a shell script to inject.

```shell

## Static Injection
cp -f source_bin source_bin_backup 
"${insert_dylib}" --weak --all-yes "${YOUR_BUILD_PATH}/libdylib_dobby_hook.dylib" "source_bin_backup" "source_bin"

## Dynamic Injection [SIP OFF]
./dynamic_inject "xxx.app" "${YOUR_BUILD_PATH}/libdylib_dobby_hook.dylib"

## Process Injection [SIP OFF]
./process_inject "$pid" "${YOUR_BUILD_PATH}/libdylib_dobby_hook.dylib"
```


## Sponsor

[![JetBrains](jetbrains.svg)](https://www.jetbrains.com/?from=dylib_dobby_hook "JetBrains")

## WARN

For research and learning purposes only. Please do not use for illegal purposes.   
Note: If reprinted, please indicate the source (link to this post) and author information.

