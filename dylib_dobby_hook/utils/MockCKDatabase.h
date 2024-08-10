//
//  MockCKDatabase.h
//  dylib_dobby_hook
//
//  Created by voidm on 2024/8/3.
//
#import <CloudKit/CloudKit.h>

#ifndef MockCKDatabase_h
#define MockCKDatabase_h


@interface MockCKDatabase : CKDatabase

@property (nonatomic, strong) NSMutableDictionary<CKRecordID *, CKRecord *> * records;
@property (nonatomic, strong) NSMutableDictionary<CKRecordZoneID *, CKRecordZone *> *recordZones;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CKSubscription *> *subscriptions;

- (instancetype)initDatabase ;

- (void)saveRecord:(CKRecord *)record completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler;
- (void)fetchRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler;
- (void)deleteRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(NSError *error))completionHandler;
- (void)performQuery:(CKQuery *)query inZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(NSArray<CKRecord *> *records, NSError *error))completionHandler;
- (void)fetchAllRecordsWithCompletion:(void (^)(NSArray<CKRecord *> *records, NSError *error))completionHandler;
- (void)addOperation:(NSOperation *)operation;

- (void)fetchAllRecordZonesWithCompletionHandler:(void (^)(NSArray<CKRecordZone *> * zones, NSError * error))completionHandler;
- (void)fetchRecordZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(CKRecordZone *  zone, NSError *  error))completionHandler;
- (void)saveRecordZone:(CKRecordZone *)zone completionHandler:(void (^)(CKRecordZone *  zone, NSError *  error))completionHandler;
- (void)deleteRecordZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(CKRecordZoneID *  zoneID, NSError * error))completionHandler;

- (void)fetchSubscriptionWithID:(CKSubscriptionID  )subscriptionID completionHandler:(void (^)(CKSubscription *  subscription, NSError * error))completionHandler;
- (void)fetchAllSubscriptionsWithCompletionHandler:(void (^)(NSArray<CKSubscription *> *  subscriptions, NSError *  error))completionHandler;
- (void)saveSubscription:(CKSubscription *)subscription completionHandler:(void (^)(CKSubscription *  subscription, NSError *  error))completionHandler;
- (void)deleteSubscriptionWithID:(CKSubscriptionID)subscriptionID completionHandler:(void (^)(CKSubscriptionID  subscriptionID, NSError *  error))completionHandler;
@end


#endif /* MockCKDatabase_h */
