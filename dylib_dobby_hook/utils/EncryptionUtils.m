//
//  entry_utils.m
//  mac_patch_helper
//
//  Created by voidm on 2024/5/3.
//

#import <Foundation/Foundation.h>
#import "EncryptionUtils.h"
#import <Security/Security.h>
#import <IOKit/IOKitLib.h>
#import <stdio.h>
#import <stdlib.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <CoreWLAN/CoreWLAN.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonCrypto.h>
#import <Cocoa/Cocoa.h>
#import "Logger.h"


@implementation EncryptionUtils

+ (NSString *)runCommand:(NSString *)command trimWhitespace:(BOOL)trim {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:@[@"-c", command]];

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
    NSLogger(@"[Command] ➜ %@ | Status: %d | Output: %@",
              command, [task terminationStatus], outputString);
    return outputString;
}


+ (NSString *)generateTablePlusDeviceId{


//    mac=$(networksetup -getmacaddress en0| grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
//    Serial=$(system_profiler SPHardwareDataType | grep Serial | awk '{print $4}')
//    deviceID=$(echo -n "${mac}${Serial}" | md5)
//    echo $deviceID
//    f0:18:98:1b:24:20C02X51AJJG5J > md5 = ee4f1d1890b4eb49a5a4d7f195ca8b67
    NSString *mac = [self runCommand:@"networksetup -getmacaddress en0| grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'" trimWhitespace:YES];
    NSString *Serial = [self runCommand:@"system_profiler SPHardwareDataType | grep Serial | awk '{print $4}'" trimWhitespace:YES];
    return [self runCommand:[NSString stringWithFormat:@"printf '%%s' \"%@%@\" | md5", mac, Serial] trimWhitespace:YES];
   
}

+ (NSString *)generateSurgeDeviceId{
    
    NSMutableArray *rbx = [NSMutableArray array];

   
    // IOPlatformUUID
    io_service_t masterPort;
    io_service_t platformExpert;
    CFTypeRef uuidRef;
    masterPort = IO_OBJECT_NULL;
    platformExpert = IOServiceGetMatchingService(masterPort, IOServiceMatching("IOPlatformExpertDevice"));
    uuidRef = IORegistryEntryCreateCFProperty(platformExpert, CFSTR("IOPlatformUUID"), kCFAllocatorDefault, 0);
    NSString *uuidString = (__bridge NSString *)uuidRef;
    CFRelease(uuidRef);
    IOObjectRelease(platformExpert);
    [rbx addObject:uuidString];
    NSLogger(@"IOPlatformUUID : %@",uuidString);
    // 9B37DA4D-B136-5AAE-BED8-F16E5BB0E199 --> MD5 : E05B9A7B7518C259C5BF6D2F5ABF6BD7

    
    // hw.model
    char model[256];
    size_t size = sizeof(model);
    if (sysctlbyname("hw.model", model, &size, NULL, 0) == 0) {
        NSString *hwModel = [NSString stringWithUTF8String:model];
        [rbx addObject:hwModel];
        NSLogger(@"hw.model : %@",hwModel);
        // MacBookPro15,1
    }
    
    // machdep.cpu.brand_string
    size = sizeof(model); // 重新设置size
    if (sysctlbyname("machdep.cpu.brand_string", model, &size, NULL, 0) == 0) {
        NSString *cpu = [NSString stringWithUTF8String:model];
        [rbx addObject:cpu];
        NSLogger(@"machdep.cpu.brand_string : %@",cpu);
        // MacBookPro15,1
    }
    
    // machdep.cpu.signature
    int64_t signature = 0;
    size_t signatureSize = sizeof(signature);
    if (sysctlbyname("machdep.cpu.signature",  &signature, &signatureSize, NULL, 0) == 0) {
        
        NSNumber *numberSignature = [NSNumber numberWithLongLong:signature];
        [rbx addObject:numberSignature];
        NSLogger(@"machdep.cpu.signature: %@", numberSignature);
        // 591594
    }else{
        [rbx addObject:@0];
    }
    // hw.memsize
    int64_t memsize;
    size_t size_memsize = sizeof(memsize);
    if (sysctlbyname("hw.memsize", &memsize, &size_memsize, NULL, 0) == 0) {
        NSNumber *numberMemsize = [NSNumber numberWithLongLong:memsize];
        [rbx addObject:numberMemsize];
        NSLogger(@"hw.memsize: %@", numberMemsize);
    }else {
        [rbx addObject:@"#"];
        NSLogger(@"hw.memsize: %s", "#");
    }
    
    // /Users/voidm/Library/Preferences/com.nssurge.surge-mac.plist
    bool ActivationCompatibilityMode = false;
    
    CWWiFiClient *wifiClient = [CWWiFiClient sharedWiFiClient];
    CWInterface *wifiInterface = [wifiClient interface];
    NSString *hardwareAddress = [wifiInterface hardwareAddress];
    NSLogger(@"Hardware Address: %@", hardwareAddress);
    [rbx addObject:hardwareAddress];

    // f0:18:98:1b:24:20
    
    if (!ActivationCompatibilityMode) {
        // com.nssurge.surge-mac.nsa.wifimac: e05b9a7b7518c259c5bf6d2f5abf6bd7/f0:18:98:1b:24:20       
    }
    
    NSString *joinedString = [rbx componentsJoinedByString:@"/"];
    // 9B37DA4D-B136-5AAE-BED8-F16E5BB0E199/MacBookPro15,1/Intel(R) Core(TM) i7-8850H CPU @ 2.60GHz/591594/17179869184/f0:18:98:1b:24:20
    // E9EFB28F-053B-5C48-BAA0-E6A055AD806F/MacBookPro17,1/Apple M1/0/8589934592/3c:06:30:30:7d:35
    NSLogger(@"joinedString %@", joinedString);
    NSString *deviceIdMD5 = [self calculateMD5:joinedString];
    // 36d7a97a91b82ce5bc8b2609d4e17dae
    NSLogger(@"deviceIdMD5 %@", deviceIdMD5);
    return deviceIdMD5;
};


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


