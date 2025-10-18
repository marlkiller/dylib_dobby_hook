//
//  MockUbiquitousKeyValueStore.m
//  dylib_dobby_hook
//
//  Created by voidm on 2025/8/16.
//

#import "MockUbiquitousKeyValueStore.h"
#import "Logger.h"


@implementation MockUbiquitousKeyValueStore {
    NSUserDefaults *_backingStore;
}
- (id)dictionaryRepresentation{
    return [_backingStore dictionaryRepresentation];
};
+ (instancetype)defaultStore {
    static MockUbiquitousKeyValueStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[self alloc] init];
    });
    return store;
}

- (instancetype)init {
    if (self = [super init]) {
        _backingStore = [[NSUserDefaults alloc] initWithSuiteName:@"MockUbiquitousKeyValueStore"];
        [self printBackingStoreInfo];
    }
    return self;
}

// 打印 plist 文件路径 + defaults 命令
- (void)printBackingStoreInfo {
    NSString *plistPath = [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist",
                           NSHomeDirectory(),
                           @"MockUbiquitousKeyValueStore"];
    NSString *command = [NSString stringWithFormat:@"defaults export \"%@\" -", plistPath];
    NSLogger(@"[MockUbiquitousKeyValueStore] export command: %@", command);

}
- (BOOL)boolForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    return [obj respondsToSelector:@selector(boolValue)] ? [obj boolValue] : NO;
}

- (NSInteger)integerForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    return [obj respondsToSelector:@selector(integerValue)] ? [obj integerValue] : 0;
}

- (float)floatForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    return [obj respondsToSelector:@selector(floatValue)] ? [obj floatValue] : 0;
}

- (double)doubleForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    return [obj respondsToSelector:@selector(doubleValue)] ? [obj doubleValue] : 0;
}

- (NSString *)stringForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    return [obj isKindOfClass:[NSString class]] ? obj : [obj description];
}

- (id)objectForKey:(NSString *)key {
    id obj = [_backingStore objectForKey:key];
    NSLogger(@"[Mock] objectForKey:%@ => %@", key, obj);
    return obj;
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)setFloat:(float)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)setDouble:(double)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)setString:(NSString *)value forKey:(NSString *)key {
    [self setObject:value forKey:key];
}

- (void)setObject:(id)obj forKey:(NSString *)key {
    NSLogger(@"[Mock] setObject:%@ forKey:%@", obj, key);
    [_backingStore setObject:obj forKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
    NSLogger(@"[Mock] removeObjectForKey:%@", key);
    [_backingStore removeObjectForKey:key];
}

- (BOOL)synchronize {
    NSLogger(@"[Mock] synchronize");
    return [_backingStore synchronize];
}

// 模拟一个 count 方法
- (NSUInteger)count {
    return [[_backingStore dictionaryRepresentation] count];
}


@end
