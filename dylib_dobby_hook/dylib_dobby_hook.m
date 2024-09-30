//
//  dylib_dobby_hook.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/14.
//

#import "dylib_dobby_hook.h"
#import "dobby.h"
#import "Constant.h"
#import "MemoryUtils.h"
#import <Cocoa/Cocoa.h>

@implementation dylib_dobby_hook

// INIT TEST START
int sum(int a, int b) {
    return a+b;
}
//函数指针用于保存被替换函数的地址
static int (*sum_p)(int a, int b);

//新函数
int mySum(int a,int b){
    return a - b;
}
void initTest(void){
    
    NSLog(@"before %d", sum(1, 2));
    NSLog(@"%s", DobbyGetVersion());
//    DobbyHook(sum, mySum, (void *)&sum_p);
    DobbyHook(sum, mySum, nil);
    NSLog(@"after %d", sum(1, 2));
//    NSLog(@"origin %d", sum_p(1, 2));
    
}
// INIT TEST END


BOOL shouldExcludeCurrentApp(void) {
    NSArray *excludedPrefixes = @[
        @"/System/",
        @"/usr/"
    ];
    NSString *currentPath = [Constant getCurrentAppPath];
    for (NSString *prefix in excludedPrefixes) {
        if ([currentPath hasPrefix:prefix]) {
            NSLog(@">>>>>> Current process '%@' is excluded, matching prefix '%@'", currentPath, prefix);
            return YES;
        }
    }
    return NO;
}


BOOL canShowAlert(void) {
    NSString *path = [[[NSProcessInfo processInfo] arguments] firstObject];
    
    // 检查路径
    if ([path hasPrefix:@"/System/Library/"] || [path hasPrefix:@"/usr/bin/"]) {
        NSLog(@">>>>>> Path starts with /usr/bin/, UI alert not allowed.");
        return NO;
    }
    
    if ([Constant isHelper]) {
        NSLog(@">>>>>> Process is a helper, UI alert not allowed.");
        return NO;
    }
//    NSApplicationActivationPolicyRegular： 普通应用，能在 Dock 中显示，接受用户输入。例如：Safari、Mail。
//    NSApplicationActivationPolicyAccessory： 辅助应用，不在 Dock 中显示，但可以在菜单栏中显示图标。通常用于后台工具。
//    NSApplicationActivationPolicyProhibited： 被禁止激活的应用，不显示在 Dock 中，也无法接受输入。常用于后台服务。
    BOOL isForeground = [NSRunningApplication currentApplication].activationPolicy == NSApplicationActivationPolicyRegular;
    NSLog(@">>>>>> Is current application canShowAlert: %@", isForeground ? @"YES" : @"NO");
    return isForeground;
}

+ (void) load {
    
    
//    initTest();
    NSLog(@">>>>>> dylib_dobby_hook load");
    if (shouldExcludeCurrentApp()) {
        // Starter Ref :
        // https://book.hacktricks.xyz/v/cn/macos-hardening/macos-security-and-privilege-escalation/macos-proces-abuse/macos-library-injection#dyld_insert_libraries
        return;
    }
    
    
    BOOL showAlarm = canShowAlert();
    if ([Constant isFirstOpen] && showAlarm) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Cracked By\n[marlkiller/dylib_dobby_hook]"];
        [alert setInformativeText:@"仅供研究学习使用，请勿用于非法用途"];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
    [Constant doHack];
}
@end
