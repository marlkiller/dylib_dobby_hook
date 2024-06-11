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

@interface DummyURLSessionDataTask : NSObject
@end

@implementation DummyURLSessionDataTask

- (void)resume {
    // 重写 resume 方法，使其不做任何事情
    NSLog(@">>>>>> DummyURLSessionDataTask.resume");
}

@end


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
    if ([URLString containsString:@"tableplus.com"]) {
        DummyURLSessionDataTask *dummyTask = [[DummyURLSessionDataTask alloc] init];

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
        
        
        
        if ([URLString containsString:@"v1/licenses/devices"]){
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
//            [result setObject:[EncryptionUtils generateTablePlusDeviceId] forKey:@"DeviceID"];
//            00000001002641ef         movabs     rdi, 0x4449656369766544                     ; argument #1 for method sub_100033750
//            00000001002641f9         movabs     rsi, 0xe800000000000000                     ; argument #2 for method sub_100033750
//            0000000100264203         call       sub_100033750
            [result setObject:[EncryptionUtils generateTablePlusDeviceId] forKey:@"DeviceID"];
            [result setObject:@"2025-07-16" forKey:@"UpdatesAvailableUntilString"];
                        
    //        00000001002642c7         mov        rdi, r13                                    ; argument "ptr" for method imp___stubs__swift_bridgeObjectRetain
    //        00000001002642ca         call       imp___stubs__swift_bridgeObjectRetain       ; swift_bridgeObjectRetain
    //        00000001002642cf         lea        rax, qword [aTtc9tableplus1_100751390]      ; "_TtC9TablePlus12RemoteSource"
    //        00000001002642d6         movabs     rsi, 0x8000000000000000
    //        00000001002642e0         or         rsi, rax                                    ; argument #2 for method sub_100033750
    //        00000001002642e3         movabs     rdi, 0xd00000000000001b                     ; argument #1 for method sub_100033750
    //        00000001002642ed         call       sub_100033750                               ; sub_100033750
    //        00000001002642f2         test       dl, 0x1
    //        00000001002642f5         je         loc_1002645c3
            
            success(nil, @{
//                @"Message":@"fuck",
                @"Data":result,
//                @"Code":@200
            });
        }else if ([URLString containsString:@"apps/osx/tableplus"]){
            success(nil, @{
                @"Data":@{
                    @"DayBeforeExpiration":@521
                },
            });
        }
        NSLog(@">>>>>> [hk_dataTaskWithHTTPMethod] Intercept url: %@, req params: %@",URLString,parameters);
        return dummyTask;
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
