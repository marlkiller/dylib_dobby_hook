//
//  CleanMyMacAgentHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2025/4/18.
//

#import <Foundation/Foundation.h>
#import "HackHelperProtocolDefault.h"

@interface CleanMyMacAgentHack : HackHelperProtocolDefault



@end


@implementation CleanMyMacAgentHack


- (NSString *)getAppName {
    return @"com.macpaw.CleanMyMac5.Agent";
}
 
- (BOOL)hack {
    
    [self hook_AllSecCode:@"S8EX82NJP6"];
    return YES;
}

@end
