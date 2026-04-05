//
//  entry_utils.m
//  mac_patch_helper
//
//  Created by voidm on 2024/5/3.
//

#import "EncryptionUtils.h"
#import <Security/Security.h>
#import <IOKit/IOKitLib.h>
#import <stdio.h>
#import <stdlib.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#if TARGET_OS_OSX
#import <CoreWLAN/CoreWLAN.h>
#endif
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonCrypto.h>
#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#endif
#import "Logger.h"


@implementation EncryptionUtils

#if TARGET_OS_OSX
+ (NSString *)runCommand:(NSString *)command trimWhitespace:(BOOL)trim {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:@[@"-c", command]];
    NSMutableDictionary *env = [[[NSProcessInfo processInfo] environment] mutableCopy];
    [env removeObjectForKey:@"DYLD_INSERT_LIBRARIES"];
    [task setEnvironment:env];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];

    NSFileHandle *fileHandle = [pipe fileHandleForReading];
    [task launch];
    [task waitUntilExit];
    NSData *outputData = [fileHandle readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    if (trim) {
        outputString = [outputString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    // 日志输出，查看命令状态
    NSLogger(@"[Command] ➜ %@ | Status: %d | Output: %@", command, [task terminationStatus], outputString);

    return outputString;
}

#else
+ (NSString *)runCommand:(NSString *)command trimWhitespace:(BOOL)trim {
    return nil;
}

#endif


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations" // CC_MD5
+ (NSString *)calculateMD5:(NSString *) input {
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}
#pragma clang diagnostic pop

+ (NSString *)calculateSHA1OfFile:(NSString *)filePath {
    // 打开文件
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (!fileHandle) {
        return nil;
    }

    // 初始化 SHA1 上下文
    CC_SHA1_CTX sha1Context;
    CC_SHA1_Init(&sha1Context);

    // 定义一个缓冲区
    static const size_t bufferSize = 4096;
    NSData *fileData;

    // 读取文件数据并更新 SHA1
    while ((fileData = [fileHandle readDataOfLength:bufferSize])) {
        CC_SHA1_Update(&sha1Context, [fileData bytes], (CC_LONG)[fileData length]);
        if ([fileData length] == 0) {
            break;
        }
    }

    // 关闭文件
    [fileHandle closeFile];

    // 完成 SHA1 计算
    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_Final(hash, &sha1Context);

    // 将 SHA1 值转换为 NSString
    NSMutableString *hashString = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [hashString appendFormat:@"%02x", hash[i]];
    }

    return hashString;
}

+ (NSString *)getTextBetween:(NSString *)startText and:(NSString *)endText inString:(NSString *)inputString {
    // 查找 startText 在 inputString 中的位置
    NSRange startRange = [inputString rangeOfString:startText];
    
    // 如果没找到 startText，返回 nil
    if (startRange.location == NSNotFound) {
        return nil;
    }
    
    // 从 startText 的结尾开始查找 endText
    NSRange searchRange;
    searchRange.location = startRange.location + startRange.length;
    searchRange.length = inputString.length - searchRange.location;
    
    NSRange endRange = [inputString rangeOfString:endText options:0 range:searchRange];
    
    // 如果没找到 endText，返回 nil
    if (endRange.location == NSNotFound) {
        return nil;
    }
    
    // 计算 startText 和 endText 之间的范围
    NSRange resultRange = NSMakeRange(searchRange.location, endRange.location - searchRange.location);
    
    // 截取并返回这个范围内的文本
    return [inputString substringWithRange:resultRange];
}

#if TARGET_OS_OSX
+ (BOOL)isCodeSignatureValid {
    
    SecCodeRef code = NULL;
    OSStatus status = SecCodeCopySelf(kSecCSDefaultFlags, &code);
    if (status != errSecSuccess) {
        NSLogger(@"[Error] Failed to get current app code: %d", (int)status);
        return NO;
    }

    CFDictionaryRef csInfo = NULL;
    status = SecCodeCopySigningInformation(code, kSecCSSigningInformation, &csInfo);
    if (status != errSecSuccess) {
        NSLogger(@"[Error] SecCodeCopySigningInformation failed with status = %d", (int)status);
        if (code) CFRelease(code);
        return NO;
    }

    // 检查签名是否有效
    SecCSFlags flags = 0;
    CFNumberRef flagsNumber = (CFNumberRef)CFDictionaryGetValue(csInfo, kSecCodeInfoFlags);
    if (flagsNumber == NULL) {
        NSLogger(@"[Error] kSecCodeInfoFlags is nil");
        CFRelease(csInfo);
        CFRelease(code);
        return NO;
    }

    CFNumberGetValue(flagsNumber, kCFNumberSInt32Type, &flags);
    NSLogger(@"Flags: %d", flags);

//    flags : https://developer.apple.com/documentation/security/seccodesignatureflags/forcekill?language=objc
//    codesign -d -vvv /xxx
//    0x0    none    没有额外标志
//    0x0001    kSecCodeSignatureHost    允许代码充当 动态代码加载的宿主（host），如插件或扩展
//    0x0002    kSecCodeSignatureAdhoc    该签名是 临时签名（Ad-Hoc），即没有使用 Apple 颁发的证书签名
//    0x0100    kSecCodeSignatureForceHard    强制启用 Hardened Runtime，即使没有在 codesign 选项中指定
//    0x0200    kSecCodeSignatureForceKill    进程如果违反签名策略，将被 立即终止（kill）
//    0x0400    kSecCodeSignatureForceExpiration    代码签名具有 有效期限制，过期后无法执行
//    0x0800    kSecCodeSignatureRestrict    限制代码只能加载 Apple 认可的动态库或插件
//    0x1000    kSecCodeSignatureEnforcement    强制执行代码签名检查，不允许加载未签名或签名不受信任的代码
//    0x2000    kSecCodeSignatureLibraryValidation    启用动态库验证，防止加载未签名或不受信任的动态库
//    0x10000    kSecCodeSignatureRuntime    启用 Hardened Runtime，增加代码完整性检查，防止调试、代码注入等攻击
//    0x20000    kSecCodeSignatureLinkerSigned    代码已被 链接器（Linker）签名，适用于某些特殊情况下的代码签名
    
    const int CS_VALID = 0x00000001;   // 签名是有效的
    const int CS_RUNTIME = 0x00010000; // 启用了 "hardened runtime" 的应用
    const int CS_HARD = 0x00000002;    // 强制代码签名（hardened code）

    if (flags & CS_HARD) {
        NSLogger(@"App has hardened code signature.");
    }

    if (!(flags & CS_VALID) && !(flags & CS_RUNTIME)) {
        NSLogger(@"[Error] App signature is not valid or does not have hardened runtime.");
        CFRelease(csInfo);
        CFRelease(code);
        return NO;
    }

    NSLogger(@"Code signature is valid.");
    
    CFRelease(csInfo);
    CFRelease(code);
    return YES;
}
#endif



//+ (pid_t)getProcessIDByName:(NSString *)name {
//    NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
//    for (NSRunningApplication *app in runningApps) {
//        if ([[app localizedName] isEqualToString:name]) {
//            pid_t pid = [app processIdentifier];
//            NSLogger(@"pid is %d",pid);
//            return pid;
//        }
//    }
//    return -1; // 进程未找到
//}

@end
