//
//  TablePlusHack.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import "EncryptionUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import "HackProtocolDefault.h"
#import "common_ret.h"
#import "URLSessionHook.h"


@interface TablePlusHack : HackProtocolDefault

@end

@implementation TablePlusHack

static IMP urlWithStringSeletorIMP;
//static IMP NSURLSessionClassIMP;
static IMP dataTaskWithRequestIMP;
static NSString* deviceIdOri;


- (NSString *)getAppName {
    return @"com.tinyapp.TablePlus";
}

- (NSString *)getSupportAppVersion {
    return @"6.";
}

static unsigned char *(*CC_MD5_ori)(const void *data, CC_LONG len, unsigned char *md);
static unsigned char *hk_CC_MD5(const void *data, CC_LONG len, unsigned char *md) {
    unsigned char *result = CC_MD5_ori(data, len, md);
    //    NSString *inputStr = [[NSString alloc] initWithBytes:data length:len encoding:NSUTF8StringEncoding];
    char md5Ori[CC_MD5_DIGEST_LENGTH * 2 + 1];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        snprintf(md5Ori + i * 2, 3, "%02x", md[i]);
    }

    if (strcmp(md5Ori, [deviceIdOri UTF8String]) == 0) {
        unsigned char fakeMD5[CC_MD5_DIGEST_LENGTH] = {
            0x12, 0x34, 0x56, 0x78, 0x90, 0x12, 0x34, 0x56,
            0x78, 0x90, 0x12, 0x34, 0x56, 0x78, 0x90, 0x12
        };
        memcpy(md, fakeMD5, CC_MD5_DIGEST_LENGTH);
        NSMutableString *fakeMD5Str = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
        for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
            [fakeMD5Str appendFormat:@"%02x", fakeMD5[i]];
        }
        NSLogger(@"[Hooked CC_MD5] Returning Fake MD5: %@", fakeMD5Str);
        return md;
    }
    
    return result;
}


- (BOOL)hack {
    
//    Class NSURLControllerClass = NSClassFromString(@"NSURL");
//    SEL urlWithStringSeletor = NSSelectorFromString(@"URLWithString:");
//    Method urlWithStringSeletorMethod = class_getClassMethod(NSURL.class, urlWithStringSeletor);
//    urlWithStringSeletorIMP = method_getImplementation(urlWithStringSeletorMethod);
//    [MemoryUtils hookClassMethod:
//         NSURLControllerClass
//                originalSelector:urlWithStringSeletor
//                   swizzledClass:[self class]
//                swizzledSelector:NSSelectorFromString(@"hk_URLWithString:")
//    ];
    deviceIdOri = [EncryptionUtils generateTablePlusDeviceId];
    NSLogger(@"deviceIdOri is %@",deviceIdOri);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    // 获取当前应用程序的 bundle identifier
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    // 构建完整的路径
    NSString *appDirectory = [applicationSupportDirectory stringByAppendingPathComponent:bundleIdentifier];
    NSString *licensePath = [appDirectory stringByAppendingPathComponent:@".licensemac"];
    
    NSLogger(@"License file path: %@", licensePath);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:licensePath];
    
    if (!fileExists) {
        unsigned char hexData[322] = {
            0x03, 0x01, 0xD2, 0xD4, 0x25, 0x23, 0x02, 0x10, 0x59, 0xE5, 0x22, 0xED, 0xCF, 0x84, 0xDD, 0x79,
            0xBE, 0x3B, 0xF3, 0xE4, 0x9B, 0xB0, 0xF9, 0x7E, 0x28, 0x5B, 0xCB, 0x48, 0x6F, 0xB4, 0xF2, 0xC5,
            0x10, 0xB3, 0xAE, 0xA1, 0xAD, 0x6B, 0x21, 0x57, 0xE0, 0x02, 0x26, 0xD8, 0x09, 0x12, 0xE6, 0x7D,
            0x4A, 0x73, 0xE7, 0xCE, 0xC4, 0x17, 0x1E, 0x95, 0x96, 0x08, 0x99, 0x86, 0xE7, 0x2D, 0xE5, 0x0D,
            0x53, 0xF7, 0x0D, 0x09, 0x50, 0xEA, 0xD8, 0x42, 0xBC, 0xAC, 0x1A, 0x39, 0x93, 0xDE, 0xC3, 0x0E,
            0xA8, 0x0D, 0x07, 0x27, 0xE6, 0x7F, 0x63, 0xB9, 0x8A, 0xEF, 0x63, 0x67, 0x3C, 0x4D, 0x7C, 0x46,
            0x70, 0xFC, 0x66, 0x4D, 0x4C, 0xA1, 0xE5, 0x17, 0x75, 0xFD, 0x46, 0x0B, 0x91, 0x4E, 0xF4, 0x0A,
            0x49, 0x0C, 0x75, 0x92, 0xE7, 0x3F, 0x56, 0x5D, 0xE0, 0xD6, 0x47, 0x38, 0x58, 0xAA, 0x6D, 0x00,
            0x8A, 0x03, 0xF5, 0xB5, 0xED, 0x9E, 0x45, 0x86, 0xEE, 0xE6, 0xAA, 0x6B, 0xB2, 0x7D, 0x2E, 0xA8,
            0x51, 0x34, 0x14, 0xF0, 0x71, 0x06, 0x7B, 0xCE, 0xEF, 0xFF, 0x33, 0x4C, 0x9E, 0x36, 0xB6, 0x77,
            0x53, 0x70, 0xCD, 0xA3, 0x64, 0x06, 0xD9, 0xA0, 0x48, 0xAE, 0x39, 0xBE, 0xFB, 0xF1, 0xE4, 0x0B,
            0x04, 0xD1, 0xDF, 0xB5, 0x00, 0x95, 0x70, 0xD6, 0x0A, 0xDF, 0xEC, 0x7C, 0xF4, 0x57, 0x60, 0x5F,
            0xDA, 0xCC, 0x75, 0x28, 0xCE, 0x77, 0x22, 0x40, 0x0E, 0xF7, 0x2F, 0xB2, 0xB8, 0xD4, 0xBB, 0x25,
            0xD0, 0x26, 0x75, 0x23, 0xAD, 0x6A, 0x05, 0x9F, 0x74, 0x3A, 0xBE, 0x2C, 0xA7, 0x52, 0x18, 0xCF,
            0x53, 0x17, 0x4F, 0x65, 0x16, 0xE9, 0xF6, 0xD8, 0x84, 0x65, 0xB0, 0xDE, 0x7F, 0x5C, 0x99, 0x2D,
            0x86, 0x64, 0x15, 0x2B, 0xA4, 0xEB, 0x2C, 0x9D, 0xFA, 0xAD, 0x9F, 0x33, 0xDE, 0x01, 0xA4, 0x2B,
            0x15, 0xE3, 0x37, 0xB2, 0x59, 0xA0, 0x9D, 0xDA, 0x34, 0x7B, 0xC8, 0x85, 0xD7, 0x04, 0xFF, 0x77,
            0x2A, 0xDB, 0xDA, 0x9A, 0xFA, 0x62, 0x26, 0x62, 0xAE, 0xD0, 0x61, 0xFB, 0xBC, 0x5A, 0xA6, 0xFF,
            0x96, 0x00, 0x9B, 0x3D, 0xC4, 0xB4, 0x3C, 0xF5, 0x4C, 0x14, 0x63, 0xBA, 0x6F, 0x6A, 0x76, 0x0D,
            0x94, 0xA6, 0x7D, 0x43, 0xCA, 0xDF, 0x36, 0x5E, 0x8E, 0xE9, 0x6A, 0xE3, 0xED, 0x6C, 0xB7, 0x9F,
            0x77, 0x36
        };
        NSData *data = [NSData dataWithBytes:hexData length:sizeof(hexData)];
        BOOL success = [data writeToFile:licensePath atomically:YES];
        NSLogger(@"License file: %hhd", success);
    }
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations" // CC_MD5
    tiny_hook((void *)CC_MD5, (void *)hk_CC_MD5, (void *)&CC_MD5_ori);
