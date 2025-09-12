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

@interface MockCKContainer : CKContainer

//    [TEST]
//    CKContainer* container = [CKContainer containerWithIdentifier:@"iCloud.com.example.myapp"];
//    CKDatabase *publicDatabase = [container publicCloudDatabase];
//    CKRecordID *artworkRecordID = [[CKRecordID alloc] initWithRecordName:@"123456"];
//    CKRecord *artworkRecord = [[CKRecord alloc] initWithRecordType:@"Artwork" recordID:artworkRecordID];
//    artworkRecord[@"title" ] = @"this is title";
//    [publicDatabase saveRecord:artworkRecord completionHandler:^(CKRecord *record, NSError *error){
//        if (error) {
//            NSLogger(@"saveRecord error = %@",error);
//        }
//    }];
//    [publicDatabase fetchRecordWithID:artworkRecordID completionHandler:^(CKRecord * _Nullable record, NSError * _Nullable error) {
//        if (error) {
//            NSLogger(@"fetchRecordWithID error = %@",error);
//        }else {
//
//            NSLogger(@"fetchRecordWithID record = %@",record);
//        }
//    }];

@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, readonly) MockCKDatabase *privateDatabase;
@property (nonatomic, readonly) MockCKDatabase *publicDatabase;
@property (nonatomic, strong) NSString *identifier;

+ (instancetype)defaultContainer;
+ (instancetype)containerWithIdentifier:(NSString *)identifier;


- (CKDatabase *)privateCloudDatabase;
- (CKDatabase *)publicCloudDatabase;

/**
 * [CKContainer -accountStatusWithCompletionHandler:(void (^)(CKAccountStatus accountStatus, NSError *error))completionHandler;]
 *  CKAccountStatusAvailable：iCloud is available and logged in
 *  CKAccountStatusNoAccount：Not logged in.
 *  CKAccountStatusRestricted：iCloud is restricted.
 *  CKAccountStatusCouldNotDetermine：Status unknown.
 */
- (void)accountStatusWithCompletionHandler:(void (NS_SWIFT_SENDABLE ^)(CKAccountStatus accountStatus, NSError * error))completionHandler;

@end

#endif /* MockCKContainer_h */
