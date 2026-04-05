//
//  JSONUtils.h
//  dylib_dobby_hook
//
//  Created by Hokkaido on 22/10/2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - JSON Macro

/*
Usage examples:

1. C string usage for NSLog hook or C API

const char *json = JSON_CSTR({ "a": 1, "b": 2 });
NSLog(@"%s", json);

2. NSString usage for Objective C

NSString *json = JSON_NSSTR({ "a": 1, "b": 2 });
NSLog(@"%@", json);
*/

#define JSON_CSTR(...) #__VA_ARGS__

#define JSON_NSSTR(...) @#__VA_ARGS__


@interface JSONUtils : NSObject

+ (NSString *)getVFromJSON:(NSString *)jsonString keyName:(NSString *)keyName;
+ (NSString *)jsonStringFromObject:(NSDictionary *)json;
+ (NSDictionary *)dictionaryFromJsonString:(NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END
