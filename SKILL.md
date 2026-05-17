---
name: dylib-dobby-hook
description: Work on this dylib_dobby_hook_private project. Use when adding or editing macOS/iOS dylib injection hooks, creating HackProtocolDefault subclasses, patching bytes with write_mem, hooking C functions or raw addresses with tiny_hook, resolving symbols with symtbl_solve/symexp_solve, or hooking Objective-C methods with MemoryUtils hookInstanceMethod/hookClassMethod/replaceInstanceMethod/replaceClassMethod.
---

# Dylib Dobby Hook

项目入口：`+[dylib_dobby_hook load] -> [Constant doHack]`。扩展方式是新增或修改 `HackProtocolDefault` 子类；`doHack` 会枚举子类，先用类方法 `+shouldInject:` 和 `+getSupportAppVersion` 匹配，命中后才创建实例并调用 `hack`。

常看文件：

- `dylib_dobby_hook/tinyhook.h`: `tiny_hook`, `symtbl_solve`, `symexp_solve`, `write_mem`, `ocrt_hook`
- `dylib_dobby_hook/common/MemoryUtils.h`: OC hook、特征码搜索、偏移换算、ivar/msgSend 工具
- `dylib_dobby_hook/common/CommonRetOC.m`: `ret0`, `ret1`, `ret` 和通用 CloudKit/Keychain/SecCode hook
- `dylib_dobby_hook/mac/apps/*.m`, `dylib_dobby_hook/ios/apps/*.m`: 现有 app hook 示例

## 新增 App Hook

macOS app 放 `dylib_dobby_hook/mac/apps/XXXHack.m`，iOS app 放 `dylib_dobby_hook/ios/apps/XXXHack.m`。

```objective-c
#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import "HackProtocolDefault.h"
#import "common_ret.h"

@interface XXXHack : HackProtocolDefault
@end

@implementation XXXHack

+ (NSString *)getAppName {
    return @"com.example.app";
}

+ (NSString *)getSupportAppVersion {
    return @"1."; // 用版本前缀；不限制时返回 @""
}

- (BOOL)hack {
#if defined(__arm64__) || defined(__aarch64__)
    // arm64 hook/patch
#elif defined(__x86_64__)
    // x86_64 hook/patch
#endif
    return YES;
}

@end
```

`+shouldInject:` 默认按 bundle id 前缀匹配。框架型/base hook 可重写，例如检测某个 image 是否加载：

```objective-c
+ (BOOL)shouldInject:(NSString *)target {
    return [MemoryUtils indexForImageWithName:@"Paddle"] > 0;
}
```

## tinyhook: 已知 C 函数

替换系统 C 函数或已拿到函数指针的目标。需要调用原函数时保存 `orig_xxx`，不需要时传 `NULL`。

```objective-c
static int (*orig_ptrace)(int request, pid_t pid, caddr_t addr, int data);

static int hk_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    NSLogger(@"called hk_ptrace request=%d", request);
    if (request == PT_DENY_ATTACH) return 0;
    return orig_ptrace ? orig_ptrace(request, pid, addr, data) : 0;
}

- (BOOL)hack {
    tiny_hook((void *)ptrace, (void *)hk_ptrace, (void *)&orig_ptrace);
    return YES;
}
```

## tinyhook: 某个函数地址

适合 IDA/Hopper 已确认静态地址/offset，或通过 `MemoryUtils` 换算出来的地址。替换函数签名必须和原函数 ABI 兼容。

```objective-c
static int (*orig_check)(void);

static int hk_check(void) {
    NSLogger(@"called hk_check");
    return 1;
}

- (BOOL)hack {
    // 方式 1: IDA/Hopper 看到的是静态 VA，如 0x100123456。
    // 运行时地址 = 静态 VA + 当前 image 的 ASLR slide。
    int image = [MemoryUtils indexForImageWithName:@"Target"];
    uintptr_t staticVA = 0x100123456;
    uintptr_t runtimeAddr = staticVA + _dyld_get_image_vmaddr_slide(image);

    void *addr = (void *)runtimeAddr;
    tiny_hook(addr, (void *)hk_check, (void *)&orig_check);
    return YES;
}
```

项目里已有封装，能少写就直接用：

```objective-c
- (BOOL)hack {
    // 方式 2: 传 IDA/Hopper 里的静态 VA，内部会加 _dyld_get_image_vmaddr_slide(image)。
    uintptr_t addr = [MemoryUtils getPtrFromAddress:@"/Contents/MacOS/Target"
                              targetFunctionAddress:0x100123456];
    if (!addr) return NO;
    tiny_hook((void *)addr, (void *)hk_check, (void *)&orig_check);
    return YES;
}
```

如果拿到的是 Mach-O 文件里的 global/file offset，优先用 `getPtrFromGlobalOffset`，它会处理 fat binary 当前架构 slice 的 `fileOffset`：

```objective-c
- (BOOL)hack {
    // 例: IDA/Hopper 或特征码定位到的文件全局 offset。
    uintptr_t globalOffset = 0x123456;
    uintptr_t addr = [MemoryUtils getPtrFromGlobalOffset:@"/Contents/MacOS/Target"
                                         globalFunOffset:globalOffset];
    if (!addr) return NO;
    tiny_hook((void *)addr, (void *)hk_check, (void *)&orig_check);
    return YES;
}
```

