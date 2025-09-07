//
//  CleanMyMacHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2025/4/18.
//

#import "Constant.h"
#import "HackProtocolDefault.h"
#import "MemoryUtils.h"
#import "common_ret.h"
#import "tinyhook.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <sys/ptrace.h>

@interface CleanMyMacHack : HackProtocolDefault

@end

@implementation CleanMyMacHack

static IMP updateUIForCustomerIMP;

- (NSString*)getAppName
{
    return @"com.macpaw.CleanMyMac5";
}

- (NSString*)getSupportAppVersion
{
    // AppName is [com.macpaw.CleanMyMac5],Version is [5.0.7], myAppCFBundleVersion is [50007.0.2503261326].
    return @"5.";
}

- (NSDate*)hk_expirationDate
{
    return [NSDate dateWithTimeIntervalSinceNow:60 * 60 * 24 * 365];
    ;
}
- (void)hk_updateUIForCustomer:(id)arg1 licenseValidationResult:(id)arg2
{
    // id MPALibLicenseValidationResult = [[NSClassFromString(@"MPALibLicenseValidationResult") alloc] init];
    id MPALibLicenseValidationResult = class_createInstance(objc_getClass("MPALibLicenseValidationResult"), 0);
    id MPACustomerImp = class_createInstance(objc_getClass("MPACustomerImp"), 0);
    [MemoryUtils setInstanceIvar:MPACustomerImp ivarName:"_email" value:[Constant G_EMAIL_ADDRESS]];
    ((void (*)(id, SEL, id, id))updateUIForCustomerIMP)(self, _cmd, MPACustomerImp, MPALibLicenseValidationResult);
}

static IMP resumeIMP;
// 按照下面方式来 hook xxx 方法, NSLog输入下参数
- (void)hook_resume
{
    ((void (*)(id, SEL))resumeIMP)(self, _cmd);
}

static IMP fetchCachedLicenseIMP;

- (void)hook_fetchActivationLicense:(int)arg1 callback:(void (^)(id))arg2
{
    NSLogger(@"[Hook] fetchCachedLicense: called with arg1 = %d", arg1);
    if (arg2) {
        // signature: "v16@?0@"<MPALicense>"8"
        Class MPALicenseImpClass = objc_getClass("MPALicenseImp"); // breakpoint set -r '\[MPALicenseImp .*\]'
        id licenseInstance = class_createInstance(MPALicenseImpClass, 0);
        SEL setStatusSel = sel_registerName("setStatus:");
        if ([licenseInstance respondsToSelector:setStatusSel]) {
            ((void (*)(id, SEL, NSInteger))objc_msgSend)(licenseInstance, setStatusSel, 1);
        }
        const char bytes[] = { 0x01, 0x02, 0x03 };
        NSData* fakeData = [NSData dataWithBytes:bytes length:sizeof(bytes)];
        [MemoryUtils invokeSelector:@"setPayload:" onTarget:licenseInstance, fakeData];

        Class MPAPlanImpClz = objc_getClass("MPAPlanImp");
        id planInstancce = class_createInstance(MPAPlanImpClz, 0); // breakpoint set -r '\[MPAPlanImp .*\]'
        [MemoryUtils invokeSelector:@"setPlanId:" onTarget:planInstancce, @"fuckplan"];
        [MemoryUtils invokeSelector:@"setPlanInfo:" onTarget:licenseInstance, planInstancce];
        arg2(licenseInstance);
        return;
    }
    id (*originalIMP)(id, SEL, int, id) = (id(*)(id, SEL, int, id))fetchCachedLicenseIMP;
    originalIMP(self, _cmd, arg1, arg2);
}

static IMP originalNeedsAttentionTypeIMP;

