//
//  Clop.m
//  dylib_dobby_hook
//
//  Created by NKR on 2025/9/20.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"
#import "InstructionDecoder.h"

@interface ClopHack : HackProtocolDefault

@end
@implementation ClopHack


- (NSString *)getAppName {
    return @"com.lowtechguys.Clop";
}

- (NSString *)getSupportAppVersion {
    return @"";
}

static IMP initIMP;

- (void) numberOfPreviewItemsInPreviewPanel {
    ((void*(*)(id, SEL))initIMP)(self, _cmd);
    [MemoryUtils setInstanceIvar:self ivarName:"_doneCount" value:@(0)];
}

- (BOOL)hack {

  	initIMP = [MemoryUtils hookInstanceMethod:
                              objc_getClass("_TtC4Clop19OptimisationManager")
                       originalSelector:NSSelectorFromString(@"numberOfPreviewItemsInPreviewPanel:")
                          swizzledClass:[self class]
                            swizzledSelector:@selector(numberOfPreviewItemsInPreviewPanel)
        ];
    
    Method AppDelegate = class_getInstanceMethod(NSClassFromString(@"_TtC10LowtechPro21LowtechProAppDelegate"), NSSelectorFromString(@"productActivated"));
  	IMP imp = method_getImplementation(AppDelegate);
    #if __x86_64__ || __amd64__
        void *instr_addr = (void *)((uint8_t *)imp + 0x8);
	#else
    	void *instr_addr = (void *)((uint8_t *)imp + 0x10);
    #endif

    uint64_t target = 0;
	#if __arm64__ || __aarch64__
        target = decode_bl_b_target_arm64(instr_addr);
	#elif __x86_64__ || __amd64__
        target = decode_call_target_x86_64((const uint8_t *)instr_addr);
	#endif

    tiny_hook((void*)target,ret1,NULL);
    
    Class PaddleBaseHackClass = NSClassFromString(@"PaddleBaseHack");
    id hackInstance = [[PaddleBaseHackClass alloc] init];
    [hackInstance performSelector:@selector(hack)];

    return YES;
}

@end
