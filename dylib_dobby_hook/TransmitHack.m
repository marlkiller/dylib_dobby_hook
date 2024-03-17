//
//  TablePlusHack.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import "HackProtocol.h"

@interface TransmitHack : NSObject <HackProtocol>

@end


@implementation TransmitHack

- (NSString *)getAppName {
    return @"com.panic.Transmit";
}

- (NSString *)getSupportAppVersion {
    // 5.10.4
    return @"5.";
}



- (void)hk_updateCountdownView:(uint64_t)arg1  {
    NSLog(@">>>>>> Swizzled hk_updateCountdownView method called");
    NSLog(@">>>>>> self.className : %@", self.className);
//    SEL selector = NSSelectorFromString(@"trialTitleBarViewController");
//    if ([self respondsToSelector:selector]) {
//        id trialTitleBarViewController = [self performSelector:selector];
//        NSLog(@">>>>>> trialTitleBarViewController : %@", trialTitleBarViewController);
//    }
}

- (void)hk_startUpdater {
    NSLog(@">>>>>> Swizzled hk_startUpdater method called");
    NSLog(@">>>>>> self.className : %@", self.className);
 
}

int (*hook_TRTrialStatus_ori)(void);

int hook_TRTrialStatus(void){
    NSLog(@">>>>>> called hook_TRTrialStatus");
    return 9999;
};

- (void)hk_terminateExpiredTrialTimerDidFire:(id)arg1  {
    NSLog(@">>>>>> Swizzled hk_terminateExpiredTrialTimerDidFire method called");
    NSLog(@">>>>>> self.className : %@", self.className);
}


- (BOOL)hack {
    
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/Transmit"];

    
#if defined(__arm64__) || defined(__aarch64__)
    NSString *searchMachineCode = @"F6 57 BD A9 F4 4F 01 A9 FD 7B 02 A9 FD 83 00 91 15 0C ?? ?? B5 72 ?? ?? A0 02 40 F9";
#elif defined(__x86_64__)
    NSString *searchMachineCode = @"55 48 89 E5 41 57 41 56 41 55 41 54 53 50 4C 8B ?? ?? ?? ?? ?? 49 8B 3E";

#endif
    // void __cdecl -[TRDocument updateCountdownView](TRDocument *self, SEL a2)
//    [MemoryUtils hookInstanceMethod:
//                objc_getClass("TRDocument")
//                originalSelector:NSSelectorFromString(@"updateCountdownView")
//                swizzledClass:[self class]
//                // swizzledSelector:NSSelectorFromString(@"hk_updateCountdownView:arg2:")
//                swizzledSelector:NSSelectorFromString(@"hk_updateCountdownView:")
//
//    ];
    
    [MemoryUtils hookInstanceMethod:
                objc_getClass("SPUStandardUpdaterController")
                originalSelector:NSSelectorFromString(@"startUpdater")
                swizzledClass:[self class]
                swizzledSelector:NSSelectorFromString(@"hk_startUpdater")

    ];
    
    [MemoryUtils hookInstanceMethod:
                objc_getClass("TransmitDelegate")
                originalSelector:NSSelectorFromString(@"terminateExpiredTrialTimerDidFire:")
                swizzledClass:[self class]
                swizzledSelector:NSSelectorFromString(@"hk_terminateExpiredTrialTimerDidFire:")

    ];
        
    
    int count = 1;
    NSArray *globalOffsets =[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath machineCode:(NSString *)searchMachineCode count:(int)count];
    uintptr_t globalOffset = [globalOffsets[0] unsignedIntegerValue];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    
    int imageIndex = [MemoryUtils indexForImageWithName:@"Transmit"];
    intptr_t _hook_TRTrialStatus = [MemoryUtils getPtrFromGlobalOffset:imageIndex targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    DobbyHook((void *)_hook_TRTrialStatus, (void *)hook_TRTrialStatus, (void *)&hook_TRTrialStatus_ori);
    return YES;
}
@end
