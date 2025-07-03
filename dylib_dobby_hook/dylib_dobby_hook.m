//
//  dylib_dobby_hook.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/14.
//

#import "dylib_dobby_hook.h"
#import "tinyhook.h"
#import "Constant.h"
#import "MemoryUtils.h"
#import <CommonRetOC.h>

@implementation dylib_dobby_hook

// INIT TEST START
//int sum(int a, int b) {
//    return a+b;
//}
////函数指针用于保存被替换函数的地址
////static int (*sum_p)(int a, int b);
//
////新函数
//int mySum(int a,int b){
//    return a - b;
//}
//void initTest(void){
//    
//    NSLogger(@"before %d", sum(1, 2));
//    // NSLogger(@"%s", DobbyGetVersion());
////    tiny_hook(sum, mySum, (void *)&sum_p);
//    tiny_hook(sum, mySum, nil);
//    NSLogger(@"after %d", sum(1, 2));
////    NSLogger(@"origin %d", sum_p(1, 2));
//    
//}
// INIT TEST END


BOOL shouldExcludeCurrentApp(void) {
    NSArray *excludedPrefixes = @[
        @"/System/",
        @"/usr/"
    ];
    NSString *currentPath = [Constant getCurrentAppPath];
    for (NSString *prefix in excludedPrefixes) {
        if ([currentPath hasPrefix:prefix]) {
            NSLogger(@"Current process '%@' is excluded, matching prefix '%@'", currentPath, prefix);
            return YES;
        }
    }
    return NO;
}

+ (void) load {
//    initTest();
    NSLogger(@"dylib_dobby_hook load");
    if (shouldExcludeCurrentApp()) {
        // Starter Ref :
        // https://book.hacktricks.xyz/v/cn/macos-hardening/macos-security-and-privilege-escalation/macos-proces-abuse/macos-library-injection#dyld_insert_libraries
        return;
    }
    [Constant doHack];
}
@end
