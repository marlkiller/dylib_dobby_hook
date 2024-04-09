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



@interface SurgeHack : NSObject <HackProtocol>

@end


@implementation SurgeHack



// 定义一个原始的 ptrace 函数指针
typedef int (*ptrace_ptr_t)(int _request,pid_t _pid, caddr_t _addr,int _data);
ptrace_ptr_t orig_ptrace = NULL;

// 自定义的 ptrace 函数
int my_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data) {
    if(_request != 31){
        // 如果请求不是 PT_DENY_ATTACH，则调用原始的 ptrace 函数
        return orig_ptrace(_request,_pid,_addr,_data);
    }
    NSLog(@">>>>>> ptrace request is PT_DENY_ATTACH");
    // 拒绝调试
    return 0;
}


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
    DobbyHook((void *)ptrace, (void *)my_ptrace, (void **)&orig_ptrace);
    
    // https://www.xwjack.com/2017/11/15/Reverse/
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/Surge"];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    
    
    // NSURL['+ URLWithString:']
    //    Class NSURLControllerClass = NSClassFromString(@"NSURL");
    //    SEL urlWithStringSeletor = NSSelectorFromString(@"URLWithString:");
    //    Method urlWithStringSeletorMethod = class_getClassMethod(NSURL.class, urlWithStringSeletor);
    //    // 获取 viewDidLoad 方法的函数地址
    //    IMP urlWithStringSeletorIMP = method_getImplementation(urlWithStringSeletorMethod);
    //    methodPointer2 = (MethodPointer2)urlWithStringSeletorIMP;
    //
    //    [MemoryUtils hookClassMethod:
    //         NSURLControllerClass
    //                originalSelector:urlWithStringSeletor
    //                      swizzledClass:[self class]
    //                   swizzledSelector:NSSelectorFromString(@"hk_URLWithString:")
    //    ];
    
    
    //     NSDictionary['- objectForKeyedSubscript:']
    Class NSDictionaryClass = NSClassFromString(@"NSDictionary");
    SEL objectForKeyedSubscriptSeletor = NSSelectorFromString(@"objectForKeyedSubscript:");
    Method urlWithStringSeletorMethod = class_getInstanceMethod(NSDictionaryClass, objectForKeyedSubscriptSeletor);
    IMP objectForKeyedSubscriptIMP = method_getImplementation(urlWithStringSeletorMethod);
    objectForKeyedSubscriptPointer = (ObjectForKeyedSubscriptPointer)objectForKeyedSubscriptIMP;
    [MemoryUtils hookInstanceMethod:
                   NSDictionaryClass
                   originalSelector:objectForKeyedSubscriptSeletor
                   swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_objectForKeyedSubscript:")
    ];

    
    // 获取 license type?
    // 0000000100343dd4 WindowController.updateLabels
    // rax = sub_1001b2aba()
    // 55 48 89 E5 8B 05 E4 B3 68 00 5D C3
    NSArray *sub_1001b2abaOffsets =[MemoryUtils searchMachineCodeOffsets:
                                   searchFilePath
                                   machineCode:@"55 48 89 E5 8B 05 E4 B3 68 00 5D C3"
                                   count:(int)1
    ];
    intptr_t _sub_1001b2aba = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[sub_1001b2abaOffsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];
    DobbyHook((void *)_sub_1001b2aba, (void *)hook_sub_1001b2aba, (void *)&sub_1001b2aba_ori);
    
    
    // 似乎是验证某签名的? rax = *(int32_t *)dword_100842390 == 0x1 ? 0x1 : 0x0;
    // sub_1001b3189 ret 1
    // 55 48 89 E5 41 57 41 56 41 55 41 54 53 48 83 EC 28 48 89 FB 4C 8B 35 94 B3 56 00
    
    NSArray *sub_1001b3189Offsets =[MemoryUtils searchMachineCodeOffsets:
                                   searchFilePath
                                   machineCode:@"55 48 89 E5 41 57 41 56 41 55 41 54 53 48 83 EC 28 48 89 FB 4C 8B 35 94 B3 56 00"
                                   count:(int)1
    ];
    intptr_t _sub_1001b3189 = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[sub_1001b3189Offsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];
    DobbyHook((void *)_sub_1001b3189, (void *)hook_sub_1001b3189, (void *)&sub__1001b3189_ori);
    
    
