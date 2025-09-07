//
//  DeskWidgetHack.m
//  dylib_dobby_hook
//
//  Created by ooooooio on 2025/6/27.
//


#import <Foundation/Foundation.h>
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"

@interface DeskWidgetHack : HackProtocolDefault



@end


@implementation DeskWidgetHack
static IMP urlWithStringSeletorIMP;

- (NSString *)getAppName {
    return @"com.byteapp.widget";
}

- (NSString *)getSupportAppVersion {
    return @"";
}


- (BOOL)hack {
   
    urlWithStringSeletorIMP = [MemoryUtils hookClassMethod:
         NSClassFromString(@"NSURL")
                   originalSelector:NSSelectorFromString(@"URLWithString:")
                      swizzledClass:[self class]
                swizzledSelector:@selector(hk_URLWithString:)
    ];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@16 forKey:@"kLocalMemberStatusKey"];
    [defaults synchronize];
    
    return YES;
}

+ (id)hk_URLWithString:arg1{
    
    if ([arg1 hasPrefix:@"https://"] && ([arg1 containsString:@"buy.itunes.apple.com"] || [arg1 containsString:@"app-analytics-services.com"])) {
        NSLogger(@"hk_URLWithString Intercept requests %@",arg1);
        arg1 =  @"https://127.0.0.1";
    }
    id ret = ((id(*)(id, SEL,id))urlWithStringSeletorIMP)(self, _cmd,arg1);
    return ret;
}


@end