+ (NSDictionary *)generateKeyPair:(bool)is_pkcs8 {
    
    // 设置密钥参数
    NSDictionary *parameters = @{
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
        (__bridge id)kSecAttrKeySizeInBits: @2048
    };
    
    // 生成密钥对
    SecKeyRef publicKey, privateKey;
    //    OSStatus status = SecKeyGeneratePair((__bridge CFDictionaryRef)parameters, &publicKey, &privateKey);
    CFErrorRef error = NULL;
    privateKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)parameters, &error);
    if (error != NULL) {       
        NSLogger(@"密钥生成失败: %@", error);
        return nil;
    }
    
    publicKey = SecKeyCopyPublicKey(privateKey);
    
    // 将密钥转换为字符串
    NSData *publicKeyData = CFBridgingRelease(SecKeyCopyExternalRepresentation(publicKey, nil));
    NSData *privateKeyData = CFBridgingRelease(SecKeyCopyExternalRepresentation(privateKey, nil));
    
    if (is_pkcs8) {
        publicKeyData = [self addPublicKeyHeader:publicKeyData];
        privateKeyData = [self addPrivateKeyHeader:privateKeyData];
    }
    
    
    
    NSString *publicKeyString = [self convertToPEMFormat:publicKeyData withKeyType:@"PUBLIC"];
    NSString *privateKeyString = [self convertToPEMFormat:privateKeyData withKeyType:@"PRIVATE"];
    
//    NSString *publicKeyString = [publicKeyData base64EncodedStringWithOptions:0];
//    NSString *privateKeyString = [privateKeyData base64EncodedStringWithOptions:0];
    // 返回密钥对
    return @{
        @"publicKey": publicKeyString,
        @"privateKey": privateKeyString
    };
}


