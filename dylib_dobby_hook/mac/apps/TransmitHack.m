//
//  TransmitHack.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"

@interface TransmitHack : HackProtocolDefault

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
    NSLogger(@"Swizzled hk_updateCountdownView method called");
    NSLogger(@"self.className : %@", self.className);
//    SEL selector = NSSelectorFromString(@"trialTitleBarViewController");
//    if ([self respondsToSelector:selector]) {
//        id trialTitleBarViewController = [self performSelector:selector];
//        NSLogger(@"trialTitleBarViewController : %@", trialTitleBarViewController);
//    }
}

- (void)hk_startUpdater {
    NSLogger(@"Swizzled hk_startUpdater method called");
    NSLogger(@"self.className : %@", self.className);
 
}

int (*hook_TRTrialStatus_ori)(void);

int hook_TRTrialStatus(void){
    NSLogger(@"called hook_TRTrialStatus");
    return 9999;
};

- (void)hk_terminateExpiredTrialTimerDidFire:(id)arg1  {
    NSLogger(@"Swizzled hk_terminateExpiredTrialTimerDidFire method called");
    NSLogger(@"self.className : %@", self.className);
}


- (BOOL)hack {
    // void __cdecl -[TRDocument updateCountdownView](TRDocument *self, SEL a2)
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
    
#if defined(__arm64__) || defined(__aarch64__)
    NSString *searchMachineCode = @"F6 57 BD A9 F4 4F 01 A9 FD 7B 02 A9 FD 83 00 91 15 0C ?? ?? B5 72 ?? ?? A0 02 40 F9";
#elif defined(__x86_64__)
    NSString *searchMachineCode = @"55 48 89 E5 41 57 41 56 41 55 41 54 53 50 4C 8B ?? ?? ?? ?? ?? 49 8B 3E";
#endif
        
    [MemoryUtils hookWithMachineCode:@"/Contents/MacOS/Transmit"
                             machineCode:searchMachineCode
                               fake_func:(void *)hook_TRTrialStatus
                                   count:1
                            out_orig:(void *)&hook_TRTrialStatus_ori
    ];
    
    // license info
//    __text:000000010002FAFB ; void __cdecl -[TransmitDelegate showLicense:](TransmitDelegate *self, SEL, id)
//    rax = [NSUserDefaults standardUserDefaults];
//    r15 = [[rax stringForKey:@"RegistrationUsername"] retain];
//    rax = [r14 licenseWindowController];
//    rax = [rax retain];
//    [rax setName:r15];
//    [rax release];
//    [r15 release];
//    [rbx release];
//    rax = [NSUserDefaults standardUserDefaults];
//    rax = [rax retain];
//    var_30 = [[rax stringForKey:@"RegistrationDate"] retain];
//    [rax release];
//    if (var_30 != 0x0) {
//            r12 = objc_alloc_init(@class(NSDateFormatter));
//            rax = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
//            rax = [rax retain];
//            [r12 setTimeZone:rax];
//            [rax release];
//            [r12 setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
//            rbx = [[r12 dateFromString:var_30] retain];
//            rax = [r14 licenseWindowController];
//            rax = [rax retain];
//            [rax setRegistrationDate:rbx];
//            [rax release];
//            [rbx release];
//            [r12 release];
//    }
    
    NSUserDefaults *defaults  = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[Constant G_EMAIL_ADDRESS] forKey:@"RegistrationUsername"];
    [defaults setObject:@"2099-04-11 13:30:45 GMT" forKey:@"RegistrationDate"];
    [defaults synchronize];
    
    return YES;
}
@end
