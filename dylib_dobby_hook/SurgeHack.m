//
//  SurgeHack.m
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/4/4.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import "HackProtocol.h"
#include <sys/ptrace.h>
#import <objc/message.h>
#import "common_ret.h"



@interface SurgeHack : NSObject <HackProtocol>

@end


@implementation SurgeHack


- (NSString *)getAppName {
    // >>>>>> AppName is [com.nssurge.surge-mac],Version is [5.6.1], myAppCFBundleVersion is [2612].
    return @"com.nssurge.surge-mac";
}

- (NSString *)getSupportAppVersion {
    return @"5.6.1";
}



- (BOOL)hack {
    
    // 程序使用ptrace来进行动态调试保护，使得执行lldb的时候出现Process xxxx exited with status = 45 (0x0000002d)错误。
    // 使用 DobbyHook 替换 ptrace函数。
    DobbyHook((void *)ptrace, (void *)my_ptrace, (void *)&orig_ptrace);
    
    // https://www.xwjack.com/2017/11/15/Reverse/
    
    // NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/Surge"];
    // uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    
    
    // NSURL['+ URLWithString:']
    Class NSURLControllerClass = NSClassFromString(@"NSURL");
    SEL urlWithStringSeletor = NSSelectorFromString(@"URLWithString:");
    Method urlWithStringSeletorMethod = class_getClassMethod(NSURL.class, urlWithStringSeletor);
    // 获取 viewDidLoad 方法的函数地址
    IMP urlWithStringSeletorIMP = method_getImplementation(urlWithStringSeletorMethod);
    urlWithStringPointer = (URLWithStringPointer)urlWithStringSeletorIMP;

    [MemoryUtils hookClassMethod:
         NSURLControllerClass
                originalSelector:urlWithStringSeletor
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_URLWithString:")
    ];
    
    
    // -[SGMLicenseViewController reload]:
    [MemoryUtils hookInstanceMethod:
         NSClassFromString(@"SGMEnterprise")
                   originalSelector:NSSelectorFromString(@"settings")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_settings")
    ];
    
    
    // hook getxattr com.nssurge.surge-mac
    DobbyHook((void *)0x1001a08fb, (void *)hook_sub_1001a08fb, nil);
    
    // hook get deviceid >> 0x1001b3324
    // DobbyHook((void *)0x1001b3324, (void *)hook_sub_1001a08fb, nil);

    // -[NSData KD_JSONObject]:
    Class nsDataClass = NSClassFromString(@"NSData");
    SEL KD_JSONObjectSeleter = NSSelectorFromString(@"KD_JSONObject");
    Method kd_JSONObjectSeleterOriginalMethod = class_getInstanceMethod(nsDataClass, KD_JSONObjectSeleter);
    // 获取 KD_JSONObject 方法的函数地址
    IMP originalMethodIMP = method_getImplementation(kd_JSONObjectSeleterOriginalMethod);
    kd_JSONObjectPointer = (KD_JSONObjectPointer)originalMethodIMP;
    
    [MemoryUtils hookInstanceMethod:
         NSClassFromString(@"NSData")
                   originalSelector:NSSelectorFromString(@"KD_JSONObject")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_KD_JSONObject")
    ];
    
    
    // (r12)(rdi, @selector(KD_MD5), @"/");  -[NSString KD_MD5] // void sub_1001b3365(void * _block)
    Class NSStringClz = NSClassFromString(@"NSString");
    SEL KD_MD5Seleter = NSSelectorFromString(@"KD_MD5");
    Method KD_MD5lMethod = class_getInstanceMethod(NSStringClz, KD_MD5Seleter);
    IMP KD_MD5IMP = method_getImplementation(KD_MD5lMethod);
    KD_MD5IMPGlobal = method_getImplementation(KD_MD5lMethod);
    kd_MD5Pointer = (KD_MD5Pointer)KD_MD5IMP;
    [MemoryUtils hookInstanceMethod:
         NSClassFromString(@"NSString")
                   originalSelector:NSSelectorFromString(@"KD_MD5")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_KD_MD5")
    ];
    
    // 0x1001b304c         mov        dword [dword_10083dea8], 0x4                ; dword_10083dea8
//    NSLog(@">>>>>> Before %s",[MemoryUtils readMachineCodeStringAtAddress:0x1001b304c length:4].UTF8String);
//    uint8_t nopx10[10] = {0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90};
//    DobbyCodePatch((void*)0x1001b304c,(uint8_t *)nopx10,10);
//    NSLog(@">>>>>> After %s",[MemoryUtils readMachineCodeStringAtAddress:0x1001b304c length:4].UTF8String); // 2A 00 80 52; mov w10, #1


    
    // -[NSDictionary objectForKeyedSubscript:]:
    Class NSDictionaryClass = NSClassFromString(@"__NSDictionaryI");
    SEL objectForKeyedSubscriptSeleter = NSSelectorFromString(@"objectForKeyedSubscript:");
    Method objectForKeyedSubscriptMethod = class_getInstanceMethod(NSDictionaryClass, objectForKeyedSubscriptSeleter);
    IMP objectForKeyedSubscriptImp = method_getImplementation(objectForKeyedSubscriptMethod);
    objectForKeyedSubscriptPointer = (ObjectForKeyedSubscriptPointer)objectForKeyedSubscriptImp;
    
    
    [MemoryUtils hookInstanceMethod:
         NSClassFromString(@"__NSDictionaryI")
                   originalSelector:NSSelectorFromString(@"objectForKeyedSubscript:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_objectForKeyedSubscript:")
    ];
    
    
    //  -[SGCloudKit init]
    [MemoryUtils hookInstanceMethod:
         NSClassFromString(@"SGCloudKit")
                   originalSelector:NSSelectorFromString(@"init")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_init")
    ];
    // -[SGPonteManager updatePonteDeviceListWithCompletionHandler:]+57

    [MemoryUtils hookInstanceMethod:
         NSClassFromString(@"SGPonteManager")
                   originalSelector:NSSelectorFromString(@"updatePonteDeviceListWithCompletionHandler:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_updatePonteDeviceListWithCompletionHandler")
    ];
    
    
    
//     sub_10019f124  int sub_10019f124(int arg0, int arg1)
        
//    DobbyHook((void *)0x10019f124, (void *)hook_sub_10019f124, (void *)&sub_10019f124_ori);

    // 10019f466
    DobbyHook((void *)0x10019f466, (void *)hook_sub_10019f466, (void *)&sub_10019f466_ori);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // raiseEventMethodPointer(NSClassFromString(@"SGEEventCenter"), NSSelectorFromString(@"raiseEvent:content:type:"),@"3",@"自定义消息3",0);
        Method raiseEventMethod = class_getClassMethod(NSClassFromString(@"SGEEventCenter"), NSSelectorFromString(@"raiseEvent:content:type:"));
        IMP raiseEventMethodIMP = method_getImplementation(raiseEventMethod);
        // 定义函数指针
        void (*func)(id, SEL, NSString *, NSString *, NSInteger) = (void (*)(id, SEL, NSString *, NSString *, NSInteger))raiseEventMethodIMP;
        // 调用方法
        func(NSClassFromString(@"SGEEventCenter"), NSSelectorFromString(@"raiseEvent:content:type:"), @"4", @"自定义消息4", 0);
        
        // 调用类方法
        Class SGEEventCenterClass = NSClassFromString(@"SGEEventCenter");
        if (SGEEventCenterClass) {
            SEL selector = NSSelectorFromString(@"raiseEvent:content:type:");
            if ([SGEEventCenterClass respondsToSelector:selector]) {
                NSMethodSignature *methodSignature = [SGEEventCenterClass methodSignatureForSelector:selector];
                if (methodSignature) {
                    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
                    // 如果是调用实例方法,需要 set target 一个实例对象
                    // [invocation setTarget:[[SGEEventCenterClass alloc] init]];
                    [invocation setTarget:SGEEventCenterClass];
                    [invocation setSelector:selector];
                    NSString *param1 = @"5";
                    NSString *param2 = @"自定义消息5";
                    NSInteger param3 = 0;
                    [invocation setArgument:&param1 atIndex:2];
                    [invocation setArgument:&param2 atIndex:3];
                    [invocation setArgument:&param3 atIndex:4];
                    [invocation invoke];
                }
            }
        }
        
        
        
    });
    
    return YES;
}


