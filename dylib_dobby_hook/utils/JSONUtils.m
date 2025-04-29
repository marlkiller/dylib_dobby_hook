//
//  JSONUtils.m
//  dylib_dobby_hook
//
//  Created by Hokkaido on 22/10/2024.
//

#import "JSONUtils.h"

@implementation JSONUtils

+ (NSString *)getVFromJSON:(NSString *)jsonString keyName:(NSString *)keyName {
    if (!jsonString || !keyName) return nil;
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:0
                                                               error:nil];
    id result = jsonDict;
    for (NSString *key in [keyName componentsSeparatedByString:@"."]) {
        if (![result isKindOfClass:[NSDictionary class]]) return nil;
        result = result[key];
    }
    return [result isKindOfClass:[NSString class]] ? result : nil;
}

+ (NSString *)jsonStringFromObject:(NSDictionary *)json {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingWithoutEscapingSlashes error:nil];
    return jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : nil;
}

+ (NSDictionary *)dictionaryFromJsonString:(NSString *)jsonString {
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
    if (error) {
        NSLog(@"Error parsing JSON: %@", error.localizedDescription);
        return nil;
    }
    
    return jsonDict;
}
@end
