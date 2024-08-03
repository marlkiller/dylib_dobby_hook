//
//  MockCKContainer.h
//  dylib_dobby_hook
//
//  Created by voidm on 2024/8/3.
//
#import <CloudKit/CloudKit.h>
#import "MockCKDatabase.h"

#ifndef MockCKContainer_h
#define MockCKContainer_h

@interface MockCKContainer : NSObject


@property (nonatomic, readonly) MockCKDatabase *privateDatabase;
@property (nonatomic, readonly) MockCKDatabase *publicDatabase;
@property (nonatomic, strong) NSString *identifier;

+ (instancetype)defaultContainer;
+ (instancetype)containerWithIdentifier:(NSString *)identifier;


- (CKDatabase *)privateCloudDatabase;
- (CKDatabase *)publicCloudDatabase;


@end

#endif /* MockCKContainer_h */
