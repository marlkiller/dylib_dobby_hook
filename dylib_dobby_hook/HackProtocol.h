//
//  hook_protocol.h
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

@protocol HackProtocol

- (NSString *)getAppName;
- (NSString *)getSupportAppVersion;
- (BOOL)hack;
@end
