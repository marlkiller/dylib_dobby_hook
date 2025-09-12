//
//  MockKeychain.m
//  dylib_dobby_hook
//
//  Created by voidm on 2025/6/26.
//
#import "Logger.h"
#import "MockKeychain.h"

@implementation MockKeychain

#if TARGET_OS_OSX
+ (instancetype)sharedStore {
    static MockKeychain *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[self alloc] init];
        // eg: ~/Library/Application Support/${appID}/mock_keychain_store.archive
        NSString *path = [self storeFilePath];
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data) {
            NSError *error = nil;
            NSSet *allowedClasses = [NSSet setWithObjects:[NSArray class], [NSMutableDictionary class], [NSDictionary class], [NSData class], [NSString class], nil];
            NSArray *savedItems = [NSKeyedUnarchiver unarchivedObjectOfClasses:allowedClasses fromData:data error:&error];
            if ([savedItems isKindOfClass:[NSArray class]]) {
                store.items = [savedItems mutableCopy];
            } else {
                store.items = [NSMutableArray array];
            }
        } else {
            store.items = [NSMutableArray array];
        }
    });
    return store;
}

+ (NSString *)storeFilePath {
    static NSString *storeFile = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *appSupportDir = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
        NSString *appID = [[NSBundle mainBundle] bundleIdentifier];
        NSString *dir = [appSupportDir stringByAppendingPathComponent:appID ?: @"default_app"];
        
        NSError *error = nil;
        BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:&error];
               
        storeFile = [dir stringByAppendingPathComponent:@"mock_keychain_store.archive"];
        NSLogger(@"Mock keychain store file path: %@ [%d]", storeFile,created);
    });
    return storeFile;
}


- (void)saveToDisk {
    NSString *path = [[self class] storeFilePath];
    NSError *error = nil;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.items
                                         requiringSecureCoding:NO
                                                         error:&error];
    if (data && !error) {
        [data writeToFile:path atomically:YES];
    }
}

- (NSData *)generate20BytePersistentRef {
    NSUUID *uuid = [NSUUID UUID];
    NSData *uuidData = [uuid.UUIDString dataUsingEncoding:NSUTF8StringEncoding];
    return [uuidData subdataWithRange:NSMakeRange(0, MIN(20, uuidData.length))];
}


- (OSStatus)addItem:(NSDictionary *)attributes returningRef:(SecKeychainItemRef *)ref persistentRef:(NSData **)persistentRef {
    // 查重逻辑
    if ([self itemsMatching:attributes].count > 0) {
        return errSecDuplicateItem;
    }
    // 创建新条目
    NSMutableDictionary *newItem = [attributes mutableCopy];
    newItem[(__bridge id)kSecClass] = attributes[(__bridge id)kSecClass] ?: (__bridge id)kSecClassGenericPassword;
    
    // 生成 persistentRef (20 byte)
    NSData *persRef = [self generate20BytePersistentRef];
    newItem[(__bridge id)kSecValuePersistentRef] = persRef;
    // 添加到存储
    [_items addObject:newItem];
    // 处理返回参数
    if (persistentRef) {
        *persistentRef = persRef;
    }
    if (ref) {
        // 内存引用直接使用 persistentRef
        *ref = (SecKeychainItemRef)CFBridgingRetain(persRef);
    }
    [self saveToDisk];
    return errSecSuccess;
}


- (NSArray<NSDictionary *> *)itemsMatching:(NSDictionary *)query {
    NSMutableArray *results = [NSMutableArray array];
    // 1. 处理 kSecValuePersistentRef 查询（唯一匹配）
    NSData *expectedRef = query[(__bridge id)kSecValuePersistentRef];
    if (expectedRef) {
       for (NSDictionary *item in self.items) {
           NSData *itemRef = item[(__bridge id)kSecValuePersistentRef];
           if ([itemRef isEqual:expectedRef]) {
               [results addObject:item];
               break;
           }
       }
       return results;
    }
  
    // 2. 普通属性查询
    for (NSDictionary *item in self.items) {
        BOOL match = YES;
        for (id key in query) {
            // 跳过控制标志
//            if ([self isControlKey:key]) {
//                continue;
//            }
            id queryValue = query[key];
            id itemValue = item[key];
            
            if (queryValue && ![queryValue isEqual:itemValue]) {
                match = NO;
                break;
            }
        }
        if (match) {
            [results addObject:item];
        }
    }
    return results;
}


- (OSStatus)updateItems:(NSDictionary *)query withAttributes:(NSDictionary *)attrs {
    NSArray *matches = [self itemsMatching:query];
    if (matches.count == 0) return errSecItemNotFound;
    for (NSMutableDictionary *item in self.items) {
        if ([matches containsObject:item]) {
            [item addEntriesFromDictionary:attrs];
        }
    }
    [self saveToDisk];
    return errSecSuccess;
}


- (OSStatus)deleteItems:(NSDictionary *)query {
    NSArray *matches = [self itemsMatching:query];
    if (matches.count == 0) return errSecItemNotFound;
    [self.items removeObjectsInArray:matches];
    [self saveToDisk];
    return errSecSuccess;
}
#else
#endif

@end
