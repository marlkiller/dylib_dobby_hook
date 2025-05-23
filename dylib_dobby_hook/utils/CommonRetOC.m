//
//  CommonRetOC.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/27.
//

#import <Foundation/Foundation.h>
#import "CommonRetOC.h"
#import <CloudKit/CloudKit.h>
#import "MockCKContainer.h"
#import "common_ret.h"
#import "Logger.h"

@implementation CommonRetOC

- (void)ret {
    NSLogger(@"called - ret");
}
- (void)ret_ {
    NSLogger(@"called - ret_");
}
- (void)ret__ {
    NSLogger(@"called - ret__");
}

- (int)ret1 {
    NSLogger(@"called - ret1");
    return 1;
}
- (int)ret0 {
    NSLogger(@"called - ret0");
    return 0;
}
+ (int)ret1 {
    NSLogger(@"called + ret1");
    return 1;
}
+ (int)ret0 {
    NSLogger(@"called + ret0");
    return 0;
}
+ (void)ret {
    NSLogger(@"called + ret");
}


- (NSString *)getAppName { 
    return @"";
}

- (NSString *)getSupportAppVersion { 
    return @"";
}



- (BOOL)shouldInject:(NSString *)target {
    NSString *appName = [self getAppName];
    return [target hasPrefix:appName];
}



- (BOOL)hack { 
    return NO;
}





+ (id)hook_defaultStore{
    NSLogger(@"hook_defaultStore");
    // return [NSUserDefaults standardUserDefaults];
    return NULL;
}


- (id) hook_ubiquityIdentityToken {
    NSLogger(@"hook_ubiquityIdentityToken");
    return NULL;
}

- (id)hook_URLForUbiquityContainerIdentifier:(nullable NSString *)containerIdentifier{
    NSLogger(@"hook_URLForUbiquityContainerIdentifier containerIdentifier = %@",containerIdentifier);
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *url = [[defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    url = [url URLByAppendingPathComponent:containerIdentifier];
    
    BOOL isDirectory;
    if (![defaultManager fileExistsAtPath:[url path] isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        BOOL success = [defaultManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            NSLogger(@"Failed to create directory: %@", error.localizedDescription);
        }
    } else {
        NSLogger(@"Directory already exists.");
    }
    return url;
}


+ (id)hook_containerWithIdentifier:identifier {
    NSLogger(@"hook_containerWithIdentifier identifier = %@",identifier);
    // [CKContainer containerWithIdentifier:identifier];
    return [MockCKContainer containerWithIdentifier:identifier];

}
+ (id)hook_defaultContainer {
    NSLogger(@"hook_defaultContainer");
    // [CKContainer defaultContainer];
    return [MockCKContainer defaultContainer];

}


- (void)hook_AllSecItem{
    NSLogger(@"hook_AllSecItem");
    
//    FIXME: 有些 app tiny_hook 第三个参数不能传 null, 否则奔溃, 不知道为什么;
//    VM Region Info: 0 is not in any region.  Bytes before following region: 4438192128
//          REGION TYPE                    START - END         [ VSIZE] PRT/MAX SHRMOD  REGION DETAIL
//          UNUSED SPACE AT START
//    --->
//          __TEXT                      108897000-10a4f2000    [ 28.4M] r-x/r-x SM=COW  /Applications/Navicat Premium.app/Contents/MacOS/Navicat Premium
//
//    Thread 0 Crashed::  Dispatch queue: com.apple.main-thread
//    0   Security                              0x7ff814322df9 SecItemCopyMatching + 0
    
    tiny_hook(SecItemAdd, hk_SecItemAdd,  (void *)&SecItemAdd_ori);
    tiny_hook(SecItemUpdate, hk_SecItemUpdate, (void *)&SecItemUpdate_ori);
    tiny_hook(SecItemDelete, hk_SecItemDelete, (void *)&SecItemDelete_ori);
    tiny_hook(SecItemCopyMatching, hk_SecItemCopyMatching,(void *)&SecItemCopyMatching_ori);
}

- (void)hook_AllSecCode:teamIdentifier{
    static dispatch_once_t onceToken;
    static BOOL hasHooked = NO;
    if (hasHooked) {
        NSLogger(@"[Warning] hook_AllSecCode called multiple times! Skip hooking. teamIdentifier = %@", teamIdentifier);
        return;
    }
    dispatch_once(&onceToken, ^{
        hasHooked = YES;        
        NSLogger(@"[Hook] hook_AllSecCode first time. teamIdentifier = %@", teamIdentifier);
        G_TEAM_IDENTITY_ORI = [teamIdentifier UTF8String];
    //    Security`SecStaticCodeCheckValidity:
    //        0x7ff8106bc4aa <+0>: pushq  %rbp
    //        0x7ff8106bc4ab <+1>: movq   %rsp, %rbp
    //        0x7ff8106bc4ae <+4>: xorl   %ecx, %ecx
    //        0x7ff8106bc4b0 <+6>: popq   %rbp
    //        0x7ff8106bc4b1 <+7>: jmp    0x7ff8106bc4b6            ; SecStaticCodeCheckValidityWithErrors
//        tiny_hook(SecCodeCheckValidity, (void *)hk_SecCodeCheckValidity, (void *)&SecCodeCheckValidity_ori);
//        tiny_hook(SecStaticCodeCheckValidity, (void *)hk_SecStaticCodeCheckValidity, (void *)&SecStaticCodeCheckValidity_ori);
        tiny_hook(SecCodeCheckValidityWithErrors, (void *)hk_SecCodeCheckValidityWithErrors, (void *)&SecCodeCheckValidityWithErrors_ori);
        tiny_hook(SecCodeCopySigningInformation, (void *)hk_SecCodeCopySigningInformation, (void *)&SecCodeCopySigningInformation_ori);
        tiny_hook(SecStaticCodeCheckValidityWithErrors, (void *)hk_SecStaticCodeCheckValidityWithErrors, (void *)&SecStaticCodeCheckValidityWithErrors_ori);
    });
    
//    TODO:Is it needed?
//    SecTaskValidateForRequirement
//    SecRequirementEvaluate
}


// TODO: 监听进程并执行线程注入
- (void)startMonitorInjection:processName {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        while (true) {
            @autoreleasepool {
//                pid_t pid = [EncryptionUtils getProcessIDByName:processName];
//                kern_return_t result = inject_dylib(pid, nil);
//                if (result == KERN_SUCCESS) {
//                    NSLogger(@"Successfully injected dylib into process %d", pid);
//                    return;
//                } else {
//                    NSLogger(@"Failed to inject dylib into process %d", pid);
//                }
            }
            [NSThread sleepForTimeInterval:5.0];
        }
    });
}

@end
