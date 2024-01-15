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
    return @"com.tinyapp.TablePlus";
}

- (BOOL)checkVersion {
    // TODO
    return YES;
}

- (BOOL)hack {
    
    #if defined(__arm64__) || defined(__aarch64__)
        
    #elif defined(__x86_64__)
        
    #endif
    
    return YES;
}





@end
