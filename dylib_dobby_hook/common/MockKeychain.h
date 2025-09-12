//
//  MockKeychain.h
//  dylib_dobby_hook
//
//  Created by voidm on 2025/6/26.
//

#ifndef MockKeychain_h
#define MockKeychain_h
#import <Foundation/Foundation.h>

@interface MockKeychain : NSObject

#if TARGET_OS_OSX
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *items;
+ (instancetype)sharedStore;
//@property (nonatomic, strong) NSMutableDictionary<NSData *, NSMutableDictionary *> *persistentRefMap;
- (OSStatus)addItem:(NSDictionary *)attributes returningRef:(SecKeychainItemRef *)ref persistentRef:(NSData **)persistentRef;
- (NSArray<NSDictionary *> *)itemsMatching:(NSDictionary *)query;
- (OSStatus)updateItems:(NSDictionary *)query withAttributes:(NSDictionary *)attributes;
- (OSStatus)deleteItems:(NSDictionary *)query;
#else
#endif

@end


#endif /* MockKeychain_h */
