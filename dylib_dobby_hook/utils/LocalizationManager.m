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
                @"alert_tip": @"Notice",
                @"alert_message": @"This is a cracked version provided for free and open source. If you paid for this software, please report the seller, leave negative feedback, and avoid further purchases.\n\nDisclaimer: This version is for educational and research purposes only. The developers take no responsibility for any consequences arising from its use.",
                @"alert_button": @"OK"
            },
            @"zh": @{
                @"alert_tip": @"免责声明",
                @"alert_message": @"当前为免费开源的破解版本。如您是付费购买所得，请及时举报售卖渠道并给予差评，避免他人受骗。\n\n免责声明：本版本仅供学习与研究用途，开发者不对由此产生的任何后果承担责任。",
                @"alert_button": @"我知道了"
            }
        };
    });

    NSString *language = [[NSLocale preferredLanguages] firstObject];
    if ([language hasPrefix:@"zh"]) {
        language = @"zh"; // zh-Hans,zh-Hant-TW,zh-Hant-HK
    } else if ([language hasPrefix:@"en"]) {
        language = @"en"; // en-US,en-GB
    }
    NSDictionary *strings = localizations[language] ?: localizations[@"zh"];
    return strings[key] ?: @"";
}

@end
