//
//  MockCKContainer.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/8/3.
//

#import <Foundation/Foundation.h>
#import "MockCKContainer.h"
#import <CloudKit/CloudKit.h>
#import "MockCKDatabase.h"
#import <objc/runtime.h>
#import <AppKit/AppKit.h>
#import "Logger.h"
//
//@interface MockCKDeviceContext : NSObject
//
//@property (nonatomic, strong) NSString *deviceIdentifier;
//@property (nonatomic, strong) NSString *deviceModel;
//@property (nonatomic, strong) NSString *systemVersion;
//@property (nonatomic, strong) NSString *deviceName;
//@property (nonatomic, strong) NSString *localizedModel;
//@property (nonatomic, strong) NSString *systemName;
//
//@end
//
//@implementation MockCKDeviceContext
//
//- (instancetype)init {
//    // [CKDeviceContext alloc];
//    // class_createInstance([CKDeviceContext class], 0);
//    self = [super init];
//    if (self) {
//        NSProcessInfo* processInfo = [NSProcessInfo processInfo];
//        _deviceIdentifier = [[NSUUID UUID] UUIDString];  // Simulated device identifier
//        _deviceModel = [[processInfo hostName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//        _systemVersion = [[NSProcessInfo processInfo] operatingSystemVersionString];
//        _deviceName = [processInfo hostName];
//        _localizedModel = [[processInfo operatingSystemVersionString] stringByAppendingString:@" (macOS)"];
//        _systemName = @"macOS";
//    }
//    return self;
//}
// 
//@end

@implementation MockCKContainer

//- (instancetype)init {
//    self = [super init];
//    self = class_createInstance([MockCKContainer class], 0);
//    if (self) {
//        _privateDatabase = [[MockCKDatabase alloc] init];
//        _publicDatabase = [[MockCKDatabase alloc] init];
//    }
//    return self;
//}

+ (instancetype)defaultContainer {
    static MockCKContainer *defaultContainer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultContainer = [[self alloc] initWithIdentifier:@"default"];
    });
    return defaultContainer;
}

+ (instancetype)containerWithIdentifier:(NSString *)identifier {
    return [[self alloc] initWithIdentifier:identifier];
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    NSLogger(@"initWithIdentifier identifier = %@",identifier);
    if (self) {
        _identifier = [identifier copy];
        _privateDatabase = [[MockCKDatabase alloc] initDatabase];
        _publicDatabase = [[MockCKDatabase alloc] initDatabase];
    }
    return self;
}
- (CKDatabase *)privateCloudDatabase {
    NSLogger(@"privateCloudDatabase");
    return (CKDatabase *)self.privateDatabase;
}

- (CKDatabase *)publicCloudDatabase {
    NSLogger(@"publicCloudDatabase");
    return (CKDatabase *)self.publicDatabase;
}


- (void)accountStatusWithCompletionHandler:(void (NS_SWIFT_SENDABLE ^)(CKAccountStatus accountStatus, NSError * error))completionHandler{
    NSLogger(@"accountStatusWithCompletionHandler");
    CKAccountStatus mockAccountStatus = CKAccountStatusCouldNotDetermine;
    NSError *mockError = nil;
   
    if (completionHandler) {
        completionHandler(mockAccountStatus, mockError);
    }
   
}

//- (MockCKDeviceContext *)deviceContext {
//    return [[MockCKDeviceContext alloc] init];
//}
@end

