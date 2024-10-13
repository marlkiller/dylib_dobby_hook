//
//  LocalizationManager.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/10/11.
//

#import <Foundation/Foundation.h>
#import <LocalizationManager.h>

@implementation LocalizationManager

+ (NSString *)localizedStringForKey:(NSString *)key {
    // 定义不同语言的字符串
    static NSDictionary *localizations;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localizations = @{
            @"en": @{
                @"alert_tip": @"Tip",
                @"alert_message": @"If only time could stop at the moment we first met.",
                @"alert_button": @"OK"
            },
            @"zh": @{
                @"alert_tip": @"提示",
                @"alert_message": @"人生若只如初见 。",
                @"alert_button": @"确定"
            }
        };
    });

    NSString *language = [[NSLocale preferredLanguages] firstObject];
    if ([language hasPrefix:@"zh"]) {
        // zh-Hans-CN
        language = @"zh";
    }
    NSDictionary *strings = localizations[language] ?: localizations[@"zh"];
    return strings[key] ?: @"";
}

@end