- (int)hook_needsAttentionType
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    id fakeLicInfo = @{
        @"Status" : @(0),
        @"ActiveUntilTimestamp" : @(now + 3600),
        @"PlanRenewalTimestamp" : @(now + 604800),
    };
    [MemoryUtils setInstanceIvar:self ivarName:"_libLicenseInfo" value:fakeLicInfo];
    [MemoryUtils getInstanceIvar:self ivarName:"_libLicenseInfo"];
    [MemoryUtils setInstanceIvar:self ivarName:"_libValidationStatus" value:@1];

    // id lic = [MemoryUtils getInstanceIvar:self ivarName:"_license"];
    // id status = [MemoryUtils invokeSelector:@"status" onTarget:lic];
    // v19 = (char *)-[MPALicense status](v18, "status");
    // if ( (unsigned __int64)(v19 - 1) >= 3 ) return 0
    // result = 7 4 2[(_QWORD)v19 - 1];
    int result = ((int (*)(id, SEL))originalNeedsAttentionTypeIMP)(self, _cmd);
    NSLogger(@"Original return: %d", result);
    return 1;
}

- (BOOL)hack
{
    [self hook_AllSecCode:@"S8EX82NJP6"];
    // 000000010029e5bf         db         "fetchCompanionAppActivationEligibilityWithCallback:", 0 ; DATA XREF=sub_100066fe4+592, sub_10006a04c+788, 0x100354e80
#if defined(__arm64__) || defined(__aarch64__)
    NSString* patch1Ori = @"61 00 00 54 1A 00 80 52 13 00 00 14";
    uint8_t patch1Target[12] = { 0x1F, 0x20, 0x03, 0xD5, 0x3A, 0x00, 0x80, 0x52, 0x13, 0x00, 0x00, 0x14 };
#elif defined(__x86_64__)
    NSString* patch1Ori = @"83 F8 01 75 09 45 31 E4";
    uint8_t patch1Target[8] = { 0x45, 0x31, 0xE4, 0x90, 0x90, 0x41, 0xB4, 0x01 };
#endif

    NSArray* patch1Ptrs = [MemoryUtils getPtrFromMachineCode:(NSString*)@"/Contents/MacOS/CleanMyMac_5"
                                                 machineCode:(NSString*)patch1Ori
                                                       count:(int)1];
    uintptr_t patch1Ptr = [patch1Ptrs[0] unsignedIntegerValue];
    write_mem((void*)patch1Ptr, (uint8_t*)patch1Target, sizeof(patch1Target) / sizeof(patch1Target[0]));

    //    originalNeedsAttentionTypeIMP = [MemoryUtils hookInstanceMethod:
    //        objc_getClass("MPALibLicenseValidationResult")
    //        originalSelector:NSSelectorFromString(@"needsAttentionType")
    //        swizzledClass:[self class]
    //        swizzledSelector:@selector(hook_needsAttentionType)
    //    ];
    //    fetchCachedLicenseIMP = [MemoryUtils hookInstanceMethod:
    //        objc_getClass("MPAServerDataProviderImp")
    //        originalSelector:NSSelectorFromString(@"fetchActivationLicense:callback:")
    //        swizzledClass:[self class]
    //        swizzledSelector:@selector(hook_fetchActivationLicense:callback:)
    //    ];

    //
    //    resumeIMP = [MemoryUtils hookInstanceMethod:
    //          objc_getClass("NSURLSessionDataTask")
    //          originalSelector:NSSelectorFromString(@"resume")
    //          swizzledClass:[self class]
    //          swizzledSelector:NSSelectorFromString(@"hook_resume")
    //   ];

    updateUIForCustomerIMP = [MemoryUtils hookInstanceMethod:
            NSClassFromString(@"MPAActivationInfoViewController")
                                            originalSelector:NSSelectorFromString(@"updateUIForCustomer:licenseValidationResult:")
                                               swizzledClass:[self class]
                                            swizzledSelector:NSSelectorFromString(@"hk_updateUIForCustomer:licenseValidationResult:")];
    [MemoryUtils hookInstanceMethod:
            NSClassFromString(@"MPALibLicenseValidationResult")
                   originalSelector:NSSelectorFromString(@"expirationDate")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_expirationDate")];
    return YES;
}

@end
