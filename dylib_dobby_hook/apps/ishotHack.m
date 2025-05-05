//
//  ishotHack.h
//  dylib_dobby_hook
//
//  Created by weizi asd on 2024/10/28.


#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"
#import <AppKit/AppKit.h>
//#include <mach/mach_vm.h>

@interface ishotHack : HackProtocolDefault


@end


@implementation ishotHack
static IMP displayRegisteredInfoIMP;

- (NSString *)getAppName {
    return @"cn.better365.ishot";
}

- (NSString *)getSupportAppVersion {
    return @"2.5";
}

- (BOOL)hack {
    
    displayRegisteredInfoIMP = [MemoryUtils hookInstanceMethod:
                                    NSClassFromString(@"AppPrefsWindowController")
               originalSelector:NSSelectorFromString(@"awakeFromNib")
               swizzledClass:[self class]
                                              swizzledSelector:@selector(ishot_hk_displayRegisteredInfo)
           ];
    
    //NSLog(@"displayRegisteredInfoIMP : %p",displayRegisteredInfoIMP);
    ishot_istrial();
    
    return YES;
}

void ishot_istrial(void) {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"4K6FWZU8C4.group.cn.better365"];
    [defaults setObject:@100000000000 forKey:@"AppStoreiShotInstallTime"];
}



- (void)ishot_hk_displayRegisteredInfo {
    ((void(*)(id, SEL))displayRegisteredInfoIMP)(self,_cmd);
    
  
    id _buyButton = [MemoryUtils getInstanceIvar:self ivarName:"_buyButton"];
    if (_buyButton) {
        //NSLogger(@"buyButton %@",[buyButton stringValue]);
        [_buyButton setTitle:@"授权给: wawa"];
        //[_buyButton setHidden:YES];
        [_buyButton setEnabled:NO];
        //[MemoryUtils setInstanceIvar:self ivarName:"expirationTimeValueTextField" value:expirationTimeValueTextField];
    }
    //_version
    id _version = [MemoryUtils getInstanceIvar:self ivarName:"_version"];
    if (_version) {
        //NSLogger(@"buyButton %@",[buyButton stringValue]);
        [_version setStringValue:@"iShot Pro 2.5.5"];
        //[MemoryUtils setInstanceIvar:self ivarName:"expirationTimeValueTextField" value:expirationTimeValueTextField];
    }
    return;

}

@end
