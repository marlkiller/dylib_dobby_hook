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


@implementation MockCKContainer

- (instancetype)init {
    self = [super init];
    if (self) {
        _privateDatabase = [[MockCKDatabase alloc] init];
        _publicDatabase = [[MockCKDatabase alloc] init];
    }
    return self;
}

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
    NSLog(@">>>>>> initWithIdentifier identifier = %@",identifier);
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _privateDatabase = [[MockCKDatabase alloc] init];
        _publicDatabase = [[MockCKDatabase alloc] init];
    }
    return self;
}
- (CKDatabase *)privateCloudDatabase {
    NSLog(@">>>>>> privateCloudDatabase");
    return (CKDatabase *)self.privateDatabase;
}

- (CKDatabase *)publicCloudDatabase {
    NSLog(@">>>>>> publicCloudDatabase");
    return (CKDatabase *)self.publicDatabase;
}

@end

