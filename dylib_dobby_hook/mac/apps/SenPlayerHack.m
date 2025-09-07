//
//  SenPlayerHack.m
//  dylib_dobby_hook
//
//  Created by ooooooio on 2025/7/4.
//

#import <Foundation/Foundation.h>
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"
#import "common_ret.h"

@interface SenPlayerHack : HackProtocolDefault



@end


@implementation SenPlayerHack

- (NSString *)getAppName {
    return @"com.wuziqi.SenPlayer";
}

- (NSString *)getSupportAppVersion {
    return @"5.6.3";
}


- (BOOL)hack {
    
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
    
    hookSenPlayerSubRefresh(@"/Contents/MacOS/SenPlayer");

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"com.wuziqi.SenPlayer.LifeTimePro" forKey:@"ProId"];
    [defaults setObject:@YES forKey:@"kFont"];
    [defaults synchronize];
    
    return YES;
}

void hookSenPlayerSubRefresh(NSString *searchFilePath) {
    /*
     凭证有效时长: 无凭证
     */
#if defined(__arm64__) || defined(__aarch64__)
    NSString *mark = @"E9 23 B9 6D FC 6F 01 A9 FA 67 02 A9 F8 5F 03 A9 F6 57 04 A9 F4 4F 05 A9 FD 7B 06 A9 FD 83 01 91 FF 43 00 D1 F5 03 14 AA 08 40 60 1E";
#elif defined(__x86_64__)
    NSString *mark = @"55 48 89 E5 41 57 41 56 41 55 41 54 53 48 83 EC 68 4D 89 EC F2 0F 11 45 B8 48";
#endif
    
    [MemoryUtils hookWithMachineCode:searchFilePath
                         machineCode:mark
                           fake_func:(void *)ret0
                               count:1
    ];
}
@end
