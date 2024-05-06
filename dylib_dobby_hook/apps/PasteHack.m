#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocol.h"
#import "common_ret.h"

@interface PasteHack : NSObject <HackProtocol>

@end

@implementation PasteHack


- (NSString *)getAppName {
    return @"com.wiheads.paste";
}

- (NSString *)getSupportAppVersion {
    return @"4.1.3";
}

int (*validSubscriptionOri)(void);

//int validSubscriptionNew(int arg0, int arg1) {
//    return 1;
//}
//int _cloudKitNew(int arg0, int arg1) {
//    return 1;
//}

- (int) hook_ubiquityIdentityToken {
    NSLog(@">>>>>> hook_ubiquityIdentityToken");
    return 0;
}

- (BOOL)hack {
    
#if defined(__arm64__) || defined(__aarch64__)
    
    // hook 是否有效订阅
    //    intptr_t validSubscription = [MemoryUtils getPtrFromAddress:0x1002e14dc];
    //    DobbyHook(validSubscription, validSubscriptionNew, (void *)&validSubscriptionOri);
    // hook cloudkit
    //    intptr_t _cloudKit = [MemoryUtils getPtrFromAddress:0x1002b7a68];
    //    DobbyHook(_cloudKit, ret1, (void *)&_cloudKitOri);
    
    [MemoryUtils hookInstanceMethod:objc_getClass("NSFileManager") originalSelector:NSSelectorFromString(@"ubiquityIdentityToken") swizzledClass:[self class] swizzledSelector:NSSelectorFromString(@"hook_ubiquityIdentityToken")];
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/Paste"];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    
    hookSubscription(searchFilePath, fileOffset);
    
#elif defined(__x86_64__)
    // TODO Support __x86_64__
#endif
    
    return YES;
}

void hookSubscription(NSString *searchFilePath, uintptr_t fileOffset) {
    
    NSArray *globalOffsets =[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath
                                                      machineCode:(NSString *) @"F8 5F BC A9 F6 57 01 A9 F4 4F 02 A9 FD 7B 03 A9 FD C3 00 91 F5 03 01 AA F6 03 00 AA F7 1C 00 90 F7 42 2D 91"
                                                            count:(int)1];
    uintptr_t globalOffset = [globalOffsets[0] unsignedIntegerValue];
    
    intptr_t validSubscription = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    DobbyHook((void *)validSubscription, (void *)ret1, (void *)&validSubscriptionOri);
}

@end
