//
//  entry_utils.m
//  mac_patch_helper
//
//  Created by voidm on 2024/5/3.
//

#import <Foundation/Foundation.h>
#import "encryp_utils.h"
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

@implementation EncryptionUtils

+ (NSString *)generateTablePlusDeviceId{

//    mac=$(ifconfig en0 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
//    Serial=$(system_profiler SPHardwareDataType | grep Serial | awk '{print $4}')
//    deviceID=$(echo -n "${mac}${Serial}" | md5)
//    echo $deviceID

    CWWiFiClient *wifiClient = [CWWiFiClient sharedWiFiClient];
    CWInterface *wifiInterface = [wifiClient interface];
    NSString *hardwareAddress = [wifiInterface hardwareAddress];
    // f0:18:98:1b:24:20

    NSString *serialNumber = nil;
    
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 120000) // Before macOS 12 Monterey
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMainPortDefault,
                                                              IOServiceMatching("IOPlatformExpertDevice"));
#else
    // 在 macOS 12.0 之前的版本，使用其他适当的兼容方法
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                              IOServiceMatching("IOPlatformExpertDevice"));
#endif



    if (platformExpert) {
        CFTypeRef serialNumberAsCFString =
                IORegistryEntryCreateCFProperty(platformExpert,
                                                CFSTR(kIOPlatformSerialNumberKey),
                                                kCFAllocatorDefault, 0);
        if (serialNumberAsCFString) {
            // C02X51AJJG5J
            serialNumber = CFBridgingRelease(serialNumberAsCFString);
        }
        IOObjectRelease(platformExpert);
    }else{
        return nil;
    }
    // ee4f1d1890b4eb49a5a4d7f195ca8b67
    return [self calculateMD5:[hardwareAddress stringByAppendingString:serialNumber]];
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
    NSLog(@"IOPlatformUUID : %@",uuidString);
    // 9B37DA4D-B136-5AAE-BED8-F16E5BB0E199 --> MD5 : E05B9A7B7518C259C5BF6D2F5ABF6BD7

    
    // hw.model
    char model[256];
    size_t size = sizeof(model);
    if (sysctlbyname("hw.model", model, &size, NULL, 0) == 0) {
        NSString *hwModel = [NSString stringWithUTF8String:model];
        [rbx addObject:hwModel];
        NSLog(@"hw.model : %@",hwModel);
        // MacBookPro15,1
    }
    
    // machdep.cpu.brand_string
    size = sizeof(model); // 重新设置size
    if (sysctlbyname("machdep.cpu.brand_string", model, &size, NULL, 0) == 0) {
        NSString *cpu = [NSString stringWithUTF8String:model];
        [rbx addObject:cpu];
        NSLog(@"machdep.cpu.brand_string : %@",cpu);
        // MacBookPro15,1
    }
    
    // machdep.cpu.signature
    int64_t signature = 0;
    size_t signatureSize = sizeof(signature);
    if (sysctlbyname("machdep.cpu.signature",  &signature, &signatureSize, NULL, 0) == 0) {
        
        NSNumber *numberSignature = [NSNumber numberWithLongLong:signature];
        [rbx addObject:numberSignature];
        NSLog(@"machdep.cpu.signature: %@", numberSignature);
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
        NSLog(@"hw.memsize: %@", numberMemsize);
    }else {
        [rbx addObject:@"#"];
        NSLog(@"hw.memsize: %s", "#");
    }
    
    // /Users/voidm/Library/Preferences/com.nssurge.surge-mac.plist
    bool ActivationCompatibilityMode = false;
    
    CWWiFiClient *wifiClient = [CWWiFiClient sharedWiFiClient];
    CWInterface *wifiInterface = [wifiClient interface];
    NSString *hardwareAddress = [wifiInterface hardwareAddress];
    NSLog(@"Hardware Address: %@", hardwareAddress);
    [rbx addObject:hardwareAddress];

    // f0:18:98:1b:24:20
    
    if (!ActivationCompatibilityMode) {
        // com.nssurge.surge-mac.nsa.wifimac: e05b9a7b7518c259c5bf6d2f5abf6bd7/f0:18:98:1b:24:20       
    }
    
    NSString *joinedString = [rbx componentsJoinedByString:@"/"];
    // 9B37DA4D-B136-5AAE-BED8-F16E5BB0E199/MacBookPro15,1/Intel(R) Core(TM) i7-8850H CPU @ 2.60GHz/591594/17179869184/f0:18:98:1b:24:20
    // E9EFB28F-053B-5C48-BAA0-E6A055AD806F/MacBookPro17,1/Apple M1/0/8589934592/3c:06:30:30:7d:35
    NSLog(@"joinedString %@", joinedString);
    NSString *deviceIdMD5 = [self calculateMD5:joinedString];
    // 36d7a97a91b82ce5bc8b2609d4e17dae
    NSLog(@"deviceIdMD5 %@", deviceIdMD5);
    return deviceIdMD5;
};

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
        NSLog(@"密钥生成失败: %@", error);
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
        NSLog(@"Signature generation failed: %@", (__bridge NSError *)error);
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
@end
