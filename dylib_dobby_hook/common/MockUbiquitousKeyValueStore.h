//
//  MockUbiquitousKeyValueStore.h
//  dylib_dobby_hook
//
//  Created by voidm on 2025/8/16.
//
#import <Foundation/Foundation.h>

@interface MockUbiquitousKeyValueStore : NSObject
+ (instancetype)defaultStore;
@property (nonatomic, strong) NSUserDefaults *backingStore;
@end
