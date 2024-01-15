//
//  TablePlusHack.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "TablePlusHack.h"
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"

@implementation TablePlusHack


- (NSString *)getAppName {
    return @"tale";
}

- (BOOL)checkVersion {
    // TODO
    return YES;
}

- (BOOL)hack {
    [self hook];
    return YES;
}



#if defined(__arm64__) || defined(__aarch64__)


- (void)hook {
    NSLog(@"The current app running environment is __arm64__");
    
}
#elif defined(__x86_64__)

- (void)hook {
    NSLog(@"The current app running environment is __x86_64__");
    NSLog(@"The current app running environment is __x86_64__");
    
   
}
#endif


@end
