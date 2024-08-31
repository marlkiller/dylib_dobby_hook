//
//  hook_protocol.h
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

@protocol HackProtocol

- (NSString *)getAppName;
- (NSString *)getSupportAppVersion;

/**
 * 判断当前应用是否需要注入。
 * 默认根据 AppName 前缀匹配，如果需要自定义，请在实现类中自行实现。
 */
- (BOOL)shouldInject:(NSString *)target;

- (BOOL)hack;
@end

