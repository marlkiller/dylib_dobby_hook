//
//  MockCKDatabase.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/8/3.
//

#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>
#import "MockCKDatabase.h"

@implementation MockCKDatabase

- (instancetype)init {
    self = [super init];
    if (self) {
        _records = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)saveRecord:(CKRecord *)record
         completion:(void (^)(CKRecord *record, NSError *error))completion {
    NSLog(@">>>>>> saveRecord record = %@",record);
    self.records[record.recordID] = record;
    if (completion) {
        completion(record, nil);
    }
}

- (void)fetchRecordWithID:(CKRecordID *)recordID
               completion:(void (^)(CKRecord *record, NSError *error))completion {
    NSLog(@">>>>>> fetchRecordWithID recordID = %@",recordID);
    CKRecord *record = self.records[recordID];
    if (completion) {
        completion(record, nil);
    }
}

- (void)deleteRecordWithID:(CKRecordID *)recordID
                completion:(void (^)(NSError *error))completion {
    NSLog(@">>>>>> deleteRecordWithID recordID = %@",recordID);
    [self.records removeObjectForKey:recordID];
    if (completion) {
        completion(nil);
    }
}

- (void)performQuery:(CKQuery *)query
          inZoneWithID:(CKRecordZoneID *)zoneID
           completion:(void (^)(NSArray<CKRecord *> *records, NSError *error))completion {
    NSLog(@">>>>>> performQuery query = %@,zoneID = %@",query,zoneID);
    NSPredicate *predicate = query.predicate;
    NSMutableArray<CKRecord *> *results = [NSMutableArray array];
    
    for (CKRecord *record in self.records.allValues) {
        if ([predicate evaluateWithObject:record]) {
            [results addObject:record];
        }
    }
    
    if (completion) {
        completion(results, nil);
    }
}

- (void)fetchAllRecordsWithCompletion:(void (^)(NSArray<CKRecord *> *records, NSError *error))completion {
    NSLog(@">>>>>> fetchAllRecordsWithCompletion");

    if (completion) {
        completion(self.records.allValues, nil);
    }
}


- (void)addOperation:(NSOperation *)operation {
    NSLog(@">>>>>> TODO addOperation operation = %@", operation);
}

- (void)fetchAllRecordZonesWithCompletionHandler:(void (^)(NSArray<CKRecordZone *> * zones, NSError * error))completionHandler {
    NSLog(@">>>>>> fetchAllRecordZonesWithCompletionHandler");
    NSArray<CKRecordZone *> *zones = [_recordZones allValues];
    completionHandler(zones, nil);
}
- (void)fetchRecordZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(CKRecordZone * zone, NSError * error))completionHandler {
    NSLog(@">>>>>> fetchRecordZoneWithID zoneID = %@",zoneID);
    CKRecordZone *zone = _recordZones[zoneID];
    if (zone) {
        completionHandler(zone, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Record zone not found"}];
        completionHandler(nil, error);
    }
}

- (void)saveRecordZone:(CKRecordZone *)zone completionHandler:(void (^)(CKRecordZone * zone, NSError * error))completionHandler {
    NSLog(@">>>>>> saveRecordZone zone = %@",zone);
    _recordZones[zone.zoneID] = zone;
    completionHandler(zone, nil);
}

- (void)deleteRecordZoneWithID:(CKRecordZoneID *)zoneID completionHandler:(void (^)(CKRecordZoneID * zoneID, NSError * error))completionHandler {
    NSLog(@">>>>>> deleteRecordZoneWithID zoneID = %@",zoneID);
    if (_recordZones[zoneID]) {
        [_recordZones removeObjectForKey:zoneID];
        completionHandler(zoneID, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Record zone not found"}];
        completionHandler(nil, error);
    }
}


- (void)fetchSubscriptionWithID:(CKSubscriptionID)subscriptionID completionHandler:(void (^)(CKSubscription * subscription, NSError * error))completionHandler {
    NSLog(@">>>>>> fetchSubscriptionWithID subscriptionID = %@",subscriptionID);
    CKSubscription *subscription = _subscriptions[subscriptionID];
    if (subscription) {
        completionHandler(subscription, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Subscription not found"}];
        completionHandler(nil, error);
    }
}

- (void)fetchAllSubscriptionsWithCompletionHandler:(void (^)(NSArray<CKSubscription *> * subscriptions, NSError * error))completionHandler {
    NSLog(@">>>>>> fetchAllSubscriptionsWithCompletionHandler");
    completionHandler(_subscriptions.allValues, nil);
}

- (void)saveSubscription:(CKSubscription *)subscription completionHandler:(void (^)(CKSubscription * subscription, NSError * error))completionHandler {
    NSLog(@">>>>>> saveSubscription subscription = %@",subscription);
    _subscriptions[subscription.subscriptionID] = subscription;
    completionHandler(subscription, nil);
}

- (void)deleteSubscriptionWithID:(CKSubscriptionID)subscriptionID completionHandler:(void (^)(CKSubscriptionID subscriptionID, NSError * error))completionHandler {
    NSLog(@">>>>>> deleteSubscriptionWithID subscriptionID = %@",subscriptionID);
    if (_subscriptions[subscriptionID]) {
        [_subscriptions removeObjectForKey:subscriptionID];
        completionHandler(subscriptionID, nil);
    } else {
        NSError *error = [NSError errorWithDomain:@"MockCKDatabase" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Subscription not found"}];
        completionHandler(nil, error);
    }
}

@end

