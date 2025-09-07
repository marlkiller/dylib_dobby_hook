//
//  CleanShotXHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/19.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"
#include <sys/ptrace.h>
#import "common_ret.h"

@interface CleanShotXHack : HackProtocolDefault

@end

static IMP JSONObjectWithDataIMP;

@implementation CleanShotXHack

- (NSString *)getAppName {
    return @"pl.maketheweb.cleanshotx";
}

- (NSString *)getSupportAppVersion {
    return @"4.";
}

- (BOOL)hack {
    void* showCleanShotAWC = symexp_solve(
        [MemoryUtils indexForImageWithName:@"Legit"],
        "_$s5Legit0A9CleanShotC11productName03appE07website5email8delegate15updaterDelegate16cloudAPIDelegateACSS_S3SAA0aK0_pAA0a7UpdaterK0_pAA0a5CloudM0_ptcfc"
    );
    tiny_hook(showCleanShotAWC, ret0, NULL);

#if defined(__arm64__) || defined(__aarch64__)
    // 27 01 88 9A 08 FC 50 D3 29 FC 50 D3 5F 00 04 EB is not necessary
    NSString *checkHex = @"A8 EC 78 D3 89 BC 40 92 BF 00 43 F2 27 01 88 9A 08 FC 50 D3 29 FC 50 D3 5F 00 04 EB";
#elif defined(__x86_64__)
    // 4D 89 CB 49 C1 EB is not necessary
    NSString *checkHex = @"48 89 F0 49 89 FA 4D 89 CB 49 C1 EB";
#endif

    [MemoryUtils hookWithMachineCode:@"/Contents/MacOS/CleanShot X"
    machineCode:checkHex
    fake_func:(void *)ret1
    count:1];

#if defined(__arm64__) || defined(__aarch64__)
    NSString *sigaMachCode = @"FF 03 02 D1 E9 23 03 6D F8 5F 04 A9 F6 57 05 A9 F4 4F 06 A9 FD 7B 07 A9 FD C3 01 91 .. .. .. .. .. .. .. F9 .. .. 00 B4";

    [MemoryUtils hookWithMachineCode:@"/Contents/MacOS/CleanShot X"
    machineCode:sigaMachCode
    fake_func:(void *)ret
    count:1];
#elif defined(__x86_64__)
    // No x86_64 specific code for sigaMachCode
#endif

    // Hook NSJSONSerialization using the same pattern as your ShottrHack
    JSONObjectWithDataIMP = [MemoryUtils hookClassMethod:
                                NSClassFromString(@"NSJSONSerialization")
                    originalSelector:NSSelectorFromString(@"JSONObjectWithData:options:error:")
                            swizzledClass:[self class]
                    swizzledSelector:NSSelectorFromString(@"hook_JSONObjectWithData:options:error:")
    ];

    return YES;
}

// Hook the JSON parsing method to modify the response
+ (id)hook_JSONObjectWithData:(NSData *)data options:(NSJSONReadingOptions)options error:(NSError **)error {
    id result = ((id(*)(Class, SEL, NSData *, NSJSONReadingOptions, NSError **))JSONObjectWithDataIMP)([NSJSONSerialization class], @selector(JSONObjectWithData:options:error:), data, options, error);
    if (!result) {
        return result;
    }
    if (![result isKindOfClass:[NSDictionary class]]) {
        return result;
    }
    NSDictionary *dict = (NSDictionary *)result;
    id dataObj = dict[@"data"];
    if (!dataObj || ![dataObj isKindOfClass:[NSDictionary class]]) {
        return result;
    }
    NSDictionary *dataDict = (NSDictionary *)dataObj;
    id userObj = dataDict[@"user"];
    if (!userObj || ![userObj isKindOfClass:[NSDictionary class]]) {
        return result;
    }
    NSDictionary *userDict = (NSDictionary *)userObj;
    id teamObj = userDict[@"team"];
    if (!teamObj || ![teamObj isKindOfClass:[NSDictionary class]]) {
        return result;
    }
    NSDictionary *teamDict = (NSDictionary *)teamObj;
    id billingPlanObj = teamDict[@"billing_plan"];
    if (!billingPlanObj || ![billingPlanObj isKindOfClass:[NSDictionary class]]) {
        return result;
    }
    NSDictionary *billingPlanDict = (NSDictionary *)billingPlanObj;
    id abilitiesObj = billingPlanDict[@"abilities"];
    if (!abilitiesObj || ![abilitiesObj isKindOfClass:[NSDictionary class]]) {
        return result;
    }

    @try {
        NSMutableDictionary *mutableResult = [dict mutableCopy];
        NSMutableDictionary *mutableData = [mutableResult[@"data"] mutableCopy];
        NSMutableDictionary *mutableUser = [mutableData[@"user"] mutableCopy];
        NSMutableDictionary *mutableTeam = [mutableUser[@"team"] mutableCopy];
        NSMutableDictionary *mutableBillingPlan = [mutableTeam[@"billing_plan"] mutableCopy];
        NSMutableDictionary *mutableAbilities = [mutableBillingPlan[@"abilities"] mutableCopy];
        // Enable premium features
        mutableAbilities[@"can_upload_original_media"] = @YES;
        mutableAbilities[@"can_copy_direct_link"] = @YES;
        mutableAbilities[@"can_set_expire_after"] = @YES;
        mutableAbilities[@"can_set_media_password"] = @YES;
        // Also modify billing plan to look like premium
        mutableBillingPlan[@"name"] = @"pro";
        mutableBillingPlan[@"readable_name"] = @"Pro";
        mutableBillingPlan[@"is_paid"] = @YES;
        // Rebuild the structure
        mutableBillingPlan[@"abilities"] = mutableAbilities;
        mutableTeam[@"billing_plan"] = mutableBillingPlan;
        mutableUser[@"team"] = mutableTeam;
        mutableData[@"user"] = mutableUser;
        mutableResult[@"data"] = mutableData;

        NSLogger(@"[CleanShotXHack] Successfully modified JSON response - enabled premium features");
        return mutableResult;

    } @catch (NSException *exception) {
        NSLogger(@"[CleanShotXHack] Exception while modifying JSON: %@", exception);
        return result;
    }
}

@end