intptr_t (*sub_10019f466_ori)(id arg1);


intptr_t hook_sub_10019f466(uint64_t arg1){
 
    NSDictionary *dict0 =  @{
        @"policy": @"x",
        @"sign": @"x"
    };

    intptr_t ret =sub_10019f466_ori(dict0);
    
    return ret;
}


//
//intptr_t (*sub_10019f124_ori)(uint64_t arg1,uint64_t arg2);
//
//
//intptr_t hook_sub_10019f124(uint64_t arg1,uint64_t arg2){
//    // arg1    intptr_t    0x00006000016c4c80
//    // arg2    intptr_t    0x0000000101241727
//    
////    rdi = *(r14 + 0x28);
////        if (rdi == 0x0) goto loc_10019f3a6;
//
//    uintptr_t *ptr = (uintptr_t *)(arg1 + 0x28);
//    void * addressPtr = (void *) *ptr;
//    // __NSDictionary0
//    
////    NSMutableDictionary *dict = (__bridge NSMutableDictionary *)addressPtr;
////    NSString *key = @"newKey";
////    NSString *value = @"newValue";
////    [dict setObject:value forKey:key];
////    NSLog(@"Modified Dictionary: %@", dict);
//    
//    intptr_t ret =sub_10019f124_ori(arg1,arg2);
//    
//    return ret;
//}


