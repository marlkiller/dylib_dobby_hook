//
//  TablePlusHack.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import "encryp_utils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import "HackProtocol.h"
#import "common_ret.h"

@interface TablePlusHack : NSObject <HackProtocol>

@end

@implementation TablePlusHack

static IMP urlWithStringSeletorIMP;
static IMP NSURLSessionClassIMP;
static IMP dataTaskWithRequestIMP;



- (NSString *)getAppName {
    return @"com.tinyapp.TablePlus";
}

- (NSString *)getSupportAppVersion {
    return @"6.";
}


//__strong id _rbx;
//
//id hook_license(int arg0, int arg1, int arg2, int arg3){
//    if (_rbx==nil){
//        
//        // 通过反射获取 Swift 类
//        Class TBLicenseModelClass = NSClassFromString(@"_TtC9TablePlus14TBLicenseModel");
//        if (!TBLicenseModelClass) {
//           return nil;
//        }
//       
//        id r12 = [TBLicenseModelClass alloc] ;
//
//        [MemoryUtils listAllPropertiesMethodsAndVariables:TBLicenseModelClass];
//        // LicenseModel *r12 = [[NSClassFromString(@"LicenseModel") alloc] init];
//        NSString *deviceId = [EncryptionUtils generateTablePlusDeviceId];
////        [r12 setValue:deviceId forKey:@"deviceID"];
//        [MemoryUtils setInstanceIvar:r12 ivarName:@"deviceID" value:deviceId];
//        [MemoryUtils setInstanceIvar:r12 ivarName:@"sign" value:@"12345678901234567890123456789012345678901234567890"];
//        [MemoryUtils setInstanceIvar:r12 ivarName:@"purchasedAt" value:@"2999-01-16"];
//        [MemoryUtils setInstanceIvar:r12 ivarName:@"updatesAvailableUntil" value:@"2999-01-16"];
//        [MemoryUtils setInstanceIvar:r12 ivarName:@"licenseKey" value:@"licenseKey"];
//        [MemoryUtils setInstanceIvar:r12 ivarName:@"nextChargeAt" value:@"123456"];
//        [MemoryUtils setInstanceIvar:r12 ivarName:@"email" value:[NSString stringWithCString:global_email_address encoding:NSUTF8StringEncoding]];
//        
//        // 获取属性名对应的 Ivar
//       Ivar ivar = class_getInstanceVariable([TBLicenseModelClass class], "deviceID");
//       // 如果 ivar 不为空，说明属性存在
//       if (ivar != NULL) {
//           // 获取属性的偏移量
//           ptrdiff_t offset = ivar_getOffset(ivar);
//           
//           uintptr_t address = (uintptr_t)(__bridge void *)r12 + offset;
//           // 计算属性在对象中的地址
//           NSString * __autoreleasing *deviceIdPtr = (NSString * __autoreleasing *)(void *)address;
//           *deviceIdPtr = deviceId;
//       }
//        
//        Ivar sign = class_getInstanceVariable([TBLicenseModelClass class], "sign");
//        if (sign != NULL) {
//            ptrdiff_t offset = ivar_getOffset(sign);
//            uintptr_t address = (uintptr_t)(__bridge void *)r12 + offset;
//            NSString * __autoreleasing *deviceIdPtr = (NSString * __autoreleasing *)(void *)address;
//            *deviceIdPtr = deviceId;
//        }
//        
//       _rbx=r12;
//        NSLog(@">>>>>> deviceId: %@",deviceId);
////        _rbx=r12;
////        return r12;
//        // rax_12.b = rax_11 s>= 0x32
////        NSDictionary *propertyDictionary = @{
////            @"sign": @"12345678901234567890123456789012345678901234567890",
////            @"email": [NSString stringWithCString:global_email_address encoding:NSUTF8StringEncoding],
////            @"deviceID": deviceId,
////            @"licenseKey": @"licenseKey",
////            @"purchasedAt": @"2999-01-16",
////            @"nextChargeAt": @(9999999999999), // Replace with the actual double value
////            @"updatesAvailableUntil": @"2999-01-16" // Replace with the actual value
////        };
////        _rbx = [r12 initWithDictionary:propertyDictionary];;
//    }
//    return _rbx;
//}