如果只是让函数返回 true/false，可直接用 `common_ret.m` 里的通用函数：

```objective-c
tiny_hook((void *)targetAddr, (void *)ret1, NULL);
tiny_hook((void *)targetAddr, (void *)ret0, NULL);
```

## tinyhook: 符号名

已知符号时优先用 `symtbl_solve` 或 `symexp_solve`，少依赖硬编码偏移。

```objective-c
static int (*orig_status)(void);

static int hk_status(void) {
    NSLogger(@"called hk_status");
    return 9999;
}

- (BOOL)hack {
    int image = [MemoryUtils indexForImageWithName:@"Transmit"];
    void *addr = symtbl_solve(image, "_TRTrialStatus");
    NSLogger(@"_TRTrialStatus = %p", addr);
    if (!addr) return NO;
    tiny_hook(addr, (void *)hk_status, (void *)&orig_status);
    return YES;
}
```

## tinyhook: 特征码地址

符号被 strip 时，用特征码找函数地址。注意区分架构。

```objective-c
- (BOOL)hack {
#if defined(__arm64__) || defined(__aarch64__)
    NSString *pattern = @"28 FC 7E D3 69 FC 7E D3 1F 0D 00 F1";
#elif defined(__x86_64__)
    NSString *pattern = @"48 89 F0 48 C1 E8 3E 48 83 F8 03";
#endif

    NSNumber *ptr = [MemoryUtils getPtrFromMachineCode:@"/Contents/MacOS/Target"
                                           machineCode:pattern];
    if (!ptr) return NO;
    tiny_hook((void *)[ptr unsignedIntegerValue], (void *)ret1, NULL);
    return YES;
}
```

多个命中：

```objective-c
[MemoryUtils hookWithMachineCode:@"/Contents/MacOS/Target"
                     machineCode:pattern
                        fake_func:(void *)ret
                            count:2];
```

## OC Method Hook

ObjC/Swift 暴露到 runtime 的方法，优先用 `MemoryUtils hookInstanceMethod` / `hookClassMethod`。替换方法写在当前 Hack 类里。

```objective-c
static IMP orig_viewDidLoad;

- (void)hk_viewDidLoad {
    NSLogger(@"called hk_viewDidLoad self=%@", self);
    if (orig_viewDidLoad) {
        ((void (*)(id, SEL))orig_viewDidLoad)(self, _cmd);
    }
}

- (BOOL)hack {
    Class cls = objc_getClass("TargetModule.ViewController");
    if (!cls) return NO;

    orig_viewDidLoad = [MemoryUtils hookInstanceMethod:cls
                                      originalSelector:NSSelectorFromString(@"viewDidLoad")
                                         swizzledClass:[self class]
                                      swizzledSelector:NSSelectorFromString(@"hk_viewDidLoad")];
    return YES;
}
```

类方法示例：

```objective-c
[MemoryUtils hookClassMethod:NSClassFromString(@"CKContainer")
            originalSelector:NSSelectorFromString(@"defaultContainer")
               swizzledClass:[self class]
            swizzledSelector:@selector(hook_defaultContainer)];
```

如果 OC hook 递归，改用 method IMP + `tiny_hook`：

```objective-c
static BOOL (*orig_activated)(id self, SEL _cmd);

static BOOL hk_activated(id self, SEL _cmd) {
    NSLogger(@"called hk_activated");
    return YES;
}

- (BOOL)hack {
    Method m = class_getInstanceMethod(objc_getClass("PADProduct"), NSSelectorFromString(@"activated"));
    if (!m) return NO;
    tiny_hook((void *)method_getImplementation(m), (void *)hk_activated, (void *)&orig_activated);
    return YES;
}
```

## 通用 CloudKit/Keychain/SecCode Hook

这些通用方法在 `CommonRetOC.m`，`HackProtocolDefault` 继承自它，所以 app hook 里可直接调用。

CloudKit/iCloud:

```objective-c
- (BOOL)hack {
    [self hook_AllCloudKit]; // mock CKContainer / NSUbiquitousKeyValueStore
    return YES;
}
```

Keychain:

```objective-c
- (BOOL)hack {
    [self hook_AllSecItem]; // hook SecItemAdd/Update/Delete/CopyMatching
    return YES;
}
```

SecCode 签名校验:

```objective-c
- (BOOL)hack {
    [self hook_AllSecCode:@"TEAMID1234"]; // 伪装/替换目标 TeamIdentifier
    return YES;
}
```

## 直接 Patch

只在指令很短、地址和架构都确认时使用 `write_mem`。

```objective-c
#if defined(__arm64__) || defined(__aarch64__)
uint8_t patch[] = {0x20, 0x00, 0x80, 0xD2}; // mov x0, #1
#elif defined(__x86_64__)
uint8_t patch[] = {0xB8, 0x01, 0x00, 0x00, 0x00}; // mov eax, 1
#endif

write_mem((void *)targetAddr, patch, sizeof(patch));
```

## 习惯

- 改动尽量只碰一个 app/helper hook 文件。
- hook 前检查 class/symbol/address 是否为 `nil`/`NULL`。
- C 函数、IMP、block completion 的签名必须匹配原 ABI。
- 静态偏移容易随版本失效；优先符号或特征码，并用 `getSupportAppVersion` 收窄版本。
- 用 `NSLogger` 打印关键 image、地址、分支和返回值，方便注入进程里排查。
