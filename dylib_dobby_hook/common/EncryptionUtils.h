//
//  encryp_utils.h
//  mac_patch_helper
//
//  Created by voidm on 2024/5/3.
//

#ifndef encryp_utils_h
#define encryp_utils_h
#import <Foundation/Foundation.h>

@interface EncryptionUtils : NSObject

+ (NSString *)runCommand:(NSString *)command trimWhitespace:(BOOL)trim;
+ (NSString *)generateTablePlusDeviceId;

+ (NSString *)generateSurgeDeviceId;
+ (NSString *)calculateMD5:(NSString *) input;

+ (NSString*) calculateSHA1OfFile:(NSString *)filePath;

+ (NSString *)getTextBetween:(NSString *)startText and:(NSString *)endText inString:(NSString *)inputString;

#if TARGET_OS_OSX
+ (BOOL)isCodeSignatureValid;
#endif


//+ (pid_t)getProcessIDByName:(NSString *)name;

@end
#endif /* encryp_utils_h */