- (void)hook_updatePonteDeviceListWithCompletionHandler{
    NSLog(@">>>>>> hook_updatePonteDeviceListWithCompletionHandler");
}
- (void)hook_init{
    NSLog(@">>>>>> hook_init");
}
IMP KD_MD5IMPGlobal = nil;


typedef id (*KD_MD5Pointer)(id, SEL);
KD_MD5Pointer kd_MD5Pointer = NULL;
- (NSString*)hook_KD_MD5{
    
//    NSString *result = ((NSString *(*)(id, SEL))[self methodForSelector:@selector(KD_MD5)])(self, @selector(KD_MD5));

    NSString *ret = ((NSString *(*)(id, SEL))KD_MD5IMPGlobal)(self, NSSelectorFromString(@"KD_MD5"));

//    NSString *ret = [self hook_KD_MD5];

//    NSString* ret =kd_MD5Pointer(self,_cmd);
//    return  ret;
    // e05b9a7b7518c259c5bf6d2f5abf6bd7
    // 36d7a97a91b82ce5bc8b2609d4e17dae
    // ce2500e944650ad7f6e2f580268e5454
    
    if ([ret isEqualToString:@"36d7a97a91b82ce5bc8b2609d4e17dae"]) {
        return @"ce2500e944650ad7f6e2f580268e5454";
    }
    
    // ce2500e944650ad7f6e2f580268e5454
    NSLog(@">>>>>> hook_KD_MD5 ret: %@",ret);
    return ret;
}

typedef id (*ObjectForKeyedSubscriptPointer)(id, SEL,id);
ObjectForKeyedSubscriptPointer objectForKeyedSubscriptPointer = NULL;
- (id) hook_objectForKeyedSubscript:arg1{
    NSLog(@">>>>>> hook_objectForKeyedSubscript : %@",arg1  );
    id ret = objectForKeyedSubscriptPointer(self,_cmd,arg1);
    // int sub_1001b2b3a(int arg0, int arg1) {
    if ([arg1 isEqualTo:@"expiresOnDate"]) {
        // 2024-04-15T01:28:41Z
        return @1713144521;
    }
    if ([arg1 isEqualTo:@"deviceId"]) {
        // 2024-04-15T01:28:41Z
        return @"ce2500e944650ad7f6e2f580268e5454";
    }
    if ([arg1 isEqualTo:@"type"]) {
        return @"licensed";
    }
    if ([arg1 isEqualTo:@"enterprise"]) {
        return @1;
    }
    return ret;
}