#pragma clang diagnostic pop
    dataTaskWithRequestIMP = [MemoryUtils hookInstanceMethod:NSClassFromString(@"AFHTTPSessionManager")
                   originalSelector:NSSelectorFromString(@"dataTaskWithHTTPMethod:URLString:parameters:headers:uploadProgress:downloadProgress:success:failure:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_dataTaskWithHTTPMethod:URLString:parameters:headers:uploadProgress:downloadProgress:success:failure:")
    ];
    return YES;
}

- (id)hk_dataTaskWithHTTPMethod:(NSString *)method
                                               URLString:(NSString *)URLString
                                              parameters:(id)parameters
                                                 headers:(NSDictionary<NSString *,NSString *> *)headers
                                          uploadProgress:(void (^)(NSProgress *uploadProgress))uploadProgress
                                        downloadProgress:(void (^)(NSProgress *downloadProgress))downloadProgress
                                                 success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                                 failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    
    
    
    // @"https://tableplus.com/v1/licenses/devices?deviceID=xxx"    0x0000600001f82a80
    if ([URLString containsString:@"tableplus.com"]) {
        URLSessionHook *dummyTask = [[URLSessionHook alloc] init];
        
        if ([URLString containsString:@"v1/licenses/devices"]){
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            [result setObject:@"12345678901234567890123456789012" forKey:@"DeviceID"];
            [result setObject:@"2026-12-30" forKey:@"UpdatesAvailableUntilString"];
            success(nil, @{
//                @"Message":@"",
                @"Data":result,
                @"Code":@200
            });
        }else if ([URLString containsString:@"apps/osx/tableplus"]){
            success(nil, @{
                @"Data":@{
                    @"DayBeforeExpiration":@521,
                    @"NeedToUpdate":@NO,
                    @"PushLocalNoti":@NO,
                    @"Tittle":@"This is Tittle",
                    @"LicenseKey":@"1234567890"
                },
            });
        }else if ([URLString containsString:@"licenses/register"]){
            success(nil, @{
                @"Data":@{
                    @"sign": @"12345678901234567890123456789012345678901234567890",
                    @"email": [Constant G_EMAIL_ADDRESS],
                    @"deviceID":@"12345678901234567890123456789012",
                    @"licenseKey": @"licenseKey",
                    @"purchasedAt": @"2026-12-30",
                    @"nextChargeAt": @521,
                    @"updatesAvailableUntil": @"2026-12-30"
                },
                @"Code":@200
            });
        }
        NSLogger(@"[hk_dataTaskWithHTTPMethod] Intercept url: %@, req params: %@",URLString,parameters);
        return dummyTask;
    }
    NSLogger(@"[hk_dataTaskWithHTTPMethod] Allow to pass url: %@",URLString);
    return ((id(*)(id, SEL,NSString *,NSString *,id,id,id,id,id,id))dataTaskWithRequestIMP)(self, _cmd,method,URLString,parameters,headers,uploadProgress,downloadProgress,success,failure);
}


+ (id)hk_URLWithString:arg1{
    
    if ([arg1 hasPrefix:@"https://"] && [arg1 containsString:@"tableplus"]) {
        NSLogger(@"hk_URLWithString Intercept requests %@",arg1);
        arg1 =  @"https://127.0.0.1";
    }
    id ret = ((id(*)(id, SEL,id))urlWithStringSeletorIMP)(self, _cmd,arg1);
    return ret;
}
@end