+ (NSData *)generateSignatureForData:(NSData *)data privateKey:(NSString *)privateKeyString isPKCS8:(bool)is_pkcs8 {
    NSArray *components = [privateKeyString componentsSeparatedByString:@"\n"];
    NSMutableArray *cleanedComponents = [NSMutableArray arrayWithArray:components];
    [cleanedComponents removeObject:@""];
    [cleanedComponents removeObject:@"-----BEGIN RSA PRIVATE KEY-----"];
    [cleanedComponents removeObject:@"-----END RSA PRIVATE KEY-----"];
    [cleanedComponents removeObject:@"-----BEGIN PRIVATE KEY-----"];
    [cleanedComponents removeObject:@"-----END PRIVATE KEY-----"];
    // 将剩余的字符串拼接为单个字符串
    NSString *cleanedString = [cleanedComponents componentsJoinedByString:@""];
    
    // 解码 Base64 字符串为 NSData
    NSData *privateKeyData = [[NSData alloc] initWithBase64EncodedString:cleanedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (is_pkcs8) {
        privateKeyData = [self removePrivateKeyHeader:privateKeyData];
    }
    // 创建私钥字典
    NSDictionary *attributes = @{
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPrivate,
    };
    
    SecKeyRef privateKey = NULL;
    // 创建私钥对象
    CFErrorRef error = NULL;
    privateKey = SecKeyCreateWithData((__bridge CFDataRef)privateKeyData, (__bridge CFDictionaryRef)attributes, &error);
    
    // 签名数据
    SecKeyAlgorithm algorithm = kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256;
    CFDataRef signedDataRef = SecKeyCreateSignature(privateKey, algorithm, (__bridge CFDataRef)data, &error);
    
    NSData *signedData = (__bridge NSData *)signedDataRef;
    
    if (error != NULL) {
        NSLogger(@"Signature generation failed: %@", (__bridge NSError *)error);
        if (signedDataRef != NULL) {
            CFRelease(signedDataRef);
        }
        return nil;
    }
    
    return signedData;
}


+ (BOOL)verifySignatureWithBase64:(NSString *)policy signature:(NSString *)sign publicKey:(NSString *)publicKeyString isPKCS8:(bool)is_pkcs8{
    
    NSData *policyData = [[NSData alloc] initWithBase64EncodedString:policy options:0];
    NSData *signData = [[NSData alloc] initWithBase64EncodedString:sign options:0];
    return [self verifySignatureWithByte:policyData signature:signData publicKey:publicKeyString isPKCS8:(bool)is_pkcs8];
    
    
}

+ (BOOL)verifySignatureWithByte:(NSData *)policyData signature:(NSData *)signData publicKey:(NSString *)publicKeyString isPKCS8:(bool)is_pkcs8{
    NSArray *components = [publicKeyString componentsSeparatedByString:@"\n"];
    NSMutableArray *cleanedComponents = [NSMutableArray arrayWithArray:components];
    [cleanedComponents removeObject:@""];
    [cleanedComponents removeObject:@"-----BEGIN PUBLIC KEY-----"];
    [cleanedComponents removeObject:@"-----END PUBLIC KEY-----"];
    
    // 将剩余的字符串拼接为单个字符串
    NSString *cleanedString = [cleanedComponents componentsJoinedByString:@""];
    
    // 解码 Base64 字符串为 NSData
    NSData *publicKeyData = [[NSData alloc] initWithBase64EncodedString:cleanedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (is_pkcs8) {
        publicKeyData = [self removePublicKeyHeader:publicKeyData];
    }
    // 创建公钥字典
    NSDictionary *attributes = @{
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPublic,
    };
    
    SecKeyRef publicKey = NULL;
    // 创建公钥对象
    CFErrorRef error1 = NULL;
    publicKey = SecKeyCreateWithData((__bridge CFDataRef)publicKeyData, (__bridge CFDictionaryRef)attributes, &error1);
    
    SecKeyAlgorithm algorithm = kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256;
    BOOL verificationResult = SecKeyVerifySignature(publicKey, algorithm, (__bridge CFDataRef)policyData, (__bridge CFDataRef)signData, NULL);
    
    return verificationResult;
}

// PUBLIC,PRIVATE,RSA PRIVATE
+ (NSString *)convertToPEMFormat:(NSData *)keyData withKeyType:(NSString *)keyType {
    NSString *header = [NSString stringWithFormat:@"-----BEGIN %@ KEY-----\n", keyType];
    NSString *footer = [NSString stringWithFormat:@"-----END %@ KEY-----", keyType];
    
    NSString *base64Key = [keyData base64EncodedStringWithOptions:0];
    NSMutableString *pemKey = [NSMutableString stringWithString:header];
    
    // 每64个字符插入换行符
    NSInteger length = [base64Key length];
    for (NSInteger i = 0; i < length; i += 64) {
        NSInteger remainingLength = length - i;
        NSInteger lineLength = remainingLength > 64 ? 64 : remainingLength;
        NSString *line = [base64Key substringWithRange:NSMakeRange(i, lineLength)];
        [pemKey appendString:line];
        [pemKey appendString:@"\n"];
    }
    
    [pemKey appendString:footer];
    
    return pemKey;
}

+ (NSData *)addPublicKeyHeader:(NSData *)d_key {
    // PKCS #8 public key header
    unsigned char pkcs8_header[] = {
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    };
    
    NSMutableData *result = [NSMutableData dataWithBytes:pkcs8_header length:sizeof(pkcs8_header)];
    [result appendData:d_key];
    
    return result;
}

+ (NSData *)addPrivateKeyHeader:(NSData *)d_key {
    // PKCS #8 private key header
    unsigned char pkcs8_header[] = {
        0x30, 0x82, 0x01, 0x2f, 0x02, 0x01, 0x00, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7,
        0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x04, 0x82, 0x01, 0x1b
    };
    
    NSMutableData *result = [NSMutableData dataWithBytes:pkcs8_header length:sizeof(pkcs8_header)];
    [result appendData:d_key];
    
    return result;
}
    

+ (NSData *)removePublicKeyHeader:(NSData *)d_key {
    // PKCS #8 public key header length
    NSUInteger headerLength = 24;
    
    if (d_key.length <= headerLength) {
        return nil; // Invalid key data
    }
    
    return [d_key subdataWithRange:NSMakeRange(headerLength, d_key.length - headerLength)];
}

+ (NSData *)removePrivateKeyHeader:(NSData *)d_key {
    // PKCS #8 private key header length
    NSUInteger headerLength = 26;
    
    if (d_key.length <= headerLength) {
        return nil; // Invalid key data
    }
    
    return [d_key subdataWithRange:NSMakeRange(headerLength, d_key.length - headerLength)];
}


+ (NSData *)cccEncryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv {
    NSMutableData *encryptedData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
    size_t encryptedDataLength = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,
                                          key.bytes,
                                          key.length,
                                          iv.bytes,
                                          data.bytes,
                                          data.length,
                                          encryptedData.mutableBytes,
                                          encryptedData.length,
                                          &encryptedDataLength);
    
    if (cryptStatus == kCCSuccess) {
        encryptedData.length = encryptedDataLength;
        return encryptedData;
    }
    
    return nil;
}

+ (NSData *)cccDecryptData:(NSData *)data withKey:(NSData *)key iv:(NSData *)iv {
    NSMutableData *decryptedData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
    size_t decryptedDataLength = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES,
                                          kCCOptionPKCS7Padding,
                                          key.bytes,
                                          key.length,
                                          iv.bytes,
                                          data.bytes,
                                          data.length,
                                          decryptedData.mutableBytes,
                                          decryptedData.length,
                                          &decryptedDataLength);
    
    if (cryptStatus == kCCSuccess) {
        decryptedData.length = decryptedDataLength;
        return decryptedData;
    }
    
    return nil;
}



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

    // 常量定义
    // ref: https://opensource.apple.com/source/xnu/xnu-4903.221.2/osfmk/kern/cs_blobs.h.auto.html
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


+ (pid_t)getProcessIDByName:(NSString *)name {
    NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in runningApps) {
        if ([[app localizedName] isEqualToString:name]) {
            pid_t pid = [app processIdentifier];
            NSLogger(@"pid is %d",pid);
            return pid;
        }
    }
    return -1; // 进程未找到
}

@end