typedef id (*KD_JSONObjectPointer)(id, SEL);
KD_JSONObjectPointer kd_JSONObjectPointer = NULL;
- (id) hook_KD_JSONObject{
    id ret = kd_JSONObjectPointer(self,_cmd);
    return ret;
}

NSData *hook_sub_1001a08fb(int arg0) {
    NSLog(@">>>>>> hook_sub_1001a08fb");
//    rbx = [[KDStorageHelper applicationSupportDirectoryPathWithName:@"com.nssurge.surge-mac"] retain];
//    r14 = malloc(0x19000);
//    rax = objc_retainAutorelease(rbx);
//    rbx = rax;
//    rax = [rax UTF8String];
//    r12 = 0x0;
//    rax = getxattr(rax, arg0, r14, 0x19000, 0x0, 0x0);
//    if (rax > 0x0) {
//            r12 = [[NSData dataWithBytes:r14 length:rax] retain];
//            free(r14);
//    }
//    [rbx release];
//    [r12 autorelease];
    NSString *jsonString = @"{}";
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

    return jsonData;
}


- (id)hk_settings{
    NSLog(@">>>>>> hk_settings");
    
    // 调用类方法
    //    Class cls = NSClassFromString(@"SGMEnterpriseSettings");
    //    [cls setUserID:@"this is user id"];
    
    // 调用实例方法
    id ret = [[NSClassFromString(@"SGMEnterpriseSettings") alloc] init];
    // 函数有 多个参数
    //    [ret performSelector:@selector(setUserID:andAnotherParam:)
    //                   withObject:@"this is user id"
    //                   withObject:@"this is another param"];
    // id ret = class_createInstance(objc_getClass("SGMEnterpriseSettings"), 0);
    // [ret performSelector:NSSelectorFromString(@"setUserID:") withObject:@"this is user id"];
    // [ret performSelector:NSSelectorFromString(@"setCompanyName:") withObject:@"this is cp name"];
    // [ret performSelector:NSSelectorFromString(@"setCompanyID:") withObject:@"this is cp id"];
    return ret;
}



typedef id (*URLWithStringPointer)(id, SEL,id);
URLWithStringPointer urlWithStringPointer = NULL;

+ (id)hk_URLWithString:arg1{
    id ret = urlWithStringPointer(self,_cmd,arg1);

    // >>>>>> hk_URLWithString https://www.surge-activation.com/mac/v3/resource/jsvm
    // >>>>>> hk_URLWithString https://www.surge-activation.com/mac/v3/free-trial

    if ([arg1 containsString:@"mac/v3/resource/jsvm"]) {
        NSLog(@">>>>>> hk_URLWithString /mac/v3/resource/jsvm");
        // sub_1001b2aba() == 0x4 || sub_1001b2aba() == 0x3 || sub_1001b2aba() == 0x0
    }
    if ([arg1 containsString:@"mac/v3/free-trial"]) {
        NSLog(@">>>>>> hk_URLWithString /mac/v3/free-trial");

    }
    if ([arg1 containsString:@"https://dl.nssurge.com/mac/v5/Surge-5.6.1-"]) {
        NSLog(@">>>>>> hk_URLWithString https://dl.nssurge.com/mac/v5/Surge-5.6.1-");

    }
    if ([arg1 containsString:@"mac/v3/init/"]) {
        NSLog(@">>>>>> hk_URLWithString mac/v3/init/");

    }
    NSLog(@">>>>>> hk_URLWithString %@",arg1);
    return ret;
}



@end
