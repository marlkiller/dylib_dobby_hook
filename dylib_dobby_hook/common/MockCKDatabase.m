//
//  MockCKDatabase.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/8/3.
//

#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>
#import "MockCKDatabase.h"
#import "Logger.h"

@implementation MockCKDatabase

- (instancetype)initDatabase {
    // self = [super init];
    if (self) {
        // TODO: 是否需要考虑数据持久华 ?
        // _records = [self loadPersistedDataForKey:@"records"];

        _records = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)saveRecord:(CKRecord *)record completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler {
    NSLogger(@"saveRecord record = %@",record);
    self.records[record.recordID] = record;
    if (completionHandler) {
        completionHandler(record, nil);
    }
}

- (void)fetchRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler {
    NSLogger(@"fetchRecordWithID recordID = %@",recordID);
    CKRecord *record = self.records[recordID];
    if (completionHandler) {
        completionHandler(record, nil);
    }
}

- (void)deleteRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(NSError *error))completionHandler {
    NSLogger(@"deleteRecordWithID recordID = %@",recordID);
    [self.records removeObjectForKey:recordID];
    if (completionHandler) {
        completionHandler(nil);
    }
}

- (void)performQuery:(CKQuery *)query inZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(NSArray<CKRecord *> *records, NSError *error))completionHandler {
    NSLogger(@"performQuery query = %@,zoneID = %@",query,zoneID);
    NSPredicate *predicate = query.predicate;
    NSMutableArray<CKRecord *> *results = [NSMutableArray array];
    
    for (CKRecord *record in self.records.allValues) {
        if ([predicate evaluateWithObject:record]) {
            [results addObject:record];
        }
    }
    
    if (completionHandler) {
        completionHandler(results, nil);
    }
}

- (void)fetchAllRecordsWithCompletion:(void (^)(NSArray<CKRecord *> *records, NSError *error))completionHandler {
    NSLogger(@"fetchAllRecordsWithCompletion");

    if (completionHandler) {
        completionHandler(self.records.allValues, nil);
    }
}


- (void)addOperation:(NSOperation *)operation {
    NSString *operationClass = NSStringFromClass([operation class]);
    BOOL isAsynchronous = [operation isAsynchronous];
    BOOL isReady = [operation isReady];
    BOOL isExecuting = [operation isExecuting];
    BOOL isFinished = [operation isFinished];
    BOOL isCancelled = [operation isCancelled];
    
    NSLogger(@"addOperation operation: %@\nClass: %@\nIs Asynchronous: %@\nIs Ready: %@\nIs Executing: %@\nIs Finished: %@\nIs Cancelled: %@",
          operation,
          operationClass,
          isAsynchronous ? @"YES" : @"NO",
          isReady ? @"YES" : @"NO",
          isExecuting ? @"YES" : @"NO",
          isFinished ? @"YES" : @"NO",
          isCancelled ? @"YES" : @"NO");
   
    if (isAsynchronous && [operation isReady]) {
        // 模拟操作执行
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (operation.completionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    operation.completionBlock();
                });
            }
        });
    }
}



- (void)fetchAllRecordZonesWithCompletionHandler:(void (^)(NSArray<CKRecordZone *> * zones, NSError * error))completionHandler {
    NSLogger(@"fetchAllRecordZonesWithCompletionHandler");
    NSArray<CKRecordZone *> *zones = [_recordZones allValues];
    completionHandler(zones, nil);
}
- (void)fetchRecordZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(CKRecordZone * zone, NSError * error))completionHandler {
    NSLogger(@"fetchRecordZoneWithID zoneID = %@",zoneID);
    CKRecordZone *zone = _recordZones[zoneID];
    if (zone) {
        completionHandler(zone, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Record zone not found"}];
        completionHandler(nil, error);
    }
}

- (void)saveRecordZone:(CKRecordZone *)zone completionHandler:(void (^)(CKRecordZone * zone, NSError * error))completionHandler {
    NSLogger(@"saveRecordZone zone = %@",zone);
    _recordZones[zone.zoneID] = zone;
    completionHandler(zone, nil);
}

- (void)deleteRecordZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(CKRecordZoneID * zoneID, NSError * error))completionHandler {
    NSLogger(@"deleteRecordZoneWithID zoneID = %@",zoneID);
    if (_recordZones[zoneID]) {
        [_recordZones removeObjectForKey:zoneID];
        completionHandler(zoneID, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Record zone not found"}];
        completionHandler(nil, error);
    }
}


- (void)fetchSubscriptionWithID:(CKSubscriptionID)subscriptionID completionHandler:(void (^)(CKSubscription * subscription, NSError * error))completionHandler {
    NSLogger(@"fetchSubscriptionWithID subscriptionID = %@",subscriptionID);
    CKSubscription *subscription = _subscriptions[subscriptionID];
    if (subscription) {
        completionHandler(subscription, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Subscription not found"}];
        completionHandler(nil, error);
    }
}

- (void)fetchAllSubscriptionsWithCompletionHandler:(void (^)(NSArray<CKSubscription *> * subscriptions, NSError * error))completionHandler {
    NSLogger(@"fetchAllSubscriptionsWithCompletionHandler");
    completionHandler(_subscriptions.allValues, nil);
}

- (void)saveSubscription:(CKSubscription *)subscription completionHandler:(void (^)(CKSubscription * subscription, NSError * error))completionHandler {
    NSLogger(@"saveSubscription subscription = %@",subscription);
    _subscriptions[subscription.subscriptionID] = subscription;
    completionHandler(subscription, nil);
}

- (void)deleteSubscriptionWithID:(CKSubscriptionID)subscriptionID completionHandler:(void (^)(CKSubscriptionID subscriptionID, NSError * error))completionHandler {
    NSLogger(@"deleteSubscriptionWithID subscriptionID = %@",subscriptionID);
    if (_subscriptions[subscriptionID]) {
        [_subscriptions removeObjectForKey:subscriptionID];
        completionHandler(subscriptionID, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Subscription not found"}];
        completionHandler(nil, error);
    }
}

#pragma mark - Persistence Methods
//
//- (void)persistData:(NSDictionary *)data forKey:(NSString *)key {
//    NSString *path = [self pathForKey:key];
//    [NSKeyedArchiver archiveRootObject:data toFile:path];
//}
//
//- (NSMutableDictionary *)loadPersistedDataForKey:(NSString *)key {
//    NSString *path = [self pathForKey:key];
//    return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
//}
//
//- (NSString *)pathForKey:(NSString *)key {
//    NSString *documentDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//    return [documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat", key]];
//}


@end

