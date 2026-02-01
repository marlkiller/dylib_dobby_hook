#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <Security/Security.h>

#pragma mark - Helper Macros

#define HOOK_METHOD(cls, sel, replacement, original) \
    do { \
        Method m = class_getInstanceMethod(cls, sel); \
        if (m) { \
            *(original) = (void *)method_getImplementation(m); \
            method_setImplementation(m, (IMP)(replacement)); \
        } \
    } while(0)

#pragma mark - String Builders

static NSString *buildBundleID(void) {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (!bundleID) {
        NSMutableString *fallback = [NSMutableString string];
        [fallback appendString:@"com.pranapps"];
        [fallback appendString:@"."];
        [fallback appendString:@"ByteHackerNews"];
        return fallback;
    }
    return bundleID;
}

static NSString *buildKeychainService(void) {
    NSMutableString *service = [NSMutableString string];
    [service appendString:buildBundleID()];
    [service appendString:@"."];
    [service appendString:@"productid_transaction"];
    return service;
}

static NSString *buildFakeTransaction(void) {
    NSMutableString *tx = [NSMutableString string];
    [tx appendString:@"hack_upgrade_pro"];
    [tx appendString:@"_"];
    [tx appendString:@"1000000001"];
    return tx;
}

#pragma mark - Keychain Injection

static NSData *encodeTransactionString(NSString *txString) {
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
    NSString *archiveKey = @"productid_transaction";
    [archiver encodeObject:txString forKey:archiveKey];
    [archiver finishEncoding];
    return [archiver encodedData];
}

static void injectKeychainTransaction(void) {
    @autoreleasepool {
        NSString *serviceKey = buildKeychainService();
        NSString *txValue = buildFakeTransaction();
        NSData *archivedData = encodeTransactionString(txValue);

        NSMutableDictionary *deleteQuery = [NSMutableDictionary dictionary];
        [deleteQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [deleteQuery setObject:serviceKey forKey:(__bridge id)kSecAttrService];
        SecItemDelete((__bridge CFDictionaryRef)deleteQuery);

        NSMutableDictionary *addQuery = [NSMutableDictionary dictionary];
        [addQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [addQuery setObject:serviceKey forKey:(__bridge id)kSecAttrService];
        [addQuery setObject:archivedData forKey:(__bridge id)kSecValueData];
        [addQuery setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];

        OSStatus addStatus = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);

        if (addStatus == errSecDuplicateItem) {
            NSMutableDictionary *updateQuery = [NSMutableDictionary dictionary];
            [updateQuery setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
            [updateQuery setObject:serviceKey forKey:(__bridge id)kSecAttrService];

            NSMutableDictionary *updateAttrs = [NSMutableDictionary dictionary];
            [updateAttrs setObject:archivedData forKey:(__bridge id)kSecValueData];

            SecItemUpdate((__bridge CFDictionaryRef)updateQuery, (__bridge CFDictionaryRef)updateAttrs);
        }
    }
}

#pragma mark - NSUserDefaults Hooks (Backup Layer)

static id (*orig_objectForKey)(id, SEL, NSString *) = NULL;
static id hk_objectForKey(id self, SEL _cmd, NSString *key) {
    NSString *kPremium = @"premium";
    NSString *kPro = @"pro";
    NSString *kPurchased = @"purchased";
    NSString *kTransaction = @"transaction";

    if ([key rangeOfString:kPremium].location != NSNotFound ||
        [key rangeOfString:kPro].location != NSNotFound ||
        [key rangeOfString:kPurchased].location != NSNotFound ||
        [key rangeOfString:kTransaction].location != NSNotFound) {
        return buildFakeTransaction();
    }

    return orig_objectForKey ? orig_objectForKey(self, _cmd, key) : nil;
}

static BOOL (*orig_boolForKey)(id, SEL, NSString *) = NULL;
static BOOL hk_boolForKey(id self, SEL _cmd, NSString *key) {
    NSString *kPremium = @"premium";
    NSString *kPro = @"pro";
    NSString *kPurchased = @"purchased";

    if ([key rangeOfString:kPremium].location != NSNotFound ||
        [key rangeOfString:kPro].location != NSNotFound ||
        [key rangeOfString:kPurchased].location != NSNotFound) {
        return YES;
    }

    return orig_boolForKey ? orig_boolForKey(self, _cmd, key) : NO;
}

#pragma mark - AppDelegate Hook (Re-injection)

static BOOL (*orig_didFinishLaunching)(id, SEL, id, id) = NULL;
static BOOL hk_didFinishLaunching(id self, SEL _cmd, id app, id opts) {
    injectKeychainTransaction();
    return orig_didFinishLaunching ? orig_didFinishLaunching(self, _cmd, app, opts) : YES;
}

#pragma mark - Hook Installation

static void installHooks(void) {
    @autoreleasepool {
        Class udClass = [NSUserDefaults class];

        NSString *selObjForKey = @"objectForKey:";
        SEL objSel = NSSelectorFromString(selObjForKey);
        HOOK_METHOD(udClass, objSel, hk_objectForKey, &orig_objectForKey);

        NSString *selBoolForKey = @"boolForKey:";
        SEL boolSel = NSSelectorFromString(selBoolForKey);
        HOOK_METHOD(udClass, boolSel, hk_boolForKey, &orig_boolForKey);

        int numClasses = objc_getClassList(NULL, 0);
        if (numClasses <= 0) return;

        Class *classList = (Class *)malloc(sizeof(Class) * numClasses);
        if (!classList) return;

        objc_getClassList(classList, numClasses);

        Class appDelegateClass = NULL;
        NSString *delegateName = @"AppDelegate";

        for (int i = 0; i < numClasses; i++) {
            const char *className = class_getName(classList[i]);
            if (!className) continue;

            NSString *clsName = [NSString stringWithUTF8String:className];
            if ([clsName isEqualToString:delegateName]) {
                appDelegateClass = classList[i];
                break;
            }

            if (class_conformsToProtocol(classList[i], @protocol(UIApplicationDelegate))) {
                appDelegateClass = classList[i];
                break;
            }
        }

        free(classList);

        if (appDelegateClass) {
            NSString *selDidFinish = @"application:didFinishLaunchingWithOptions:";
            SEL didFinishSel = NSSelectorFromString(selDidFinish);
            HOOK_METHOD(appDelegateClass, didFinishSel, hk_didFinishLaunching, &orig_didFinishLaunching);
        }
    }
}

#pragma mark - Loader Class

@interface HACKPremium : NSObject
+ (instancetype)shared;
- (void)activate;
@end

@implementation HACKPremium

static HACKPremium *_shared = nil;

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[HACKPremium alloc] init];
    });
    return _shared;
}

- (void)activate {
    injectKeychainTransaction();
    installHooks();
}

@end

#pragma mark - Constructor

__attribute__((constructor))
static void initHACKPremium(void) {
    @autoreleasepool {
        [[HACKPremium shared] activate];
    }
}
