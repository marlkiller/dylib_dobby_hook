#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Security/Security.h>
#import "HackProtocolDefault.h"
#import "MemoryUtils.h"
#import "Constant.h"

@interface HackerNewsHack : HackProtocolDefault

@end

@implementation HackerNewsHack

#pragma mark - App Information

- (NSString *)getAppName {
    return @"com.pranapps.ByteHackerNews";
}

- (NSString *)getSupportAppVersion {
    return @"";
}

#pragma mark - String Builders

static NSString *buildFakeTransaction(void) {
    return @"hack_upgrade_pro_1000000001";
}

static NSString *buildKeychainService(void) {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"com.pranapps.ByteHackerNews";
    return [NSString stringWithFormat:@"%@.productid_transaction", bundleID];
}

#pragma mark - Keychain Injection

static NSData *encodeTransactionString(NSString *txString) {
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
    [archiver encodeObject:txString forKey:@"productid_transaction"];
    [archiver finishEncoding];
    return [archiver encodedData];
}

static void injectKeychainTransaction(void) {
    @autoreleasepool {
        NSString *serviceKey = buildKeychainService();
        NSString *txValue = buildFakeTransaction();
        NSData *archivedData = encodeTransactionString(txValue);

        NSDictionary *query = @{
            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
            (__bridge id)kSecAttrService: serviceKey
        };
        SecItemDelete((__bridge CFDictionaryRef)query);

        NSMutableDictionary *addQuery = [query mutableCopy];
        [addQuery setObject:archivedData forKey:(__bridge id)kSecValueData];
        [addQuery setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];

        OSStatus addStatus = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
        if (addStatus == errSecDuplicateItem) {
            NSDictionary *updateAttrs = @{(__bridge id)kSecValueData: archivedData};
            SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)updateAttrs);
        }
    }
}

#pragma mark - Hooks

static IMP orig_objectForKey = NULL;
- (id)swizzled_objectForKey:(NSString *)key {
    NSArray *targets = @[@"premium", @"pro", @"purchased", @"transaction"];
    for (NSString *target in targets) {
        if ([key rangeOfString:target options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return buildFakeTransaction();
        }
    }
    return ((id (*)(id, SEL, NSString *))orig_objectForKey)(self, _cmd, key);
}

static IMP orig_boolForKey = NULL;
- (BOOL)swizzled_boolForKey:(NSString *)key {
    NSArray *targets = @[@"premium", @"pro", @"purchased", @"transaction"];
    for (NSString *target in targets) {
        if ([key rangeOfString:target options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return ((BOOL (*)(id, SEL, NSString *))orig_boolForKey)(self, _cmd, key);
}

#pragma mark - Main Hack Entry

- (BOOL)hack {
    injectKeychainTransaction();

    Class userDefaultsClass = objc_getClass("NSUserDefaults");
    if (userDefaultsClass) {
        orig_objectForKey = [MemoryUtils hookInstanceMethod:userDefaultsClass
                                           originalSelector:NSSelectorFromString(@"objectForKey:")
                                              swizzledClass:[self class]
                                           swizzledSelector:@selector(swizzled_objectForKey:)];

        orig_boolForKey = [MemoryUtils hookInstanceMethod:userDefaultsClass
                                         originalSelector:NSSelectorFromString(@"boolForKey:")
                                            swizzledClass:[self class]
                                         swizzledSelector:@selector(swizzled_boolForKey:)];
    }
    
    return YES;
}

@end
