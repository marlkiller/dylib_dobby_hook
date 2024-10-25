//
//  JSONUtils.h
//  dylib_dobby_hook
//
//  Created by Hokkaido on 22/10/2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JSONUtils : NSObject

+ (NSString *)getVFromJSON:(NSString *)jsonString keyName:(NSString *)keyName;
+ (NSString *)getJSONObject2String:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