//
//bool hook_device_id(uint64_t arg0, uint64_t arg1, uint64_t arg2, uint64_t arg3, uint64_t arg4){
//    //
//    // Interceptor.attach(Module.findExportByName(null, 'CC_MD5')
//    // ifconfig en0 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'
//    // system_profiler SPHardwareDataType | grep Serial
//    // deviceID = md5(mac+Serial)
//    // 3c:06:30:30:7d:35C02G64QMQ05D
//    // 88548E5A38EEEE04E89C5621BA04BC7E
//    
//    if (_rbx!=nil && [_rbx.deviceID isEqual:@""]){
//        
//        // arm: r1 = *(int128_t *)(arg2 + 0x28);
//        // x86: mov  rsi, qword [rdx+0x28] ; real device id ; rsi = *(arg2 + 0x28);
//        
//        // 地址要倒叙处理,垃圾写法
//        // uint64_t _rsi = (arg2 + 0x28);
//        // NSString * addressString = [MemoryUtils readMachineCodeStringAtAddress:(_rsi) length:(8)];
//        // NSArray<NSString *> *byteStrings = [addressString componentsSeparatedByString:@" "];
//        // NSMutableArray<NSString *> *reversedByteStrings = [NSMutableArray arrayWithCapacity:byteStrings.count];
//        // // 将字节字符串倒序
//        // for (NSInteger i = byteStrings.count - 1; i >= 0; i--) {
//        //     [reversedByteStrings addObject:byteStrings[i]];
//        // }
//        // // 连接倒序后的字节字符串
//        // NSString *reversedAddressString = [reversedByteStrings componentsJoinedByString:@""];
//        // // 将倒序后的地址字符串转换为实际地址值
//        // unsigned long long address = strtoull([reversedAddressString UTF8String], NULL, 16);
//        // void *addressPtr = (void *)address;
//        
//        
//        // 虽然看不明白, 但是这个写法短小精干
//        // memory read ptr = 00 0f 3c 00 00 60 00 00,
//        // memory read *ptr *ptr+100 = deviceId
//        // addressPtr = 60 00 00 3c 0f 00
//        uintptr_t *ptr = (uintptr_t *)(arg2 + 0x28);
//        // NSLog(@">>>>>> ptr: %#lx", ptr);
//        // 将 ptr 指向的内存地址的值（即指针所指向的地址）赋值给 addressPtr
//        void * addressPtr = (void *) *ptr;
//        // [MemoryUtils inspectObjectWithAddress:addressPtr]; // 打印对象
//        // NSString * deviceId = [MemoryUtils readStringAtAddress:(addressPtr+0x20)];
//        // NSLog(@">>>>>> deviceId: %@", deviceId);
//        // _rbx.deviceID =deviceId;
//        NSString *deviceId = [NSString stringWithCString:addressPtr+0x20 encoding:NSUTF8StringEncoding];
//        _rbx.deviceID =deviceId;
//        NSLog(@">>>>>> deviceId: %@", deviceId);
//        
//    }
//    return hook_device_id_ori(arg0,arg1,arg2,arg3,arg4);
//}


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
    
    
//    echo "fuck" > ~/Library/Application\ Support/com.tinyapp.TablePlus/.licensemac
//    获取 NSFileManager 的单例
//    0x100149e44 <+340>:  movq   0x725fa5(%rip), %rsi      ; "fileExistsAtPath:"
//    0x100149e4b <+347>:  movq   %rbx, %rdi
//    0x100149e4e <+350>:  movq   %r12, %rdx
//->  0x100149e51 <+353>:  callq  0x1006e641a               ; symbol stub for: objc_msgSend
    
    // 获取用户的 Application Support 目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    // 获取当前应用程序的 bundle identifier
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    // 构建完整的路径
    NSString *appDirectory = [applicationSupportDirectory stringByAppendingPathComponent:bundleIdentifier];
    NSString *licensePath = [appDirectory stringByAppendingPathComponent:@".licensemac"];
    
    NSLog(@">>>>>> License file path: %@", licensePath);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:licensePath];
    
    if (!fileExists) {
        NSString *licenseContent = @"?";
        BOOL success = [licenseContent writeToFile:licensePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSLog(@">>>>>> License file: %hhd",success);
    }
    
    
    // r12 = [[RNDecryptor decryptData:"file bytes" withPassword:"x" error:&var_48] retain];
    // +[RNDecryptor decryptData:withPassword:error:]:
    [MemoryUtils hookClassMethod:
         NSClassFromString(@"RNDecryptor")
                originalSelector: NSSelectorFromString(@"decryptData:withPassword:error:")
                   swizzledClass:[self class]
                swizzledSelector:NSSelectorFromString(@"hk_decryptData:withPassword:error:")
    ];
    
    
    
    Class AFURLSessionManagerClz = NSClassFromString(@"AFHTTPSessionManager");
    SEL dataTaskWithRequestSel = NSSelectorFromString(@"dataTaskWithHTTPMethod:URLString:parameters:headers:uploadProgress:downloadProgress:success:failure:");
    Method dataTaskWithRequestMethod = class_getInstanceMethod(AFURLSessionManagerClz, dataTaskWithRequestSel);
    dataTaskWithRequestIMP = method_getImplementation(dataTaskWithRequestMethod);
    [MemoryUtils hookInstanceMethod:
         AFURLSessionManagerClz
                   originalSelector:dataTaskWithRequestSel
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_dataTaskWithHTTPMethod:URLString:parameters:headers:uploadProgress:downloadProgress:success:failure:")
    ];
    

    //     *(rbx + *objc_ivar_offset__TtC9TablePlus11AppDelegate_updaterController) = [objc_allocWithZone(@class(SPUStandardUpdaterController)) initWithStartingUpdater:0x1 updaterDelegate:0x0 userDriverDelegate:0x0];
    [MemoryUtils replaceInstanceMethod:NSClassFromString(@"SPUUpdater")
                      originalSelector:NSSelectorFromString(@"startUpdater:")
                         swizzledClass:[self class]
                      swizzledSelector:@selector(ret1)
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
    if ([URLString containsString:@"tableplus"]) {
        
//    loc_1002645ce:
//        r14 = *qword_10093f548;
//        sub_1002661d0(&var_80, 0x100909b50, rdx, *type metadata for Swift.String);
//        swift_bridgeObjectRelease(rbx);
//        swift_bridgeObjectRelease(r13);
//        swift_bridgeObjectRelease(var_40);
//        rbx = *(r14 + 0x68);
//        *(r14 + 0x60) = r12;
//        *(r14 + 0x68) = var_38;
//        swift_release(r14);
//        goto loc_100264365;
        
        // TODO: updatesAvailableUntil 字段在请求回调中处理; 但是没分析出来具体的响应;
        success(nil, @{
            @"fuck":@"dev",
        });
        NSLog(@">>>>>> [hk_dataTaskWithHTTPMethod] Intercept url: %@",URLString);
        return nil;

    }
    NSLog(@">>>>>> [hk_dataTaskWithHTTPMethod] Allow to pass url: %@",URLString);
    return ((id(*)(id, SEL,NSString *,NSString *,id,id,id,id,id,id))dataTaskWithRequestIMP)(self, _cmd,method,URLString,parameters,headers,uploadProgress,downloadProgress,success,failure);
}




+ (id) hk_decryptData:arg1 withPassword:(NSString *)withPassword error:(int)error{
    NSDictionary *propertyDictionary = @{
        @"sign": @"12345678901234567890123456789012345678901234567890",
        @"email": [NSString stringWithCString:global_email_address encoding:NSUTF8StringEncoding],
        @"deviceID":[EncryptionUtils generateTablePlusDeviceId],
        @"licenseKey": @"licenseKey",
        @"purchasedAt": @"2025-06-16",
        @"nextChargeAt": @"2025-06-16",
        @"updatesAvailableUntil": @"2025-06-16"
    };
//    Class TBLicenseModelClass = NSClassFromString(@"_TtC9TablePlus14TBLicenseModel");
//    [MemoryUtils listAllPropertiesMethodsAndVariables:TBLicenseModelClass];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:propertyDictionary options:0 error:nil];
    return jsonData;
}

+ (id)hk_URLWithString:arg1{
    
    if ([arg1 hasPrefix:@"https://"] && [arg1 containsString:@"tableplus"]) {
        NSLog(@">>>>>> hk_URLWithString Intercept requests %@",arg1);
        arg1 =  @"https://127.0.0.1";
    }
    id ret = ((id(*)(id, SEL,id))urlWithStringSeletorIMP)(self, _cmd,arg1);
    return ret;
}
@end
