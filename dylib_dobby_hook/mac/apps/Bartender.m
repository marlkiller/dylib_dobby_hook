//
//  Bartender.m
//  dylib_dobby_hook
//
//  Created by NKR on 2025/9/20.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"
#import "InstructionDecoder.h"

@interface Bartender : HackProtocolDefault

@end

@implementation Bartender


- (NSString *)getAppName {
    return @"com.surteesstudios.Bartender";
}

- (NSString *)getSupportAppVersion {
    return @"6.";
}

- (void)installTime {
    NSUserDefaults *defaults  = [NSUserDefaults standardUserDefaults];
    NSDate *currentDate = [NSDate date];
    [defaults setObject:currentDate forKey:@"trial5Start"];
    [defaults setObject:@"NKR🦁" forKey:@"license6HoldersName"];
    [defaults setObject:@"NKR1A-NKR2B-NKR3C-NKR4D-NKR5E-NKR6F-NKR7G-NKR8H-NKR9I-NKR0J-NKRAL-NKRBM-NKRCN-NKRDQ-NKRES-NKR" forKey:@"license6"];
    [defaults synchronize];
}

- (BOOL)hack {

    [self installTime];

    Method AppDelegate = class_getInstanceMethod(NSClassFromString(@"_TtC11Bartender_611AppDelegate"), NSSelectorFromString(@"isLicensed"));
  	IMP imp = method_getImplementation(AppDelegate);

    #if __x86_64__ || __amd64__
        void *instr_addr = (void *)((uint8_t *)imp + 0x4);
	#else
    	void *instr_addr = (void *)((uint8_t *)imp + 0x8);
    #endif

    uint64_t target = 0;
	#if __arm64__ || __aarch64__
        target = decode_bl_b_target_arm64(instr_addr);
	#elif __x86_64__ || __amd64__
        target = decode_call_target_x86_64((const uint8_t *)instr_addr);
	#endif

    tiny_hook((void*)target,ret1,NULL);

    return YES;
}

@end