//    NSLog(@">>>>>> %d",[MemoryUtils readIntAtAddress:0x100842390]);
//    [MemoryUtils writeInt:1 toAddress:0x100842390];
//    NSLog(@">>>>>> %d",[MemoryUtils readIntAtAddress:0x100842390]);
    
    
    // -[SGMLicenseViewController reload]:    
    [MemoryUtils hookInstanceMethod:
                   NSClassFromString(@"SGMEnterprise")
                   originalSelector:NSSelectorFromString(@"settings")
                   swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_settings")
    ];
    
    
    // 消息日志推送
    // +[SGEEventCenter raiseEvent:content:type:]:
//    Method raiseEventMethod = class_getClassMethod(NSClassFromString(@"SGEEventCenter"), NSSelectorFromString(@"raiseEvent:content:type:"));
//    IMP raiseEventMethodIMP = method_getImplementation(raiseEventMethod);
//    raiseEventMethodPointer = (RaiseEventMethodPointer)raiseEventMethodIMP;
//  
//    [MemoryUtils hookClassMethod:
//                   NSClassFromString(@"SGEEventCenter")
//                   originalSelector:NSSelectorFromString(@"raiseEvent:content:type:")
//                   swizzledClass:[self class]
//                   swizzledSelector:NSSelectorFromString(@"hk_raiseEvent:content:type:")
//    ];
    
    [MemoryUtils hookInstanceMethod:
                       NSClassFromString(@"SGCloudKit")
                       originalSelector:NSSelectorFromString(@"init")
                       swizzledClass:[self class]
                       swizzledSelector:NSSelectorFromString(@"hk_init")
        ];
    
    [MemoryUtils hookInstanceMethod:
                       NSClassFromString(@"SGPonteManager")
                       originalSelector:NSSelectorFromString(@"updatePonteDeviceListWithCompletionHandler:")
                       swizzledClass:[self class]
                       swizzledSelector:NSSelectorFromString(@"hk_updatePonteDeviceListWithCompletionHandler:")
        ];
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

- (void) hk_updatePonteDeviceListWithCompletionHandler:id{
    NSLog(@">>>>>> hk_updatePonteDeviceListWithCompletionHandler");
}
//typedef id (*RaiseEventMethodPointer)(id, SEL,id, id,id);
//RaiseEventMethodPointer raiseEventMethodPointer = NULL;
//
//+(void)hk_raiseEvent:(id)arg2 content:(id)arg3 type:(id)arg4 {
//     raiseEventMethodPointer(self,_cmd,arg2,arg3,arg4);
//}

- (id)hk_settings{
    id ret = [[NSClassFromString(@"SGMEnterpriseSettings") alloc] init];
    // id ret = class_createInstance(objc_getClass("SGMEnterpriseSettings"), 0);
    [ret performSelector:NSSelectorFromString(@"setUserID:") withObject:@"this is user id"];
    [ret performSelector:NSSelectorFromString(@"setCompanyName:") withObject:@"this is cp name"];
    [ret performSelector:NSSelectorFromString(@"setCompanyID:") withObject:@"this is cp id"];
    return ret;
}

- (void)hk_init{
    NSLog(@">>>>>> hk_init");
}


int (*sub__1001b3189_ori)(id a,id b);
int hook_sub_1001b3189(id a,id b){
    return 1;
}

