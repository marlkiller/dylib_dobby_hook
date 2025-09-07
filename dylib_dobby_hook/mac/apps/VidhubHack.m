//
//  VidhubHack.h
//  dylib_dobby_hook
//
//  Created by asdf asd on 2024/10/18.
//

//
//  Vidhub.m
//  dylib_dobby_hook
//
//  Created by weizi on 2024/5/11.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"

@interface VidhubHack : HackProtocolDefault

@end

@implementation VidhubHack
static IMP urlWithStringSeletorIMP;
//static IMP NSURLSessionClassIMP;

- (NSString *)getAppName {
    // 2024-05-11 15:45:29.526 Infuse[84842:2247193] >>>>>> AppName is [com.firecore.infuse],Version is [7.7.5], myAppCFBundleVersion is [7.7.4827].
    return @"com.mac.utility.media.hub";
}

- (NSString *)getSupportAppVersion {
    return @"1.7.10";
}

- (BOOL)hack {
   
    //Class NSURLControllerClass = NSClassFromString(@"NSURL");
    //SEL urlWithStringSeletor = NSSelectorFromString(@"URLWithString:");
    //Method urlWithStringSeletorMethod = class_getClassMethod(NSURL.class, urlWithStringSeletor);
    //urlWithStringSeletorIMP = method_getImplementation(urlWithStringSeletorMethod);

    
    urlWithStringSeletorIMP = [MemoryUtils hookClassMethod:
         NSClassFromString(@"NSURL")
                   originalSelector:NSSelectorFromString(@"URLWithString:")
                      swizzledClass:[self class]
                swizzledSelector:@selector(hk_URLWithString:)
    ];
    
    
    hookSubscription1(@"/Contents/MacOS/MediaCenter");
    
    
    [MemoryUtils hookClassMethod:
         NSClassFromString(@"NSUbiquitousKeyValueStore")
                   originalSelector:NSSelectorFromString(@"defaultStore")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(hook_defaultStore)
    ];

    [MemoryUtils hookClassMethod:
        NSClassFromString(@"CKContainer")
                  originalSelector:NSSelectorFromString(@"containerWithIdentifier:")
                     swizzledClass:[self class]
                  swizzledSelector:@selector(hook_containerWithIdentifier: )
    ];
    [MemoryUtils hookClassMethod:
        NSClassFromString(@"CKContainer")
                  originalSelector:NSSelectorFromString(@"defaultContainer")
                     swizzledClass:[self class]
                  swizzledSelector:@selector(hook_defaultContainer)

    ];
    
    
    return YES;
}

void hookSubscription1(NSString *searchFilePath) {

#if defined(__arm64__) || defined(__aarch64__)
    NSString *sub_0x10031f878Code = @"F8 5F BC A9 F6 57 01 A9 F4 4F 02 A9 FD 7B 03 A9 FD C3 00 91 F3 03 00 AA E8 77 00 F0 08 D5 46 F9 1F 05 00 B1 E1 06 00 54";
#elif defined(__x86_64__)
    NSString *sub_0x10031f878Code = @"55 48 89 E5 41 57 41 56 41 55 41 54 53 50 89 FB 48 83 3D F0 72 F8 00 FF 0F 85 CF 00 00 00 48 8D 05 43 70 0F 01 4C 8B 28 E8 13 12 F6 FF 49 89 C5";
#endif
    
    [MemoryUtils hookWithMachineCode:searchFilePath
                         machineCode:sub_0x10031f878Code
                           fake_func:(void *)ret1
                               count:1
    ];
}

+ (id)hk_URLWithString:arg1{
    
    if ([arg1 hasPrefix:@"https://"] && [arg1 containsString:@"in.appcenter.ms"]) {
        NSLogger(@"hk_URLWithString Intercept requests %@",arg1);
        arg1 =  @"https://127.0.0.1";
    }
    id ret = ((id(*)(id, SEL,id))urlWithStringSeletorIMP)(self, _cmd,arg1);
    return ret;
}

@end
