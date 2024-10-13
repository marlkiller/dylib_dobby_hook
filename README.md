## About

[English](https://github.com/marlkiller/dylib_dobby_hook/blob/master/README.md) | [中文](https://github.com/marlkiller/dylib_dobby_hook/blob/master/README.zh-CN.md) |[Others..TODO]()


This project is a macOS dylib project that integrates the Dobby Hook framework, aiming to enhance software through the use of the Dobby Hook framework.

Development Environment:

- macOS (SIP disabled & allow any source)
- Xcode 15.2 | CLion
- Hopper | IDA

Directory Structure:

1. dylib_dobby_hook: Source code
2. libs: Libraries that the project depends on
3. release: Built product libraries
4. script:
   - auto_hack.sh: One-click script `sudo bash auto_hack.sh`
5. tools:
   - insert_dylib: Open-source static injection tool
   - dynamic_inject: Dynamic injection tool [SIP OFF]
   - process_inject: Process injection tool [BETA][SIP OFF]

## Feat

1. Cross-platform [intel/apple] HOOK
2. Integrated development and debugging environment with Xcode|CLion
3. Signature code search

<details>
  <summary>Click here to expand/collapse</summary>

| App             | version | x86 | arm | Download                                     | SIP | Author              |
|-----------------|---------|-----|-----|----------------------------------------------|-----|---------------------|
| TablePlus       | 6.*     | ✔   | ✔   | https://tableplus.com/                       |     |                     |
| DevUtils        | 1.*     | ✔   | ✔   | https://devutils.com/                        |     |                     |
| AirBuddy        | 2.*     | ✔   | ✔   | https://v2.airbuddy.app/download             |     |                     |
| Navicat Premium | 17.*    | ✔   | ✔   | App Store                                    |     |                     |
| Paste           | 4.*     | ✔   | ✔   | App Store                                    |     | Hokkaido            |
| iStat Menus     | 7.*     | ✔   | ✔   | https://bjango.com/mac/istatmenus/           |     | Hokkaido            |
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


### 0x3 Resigning
```shell
sudo codesign -f -s - --all-architectures --deep "/Applications/xxx.app"
```

## Sponsor

[![JetBrains](jetbrains.svg)](https://www.jetbrains.com/?from=dylib_dobby_hook "JetBrains")

## WARN

For research and learning purposes only. Please do not use for illegal purposes.   
Note: If reprinted, please indicate the source (link to this post) and author information.