int (*sub_1001b2aba_ori);
int hook_sub_1001b2aba(void){
    // br s -a 0x1001b2b3a
    // return *(int32_t *)dword_10083dea8;
    // 0: 开始 7 天免费试用
    // 1: 免费试用将在 x 天后到期
    // 2: Load Main Win
    // case 0,1,2,3,4
    return 2;
}

typedef id (*ObjectForKeyedSubscriptPointer)(id, SEL,id);
ObjectForKeyedSubscriptPointer objectForKeyedSubscriptPointer = NULL;
//
- (id)hk_objectForKeyedSubscript:arg1{
    id ret = objectForKeyedSubscriptPointer(self,_cmd,arg1);

    if ([arg1 isKindOfClass:[NSString class]]) {
        if ([arg1 isEqualToString:@"policy"]){
//            {
//              "deviceID": "36d7a97a91b82ce5bc8b2609d4e17dae",
//              "expiresOnDate": 2524582861,
//              "issueDate": 2524582861,
//              "type": "licensed",
//              "enterprise": 1,
//              "product":"SURGEMAC5",
//              "p":"0",
//              "k":"0"
//            }
            return @"eyJkZXZpY2VJRCI6IjM2ZDdhOTdhOTFiODJjZTViYzhiMjYwOWQ0ZTE3ZGFlIiwiZXhwaXJlc09uRGF0ZSI6MjUyNDU4Mjg2MSwiaXNzdWVEYXRlIjoyNTI0NTgyODYxLCJ0eXBlIjoibGljZW5zZWQiLCJlbnRlcnByaXNlIjoxLCJwcm9kdWN0IjoiU1VSR0VNQUM1IiwicCI6IjAiLCJrIjoiMCJ9";
        }else if ([arg1 isEqualToString:@"sign"]) {
            return @"ZXlKa1pYWnBZMlZKUkNJNklqTTJaRGRoT1RkaE9URmlPREpqWlRWaVl6aGlNall3T1dRMFpURTNaR0ZsSWl3aVpYaHdhWEpsYzA5dVJHRjBaU0k2TWpVeU5EVTRNamcyTVN3aWFYTnpkV1ZFWVhSbElqb3lOVEkwTlRneU9EWXhMQ0owZVhCbElqb2liR2xqWlc1elpXUWlMQ0psYm5SbGNuQnlhWE5sSWpveExDSndjbTlrZFdOMElqb2lVMVZTUjBWTlFVTTFJaXdpY0NJNklqQWlMQ0pySWpvaU1DSjk=";
    
        }else if ([arg1 isEqualToString:@"code"]) {
            return @0;
        }else if ([arg1 isEqualToString:@"enterprise"]) {
            return @1;
        }else if ([arg1 isEqualToString:@"error"]) {
            return nil;
        }else if ([arg1 isEqualToString:@"message"]) {
            return nil;
        }
        
    }
    NSLog(@">>>>>> hk_objectForKeyedSubscript: %@, %@", self,arg1);

    return ret;
}
//
//typedef id (*URLWithStringPointer)(id, SEL,id);
//URLWithStringPointer urlWithStringPointer = NULL;
//
//+ (id)hk_URLWithString:arg1{
//    id ret = urlWithStringPointer(self,_cmd,arg1);
//    
//    // >>>>>> hk_URLWithString https://www.surge-activation.com/mac/v3/resource/jsvm
//    // >>>>>> hk_URLWithString https://www.surge-activation.com/mac/v3/free-trial
//    
//    if ([arg1 containsString:@"mac/v3/resource/jsvm"]) {
//        NSLog(@">>>>>> hk_URLWithString /mac/v3/resource/jsvm");
//        // sub_1001b2aba() == 0x4 || sub_1001b2aba() == 0x3 || sub_1001b2aba() == 0x0
//    }
//    if ([arg1 containsString:@"mac/v3/free-trial"]) {
//        NSLog(@">>>>>> hk_URLWithString /mac/v3/free-trial");
//        
//    }
//    NSLog(@">>>>>> hk_URLWithString %@",arg1);
//    return ret;
//}



@end
